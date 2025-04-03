import Foundation
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

class ActivityViewModel: ObservableObject {
    // Shared instance for easy access
    static let shared = ActivityViewModel()
    
    @Published var activities: [Activity] = []
    @Published var popularActivities: [Activity] = []
    @Published var nearbyActivities: [Activity] = []
    @Published var favoriteActivityIDs: Set<String> = [] // Synced with Firestore via user listener
    @Published var wantToDoActivityIDs: Set<String> = [] // Synced with Firestore via user listener
    @Published var favoriteActivities: [Activity] = [] // Holds fetched favorite Activity objects
    @Published var wishlistActivities: [Activity] = [] // Holds fetched wishlist Activity objects
    @Published var isLoading = false // General loading
    @Published var isLoadingFavorites = false // Specific loading state for favorites
    @Published var isLoadingWishlist = false // Specific loading state for wishlist
    @Published var error: String?
    @Published var selectedActivity: Activity? = nil // Added for navigation
    
    // Enum to identify which list to update
    private enum ActivityListType {
        case main, nearby, popular
    }
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var activitiesListener: ListenerRegistration?
    private var userListener: ListenerRegistration? // Listener for user document
    private var authViewModel: AuthViewModel? // To get current user ID

    // Private init for Singleton
    private init() {
        print("🚀 ActivityViewModel initialized (Singleton)")
        // Setup will be called externally after AuthViewModel is available
    }

    // Call this method after AuthViewModel is initialized and available
    func setup(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        print("🚀 ActivityViewModel: AuthViewModel injected. Setting up user observation.")

        // Observe user changes from AuthViewModel
        authViewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                if let user = user, let userId = user.id {
                    print("🚀 ActivityViewModel: User logged in (\(userId)). Setting up user listener.")
                    self.setupUserListener(for: userId)
                } else {
                    print("🚀 ActivityViewModel: User logged out. Removing user listener and clearing lists.")
                    self.removeUserListener()
                    self.favoriteActivityIDs = []
                    self.wantToDoActivityIDs = []
                    // Also clear the fetched activities if IDs are cleared
                    self.favoriteActivities = []
                    self.wishlistActivities = []
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        activitiesListener?.remove()
        removeUserListener() // Ensure user listener is removed
        print("🗑️ ActivityViewModel deinitialized.")
    }

    // MARK: - User Activity List Management (Firestore-based)

    func setupUserListener(for userID: String) { // Removed private
        self.removeUserListener() // Ensure no duplicate listeners

        let userRef = db.collection("users").document(userID)
        userListener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let self = self else { return }
            guard let document = documentSnapshot else {
                print("❌ Error fetching user document for activity lists: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Use Task @MainActor for safety
            Task { @MainActor in
                do {
                    let user = try document.data(as: User.self)
                    let newFavoriteIDs = Set(user.favoriteActivityIDs ?? [])
                    let newWantToDoIDs = Set(user.wantToDoActivityIDs ?? [])

                    // Log the loaded IDs
                    print(" M setupUserListener: Loaded Favorite IDs: \(newFavoriteIDs)")
                    print(" M setupUserListener: Loaded WantTo Do IDs: \(newWantToDoIDs)")

                    // Check if IDs actually changed before triggering fetches
                    let favoritesChanged = newFavoriteIDs != self.favoriteActivityIDs
                    let wishlistChanged = newWantToDoIDs != self.wantToDoActivityIDs

                    self.favoriteActivityIDs = newFavoriteIDs
                    self.wantToDoActivityIDs = newWantToDoIDs

                    print("✅ User activity lists updated: Favorites(\(self.favoriteActivityIDs.count)), WantToDo(\(self.wantToDoActivityIDs.count))")

                    // Trigger fetches only if the corresponding ID list changed
                    if favoritesChanged {
                        print(" M Favorites changed, triggering fetchFavoriteActivities...") // Add log
                        self.fetchFavoriteActivities()
                    }
                    if wishlistChanged {
                         print(" M Wishlist changed, triggering fetchWishlistActivities...") // Add log
                        self.fetchWishlistActivities()
                    }

                } catch {
                    print("❌ Error decoding user document for activity lists: \(error)")
                    // Clear local state on error to avoid inconsistency
                    self.favoriteActivityIDs = []
                    self.wantToDoActivityIDs = []
                    self.favoriteActivities = []
                    self.wishlistActivities = []
                }
            }
        }
    }

    // Made internal to be accessible from sink closure and deinit
    func removeUserListener() {
        userListener?.remove()
        userListener = nil
        print("👂 User listener for activity lists removed.")
    }

    // Toggles favorite status and updates Firestore
    func toggleFavorite(activity: Activity) async {
        guard let activityID = activity.id else {
            print("❌ Cannot toggle favorite: Activity has no ID.")
            return
        }
        // Simplified Check: Ensure user profile is loaded (implies logged in and initial check complete)
        guard let userID = authViewModel?.user?.id else {
            print("❌ Cannot toggle favorite: User profile not loaded.")
            // Provide clearer feedback to the user
            DispatchQueue.main.async { self.error = "User profile not available. Please ensure you are logged in." }
            return
        }

        let userRef = db.collection("users").document(userID)
        let isCurrentlyFavorite = favoriteActivityIDs.contains(activityID)

        // --- Optimistic UI Update ---
        DispatchQueue.main.async {
            if isCurrentlyFavorite {
                self.favoriteActivities.removeAll { $0.id == activityID }
            } else {
                // Avoid adding duplicates if already present somehow
                if !self.favoriteActivities.contains(where: { $0.id == activityID }) {
                    self.favoriteActivities.append(activity)
                }
            }
        }
        // --- End Optimistic UI Update ---

        do {
            if isCurrentlyFavorite {
                // Remove from favorites in Firestore
                try await userRef.updateData([
                    "favoriteActivityIDs": FieldValue.arrayRemove([activityID])
                ])
                print("✅ Removed \(activityID) from favorites for user \(userID)")
            } else {
                // Add to favorites
                try await userRef.updateData([
                    "favoriteActivityIDs": FieldValue.arrayUnion([activityID])
                ])
                print("✅ Added \(activityID) to favorites for user \(userID) in Firestore")
            }
            // The listener will eventually confirm this change, but the UI is already updated.
        } catch {
            print("❌ Error updating favorites for activity \(activityID) in Firestore: \(error.localizedDescription)")
            // --- Revert Optimistic Update on Error ---
            DispatchQueue.main.async {
                // If Firestore failed, revert the local change
                if isCurrentlyFavorite {
                    // Failed to remove, so add it back if not already there
                    if !self.favoriteActivities.contains(where: { $0.id == activityID }) {
                         self.favoriteActivities.append(activity)
                    }
                } else {
                    // Failed to add, so remove it
                    self.favoriteActivities.removeAll { $0.id == activityID }
                }
                self.error = "Failed to update favorites: \(error.localizedDescription)"
            }
            // --- End Revert ---
        }
    }

    // Toggles "Want to Do" status and updates Firestore
    func toggleWantToDo(activity: Activity) async {
        guard let activityID = activity.id else {
            print("❌ Cannot toggle want to do: Activity has no ID.")
            return
        }
        // Simplified Check: Ensure user profile is loaded (implies logged in and initial check complete)
        guard let userID = authViewModel?.user?.id else {
            print("❌ Cannot toggle want to do: User profile not loaded.")
            // Provide clearer feedback to the user
            DispatchQueue.main.async { self.error = "User profile not available. Please ensure you are logged in." }
            return
        }

        let userRef = db.collection("users").document(userID)
        let isCurrentlyWantToDo = wantToDoActivityIDs.contains(activityID)

        // --- Optimistic UI Update ---
        DispatchQueue.main.async {
            if isCurrentlyWantToDo {
                self.wishlistActivities.removeAll { $0.id == activityID }
            } else {
                // Avoid adding duplicates if already present somehow
                if !self.wishlistActivities.contains(where: { $0.id == activityID }) {
                    self.wishlistActivities.append(activity)
                }
            }
        }
        // --- End Optimistic UI Update ---

        do {
            if isCurrentlyWantToDo {
                // Remove from want to do list in Firestore
                try await userRef.updateData([
                    "wantToDoActivityIDs": FieldValue.arrayRemove([activityID])
                ])
                print("✅ Removed \(activityID) from want-to-do list for user \(userID)")
            } else {
                // Add to want to do list
                try await userRef.updateData([
                    "wantToDoActivityIDs": FieldValue.arrayUnion([activityID])
                ])
                print("✅ Added \(activityID) to want-to-do list for user \(userID) in Firestore")
            }
            // The listener will eventually confirm this change, but the UI is already updated.
        } catch {
            print("❌ Error updating want-to-do list for activity \(activityID) in Firestore: \(error.localizedDescription)")
            // --- Revert Optimistic Update on Error ---
            DispatchQueue.main.async {
                 // If Firestore failed, revert the local change
                 if isCurrentlyWantToDo {
                     // Failed to remove, so add it back if not already there
                     if !self.wishlistActivities.contains(where: { $0.id == activityID }) {
                          self.wishlistActivities.append(activity)
                     }
                 } else {
                     // Failed to add, so remove it
                     self.wishlistActivities.removeAll { $0.id == activityID }
                 }
                 self.error = "Failed to update want-to-do list: \(error.localizedDescription)"
            }
            // --- End Revert ---
        }
    }

    // Check if an activity is favorited (uses local @Published set)
    func isFavorite(activity: Activity) -> Bool {
        guard let id = activity.id else { return false }
        return favoriteActivityIDs.contains(id)
    }

    // Check if an activity is in the "Want to Do" list (uses local @Published set)
    func isWantToDo(activity: Activity) -> Bool {
        guard let id = activity.id else { return false }
        return wantToDoActivityIDs.contains(id)
    }

    // Overload to check directly by ID string
    func isWantToDo(activityID: String) -> Bool {
        return wantToDoActivityIDs.contains(activityID)
    }

    // MARK: - Fetch Favorite/Wishlist Activities

    // Fetches full Activity objects based on favoriteActivityIDs
    func fetchFavoriteActivities() {
        let idsToFetch = Array(favoriteActivityIDs) // Use the current state
        print(" M fetchFavoriteActivities: Attempting to fetch activities for IDs: \(idsToFetch)") // Log IDs being fetched
        guard !idsToFetch.isEmpty else { // Check based on the array derived from the state
            // If no favorite IDs, clear the list and return
            DispatchQueue.main.async {
                self.favoriteActivities = []
                self.isLoadingFavorites = false
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoadingFavorites = true
            self.error = nil // Clear previous errors specific to this fetch if needed
        }

        // Fetch each favorite activity individually
        var fetchedFavorites: [Activity] = []
        let group = DispatchGroup()

        for activityID in idsToFetch {
            group.enter()
            db.collection("activities").document(activityID).getDocument { documentSnapshot, error in
                defer { group.leave() }

                if let error = error {
                    print("❌ Error fetching favorite activity \(activityID): \(error.localizedDescription)")
                    return
                }
                guard let document = documentSnapshot, document.exists else {
                    print(" M fetchFavoriteActivities: Document \(activityID) does not exist.")
                    return
                }

                // Directly decode the single DocumentSnapshot using try?
                if let activity = try? document.data(as: Activity.self) {
                    fetchedFavorites.append(activity)
                    // Optional: Log success
                    // print(" M fetchFavoriteActivities: Successfully parsed document \(activityID).")
                } else {
                    // Handle decoding error (try? returned nil)
                    // We don't have the specific error here, but we know it failed.
                    print("❌ Error decoding favorite activity document \(activityID) with Codable. Data: \(document.data() ?? [:])")
                }
            }
        }

        group.notify(queue: .main) {
            print(" M fetchFavoriteActivities: DispatchGroup notify block. Fetched \(fetchedFavorites.count) individual activities.")
            self.favoriteActivities = fetchedFavorites
            self.isLoadingFavorites = false
            print("✅ Fetched \(self.favoriteActivities.count) favorite activities individually. Assigned to @Published var.")
        }
    }


    // Fetches full Activity objects based on wantToDoActivityIDs - Fetching Individually
    func fetchWishlistActivities() {
        let idsToFetch = Array(wantToDoActivityIDs) // Use the current state
        print(" M fetchWishlistActivities: Attempting to fetch activities INDIVIDUALLY for IDs: \(idsToFetch)") // Log IDs being fetched
        guard !idsToFetch.isEmpty else {
            // If no wishlist IDs, clear the list and return
            DispatchQueue.main.async {
                self.wishlistActivities = []
                self.isLoadingWishlist = false
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoadingWishlist = true
            self.error = nil // Clear previous errors specific to this fetch if needed
        }

        // Fetch each wishlist activity individually
        var fetchedWishlist: [Activity] = []
        let group = DispatchGroup()

        for activityID in idsToFetch {
            group.enter()
            db.collection("activities").document(activityID).getDocument { documentSnapshot, error in
                defer { group.leave() }

                if let error = error {
                    print("❌ Error fetching wishlist activity \(activityID): \(error.localizedDescription)")
                    return
                }
                guard let document = documentSnapshot, document.exists else {
                    print(" M fetchWishlistActivities: Document \(activityID) does not exist.")
                    // This is expected if an ID in the user's list points to a deleted activity
                    return
                }
                 print(" M fetchWishlistActivities: Successfully fetched document \(activityID).")

                // Directly decode the single DocumentSnapshot using try?
                if let activity = try? document.data(as: Activity.self) {
                    fetchedWishlist.append(activity)
                    print(" M fetchWishlistActivities: Successfully parsed document \(activityID).")
                } else {
                    // Handle decoding error (try? returned nil)
                    // We don't have the specific error here, but we know it failed.
                    print("❌ Error decoding wishlist activity document \(activityID) with Codable. Data: \(document.data() ?? [:])")
                }
            }
        }

        group.notify(queue: .main) {
            print(" M fetchWishlistActivities: DispatchGroup notify block. Fetched \(fetchedWishlist.count) individual activities.")
            // Sort results if needed, e.g., by name or original order
            // For now, just assign
            self.wishlistActivities = fetchedWishlist
            self.isLoadingWishlist = false
            print("✅ Fetched \(self.wishlistActivities.count) wishlist activities individually. Assigned to @Published var.")
        }
    }


    // MARK: - Fetch General Activities
    
    func fetchActivities(category: String? = nil) {
        isLoading = true
        error = nil
        
        // Remove any existing listener
        activitiesListener?.remove()
        
        // Set up a real-time listener for activities
        let query = db.collection("activities")
            .order(by: "name")
        
        // Use a real-time listener for activities
        activitiesListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    // Display the error message to the user
                    let errorDescription = error.localizedDescription
                    self.error = "Firebase error: \(errorDescription)"
                    
                    // Log the error for debugging
                    print("Firebase error in fetchActivities: \(errorDescription)")
                    
                    // Clear activities on error to avoid showing stale data
                    self.activities = []
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.activities = []
                    return
                }
                
                // Parse activities with safe data handling
                var parsedActivities = self.parseActivities(from: documents)
                
                // If category is provided, filter the activities
                if let category = category {
                    parsedActivities = parsedActivities.filter { activity in
                        let categoryLower = category.lowercased()
                        let activityTypeLower = activity.type.title.lowercased()
                        
                        // Match category to activity type
                        switch categoryLower {
                        case "parks":
                            return activityTypeLower.contains("park")
                        case "museums":
                            return activityTypeLower.contains("museum")
                        case "playgrounds":
                            return activityTypeLower.contains("playground") || activityTypeLower.contains("park")
                        case "libraries":
                            return activityTypeLower.contains("library")
                        case "swimming":
                            return activityTypeLower.contains("swimming") || activityTypeLower.contains("pool")
                        case "sports":
                            return activityTypeLower.contains("sport") || activityTypeLower.contains("athletic")
                        default:
                            return true
                        }
                    }
                }
                
                self.activities = parsedActivities
            }
        }
    }
    
    func fetchPopularActivities(limit: Int = 10) {
        isLoading = true
        error = nil
        
        // First try to order by rating (if available)
        db.collection("activities")
            .order(by: "rating", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        print("Error fetching popular activities by rating: \(error.localizedDescription)")
                        
                        // Fallback to popularity if rating query fails
                        self.fetchPopularActivitiesByPopularity(limit: limit)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        // If no documents, set to empty
                        print("No popular activity documents found.")
                        self.popularActivities = []
                        return
                    }
                    
                    // Parse activities with safe data handling
                    let parsedActivities = self.parseActivities(from: documents)
                    
                    if parsedActivities.isEmpty {
                        // If no activities were parsed, set to empty
                        print("No popular activities parsed.")
                        self.popularActivities = []
                    } else {
                        self.popularActivities = parsedActivities
                        print("Fetched \(self.popularActivities.count) popular activities by rating")
                    }
                }
            }
    }
    
    // Fallback method if rating index is not available
    private func fetchPopularActivitiesByPopularity(limit: Int = 10) {
        isLoading = true
        error = nil
        
        db.collection("activities")
            .order(by: "popularity", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        print("Error fetching popular activities by popularity: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.popularActivities = []
                        return
                    }
                    
                    // Parse activities with safe data handling
                    self.popularActivities = self.parseActivities(from: documents)
                    print("Fetched \(self.popularActivities.count) popular activities by popularity")
                }
            }
    }
    
    // Add method to fetch featured activities
    func fetchFeaturedActivities(limit: Int = 5) {
        isLoading = true
        error = nil
        
        db.collection("activities")
            .whereField("isFeatured", isEqualTo: true)
            .limit(to: limit)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        print("Error fetching featured activities: \(error.localizedDescription)")
                        // Don't add mock data on error
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        // If no featured activities, do nothing (or set an empty state)
                        print("No featured activities found.")
                        // Optionally clear existing featured status if needed
                        return
                    }
                    
                    // Parse activities with safe data handling
                    let featuredActivities = self.parseActivities(from: documents)
                    print("Fetched \(featuredActivities.count) featured activities")
                    
                    if featuredActivities.isEmpty {
                         print("No featured activities parsed.")
                        // Optionally clear existing featured status if needed
                        return
                    }
                    
                    // If we have featured activities, update the main activities array
                    // This ensures featured activities are available for the featuredActivities computed property in HomeView
                    for activity in featuredActivities {
                        if !self.activities.contains(where: { $0.id == activity.id }) {
                            self.activities.append(activity)
                        }
                    }
                }
            }
    }
    
    // Add method that accepts CLLocation parameter with throttling
    func fetchNearbyActivities(location: CLLocation, radiusInKm: Double = 50.0, activityType: String? = nil) {
        isLoading = true
        error = nil
        
        // Convert radius to meters for Google Places API
        let radiusInMeters = Int(radiusInKm * 1000)
        
        // Use the provided activity type or default to "family_friendly"
        let searchType = activityType?.lowercased() ?? "family_friendly"
        
        print("Debug: Searching for nearby activities of type: \(searchType)")
        
        // Use regular search for nearby activities
        // We'll implement throttling and caching in the service layer
        GooglePlacesService.shared.searchNearbyActivities(
            location: location,
            radius: radiusInMeters,
            activityType: searchType,
            completion: { [weak self] (result: Result<[ActivityPlace], Error>) in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let activities):
                            // Convert Google Places activities to our Activity model
                            let mappedActivities = activities.map { place -> Activity in
                                let location = Location(
                                    name: place.location.name,
                                    address: place.location.address,
                                    latitude: place.location.latitude,
                                    longitude: place.location.longitude
                                )
                                
                                // Determine activity type based on place types
                                let activityType = self.determineActivityType(from: place.types)
                                
                                // Construct photo URL if reference exists
                                var photoURLs: [String]? = nil
                                if let photoRef = place.photoReference,
                                   let photoURL = GooglePlacesService.shared.getPhotoURL(photoReference: photoRef) {
                                    photoURLs = [photoURL.absoluteString]
                                }
                                
                                return Activity(
                                    id: place.id,
                                    name: place.name,
                                    description: nil, // Set to nil initially, will fetch on demand
                                    type: activityType,
                                    location: location,
                                    website: nil, // Not available from nearby search
                                    phoneNumber: nil, // Not available from nearby search
                                    photos: photoURLs, // Use the constructed URL
                                    rating: place.rating,
                                    reviewCount: place.userRatingsTotal,
                                    isPublic: true, // Assume public from Google Places
                                    isFeatured: false, // Not featured by default
                                    createdAt: Date(), // Use current date as placeholder
                                    updatedAt: Date() // Use current date as placeholder
                                    // photoReference is no longer needed in Activity model if photos array is used
                                )
                            }
                            
                            // Enhanced behavior: For certain types (like Parks), we want to accumulate results
                        // from multiple searches rather than replacing them
                        if searchType == "park" || searchType == "playground" {
                            // Merge new activities with existing ones, avoiding duplicates
                            self.mergeNearbyActivities(mappedActivities)
                        } else {
                            // Standard behavior - replace the entire list
                            self.nearbyActivities = mappedActivities
                        }
                        
                        print("Debug: Found \(mappedActivities.count) activities of type: \(searchType)")
                        
                    case .failure(let error):
                        self.error = "Failed to fetch nearby places: \(error.localizedDescription)"
                        print("❌ Error fetching nearby places from Google Places: \(error.localizedDescription)")
                        // Removed Firestore fallback - rely solely on Google Places for nearby search.
                        // If Google Places fails, the nearbyActivities list will remain unchanged or empty.
                    }
                }
            }
        )
    }
    
    // New helper method to merge activities while avoiding duplicates
    private func mergeNearbyActivities(_ newActivities: [Activity]) {
        var updatedActivities = self.nearbyActivities
        
        for activity in newActivities {
            // Check if the activity is already in the list (by name or by ID)
            let isDuplicate = updatedActivities.contains { existingActivity in
                if let activityId = activity.id, let existingId = existingActivity.id {
                    return activityId == existingId
                } else {
                    // If no ID, fall back to name comparison
                    return activity.name == existingActivity.name
                }
            }
            
            // If it's not a duplicate, add it to the list
            if !isDuplicate {
                updatedActivities.append(activity)
            }
        }
        
        // Update the published property
        self.nearbyActivities = updatedActivities
    }
    
    // Helper method to determine activity type from place types
    private func determineActivityType(from placeTypes: [String]) -> ActivityType {
        if placeTypes.contains("park") {
            return .park
        } else if placeTypes.contains("museum") {
            return .museum
        } else if placeTypes.contains("aquarium") {
            return .aquarium
        } else if placeTypes.contains("zoo") {
            return .zoo
        } else if placeTypes.contains("library") {
            return .library
        } else if placeTypes.contains("amusement_park") {
            return .themePark
        } else if placeTypes.contains("movie_theater") {
            return .movieTheater
        } else if placeTypes.contains("stadium") || placeTypes.contains("sports_complex") {
            return .sportingEvent
        } else {
            return .other
        }
    }
    
    // Method that uses raw coordinates
    func fetchNearbyActivities(latitude: Double, longitude: Double, radiusInKm: Double = 50.0) {
        isLoading = true
        error = nil
        
        // Calculate rough bounding box for initial filtering
        let latRadian = latitude * .pi / 180
        let degreesPerKmLat = 1 / 111.0 // approximately 111km per degree of latitude
        let degreesPerKmLon = 1 / (111.0 * cos(latRadian)) // varies based on latitude
        
        let latDelta = radiusInKm * degreesPerKmLat
        let lonDelta = radiusInKm * degreesPerKmLon
        
        let minLat = latitude - latDelta
        let maxLat = latitude + latDelta
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta
        
        // Fetch activities - simplified query to avoid index issues
        db.collection("activities")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.nearbyActivities = []
                        return
                    }
                    
                    // Parse activities and filter by location in memory
                    let activities = self.parseActivities(from: documents)
                    
                    // Filter by location criteria in memory
                    self.nearbyActivities = activities.filter { activity in
                        let activityLoc = activity.location
                        
                        // Check if public
                        guard activity.isPublic == true else {
                            return false
                        }
                        
                        // Check latitude bounds
                        guard activityLoc.latitude >= minLat && activityLoc.latitude <= maxLat else {
                            return false
                        }
                        
                        // Check longitude bounds
                        guard activityLoc.longitude >= minLon && activityLoc.longitude <= maxLon else {
                            return false
                        }
                        
                        // Calculate actual distance using CLLocation distance method
                        let activityLocation = CLLocation(latitude: activityLoc.latitude, longitude: activityLoc.longitude)
                        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                        let distanceInMeters = activityLocation.distance(from: userLocation)
                        
                        return distanceInMeters <= (radiusInKm * 1000) // convert km to meters
                    }
                }
            }
    }

    // Reverted parsing function signature to accept [QueryDocumentSnapshot]
    private func parseActivities(from documents: [QueryDocumentSnapshot]) -> [Activity] {
        return documents.compactMap { document -> Activity? in
            // No need to check document.exists here as QueryDocumentSnapshot always exists
            do {
                // Try to directly decode the document using Firestore's built-in Codable support
                return try document.data(as: Activity.self)
            } catch {
                // Log error if Codable decoding fails, including the data that failed
                // This indicates a potential mismatch between the Firestore data structure and the Activity model
                print("❌ Error decoding Activity document \(document.documentID) with Codable: \(error.localizedDescription). Data: \(document.data())")
                return nil // Return nil to exclude this document from the results
            }
        }
    }

    // MARK: - Fetch Activity Details (On Demand)

    func fetchAndSetActivityDetails(activityID: String) {
        // Find the index and type of the list containing the activity
        var activityIndex: Int? = nil
        var listType: ActivityListType? = nil
        var existingDescription: String? = nil

        if let index = activities.firstIndex(where: { $0.id == activityID }) {
            activityIndex = index
            listType = .main
            existingDescription = activities[index].description
        } else if let index = nearbyActivities.firstIndex(where: { $0.id == activityID }) {
            activityIndex = index
            listType = .nearby
            existingDescription = nearbyActivities[index].description
        } else if let index = popularActivities.firstIndex(where: { $0.id == activityID }) {
            activityIndex = index
            listType = .popular
            existingDescription = popularActivities[index].description
        }

        // Renamed 'type' back to 'listType' to avoid keyword conflict
        guard let index = activityIndex, let listType = listType else {
            print("Activity with ID \(activityID) not found in any list.")
            return
        }

        // Check if details (like description) are already fetched
        if existingDescription != nil {
             print("Details already fetched for activity \(activityID).")
             return // Avoid redundant fetching
        }

        print("Fetching details for activity ID: \(activityID) in list: \(listType)") // Corrected variable name
        // Indicate loading state specifically for this activity if needed
        // For simplicity, we'll just update when data arrives

        // Let Swift infer the result type from the getPlaceDetails signature
        GooglePlacesService.shared.getPlaceDetails(placeId: activityID) { [weak self] result in
            // We still need guard let self = self for the weak capture
            guard let self = self else { return }

            // Dispatch the update logic to the main thread
            DispatchQueue.main.async {
                switch result {
                case .success(let placeDetails):
                     // Removed the guard let check; placeDetails is already ActivityPlaceDetail due to function signature.
                     // Call the helper function directly with placeDetails, using 'listType'
                     self.updateActivityDetailsInList(activityID: activityID, placeDetails: placeDetails, listType: listType, index: index)
                case .failure(let error):
                     // Use listType variable here as well if needed for context
                     print("Error fetching details for activity \(activityID) in list \(listType): \(error.localizedDescription)")
                    // Optionally set an error state for this specific activity
                }
            }
        }
    }

    // Helper function to update activity details in the specified list, called on the main thread
    private func updateActivityDetailsInList(activityID: String, placeDetails: ActivityPlaceDetail, listType: ActivityListType, index: Int) { // Use correct type
        
        // Switch on the list type and directly modify the corresponding array
        switch listType {
        case .main:
            // Ensure index is valid before updating
            guard index < activities.count, activities[index].id == activityID else {
                print("Index \(index) out of bounds or activity ID mismatch when updating details for \(activityID) in main list.")
                return
            }
            // Get a mutable copy, modify it, and assign it back
            var activityToUpdate = activities[index]
            // Update with new details from Google Places
            activityToUpdate.editorialSummary = placeDetails.editorialSummary?.overview ?? activityToUpdate.editorialSummary // Use editorial summary
            activityToUpdate.openingHours = placeDetails.openingHours?.weekdayText ?? activityToUpdate.openingHours // Use weekday text for hours
            activityToUpdate.website = placeDetails.website ?? activityToUpdate.website
            activityToUpdate.phoneNumber = placeDetails.phoneNumber ?? activityToUpdate.phoneNumber
            // Assign the updated activity back to the array
            activities[index] = activityToUpdate
            print("Successfully updated details (summary/hours/website/phone) for activity \(activityID) in main list.")

        case .nearby:
            // Ensure index is valid before updating
            guard index < nearbyActivities.count, nearbyActivities[index].id == activityID else {
                print("Index \(index) out of bounds or activity ID mismatch when updating details for \(activityID) in nearby list.")
                return
            }
            // Get a mutable copy, modify it, and assign it back
            var activityToUpdate = nearbyActivities[index]
            // Update with new details from Google Places
            activityToUpdate.editorialSummary = placeDetails.editorialSummary?.overview ?? activityToUpdate.editorialSummary // Use editorial summary
            activityToUpdate.openingHours = placeDetails.openingHours?.weekdayText ?? activityToUpdate.openingHours // Use weekday text for hours
            activityToUpdate.website = placeDetails.website ?? activityToUpdate.website
            activityToUpdate.phoneNumber = placeDetails.phoneNumber ?? activityToUpdate.phoneNumber
            // Assign the updated activity back to the array
            nearbyActivities[index] = activityToUpdate
            print("Successfully updated details (summary/hours/website/phone) for activity \(activityID) in nearby list.")

        case .popular:
            // Ensure index is valid before updating
            guard index < popularActivities.count, popularActivities[index].id == activityID else {
                print("Index \(index) out of bounds or activity ID mismatch when updating details for \(activityID) in popular list.")
                return
            }
            // Get a mutable copy, modify it, and assign it back
            var activityToUpdate = popularActivities[index]
            // Update with new details from Google Places
            activityToUpdate.editorialSummary = placeDetails.editorialSummary?.overview ?? activityToUpdate.editorialSummary // Use editorial summary
            activityToUpdate.openingHours = placeDetails.openingHours?.weekdayText ?? activityToUpdate.openingHours // Use weekday text for hours
            activityToUpdate.website = placeDetails.website ?? activityToUpdate.website
            activityToUpdate.phoneNumber = placeDetails.phoneNumber ?? activityToUpdate.phoneNumber
            // Assign the updated activity back to the array
            popularActivities[index] = activityToUpdate
            print("Successfully updated details (summary/hours/website/phone) for activity \(activityID) in popular list.")
        }
        
        // Since we are modifying elements of @Published arrays directly, SwiftUI should detect the change.
        // If UI updates are still inconsistent, uncomment the line below.
        // self.objectWillChange.send()
    }
    
    // MARK: - Create/Update Activities
    
    func createActivity(_ activity: Activity, completion: @escaping (Result<Activity, Error>) -> Void) {
        isLoading = true
        error = nil
        
        do {
            // Follow Firebase recommended pattern for document creation
            let docRef: DocumentReference
            if let id = activity.id {
                // Use the provided ID
                docRef = db.collection("activities").document(id)
                try docRef.setData(from: activity)
            } else {
                // Let Firestore generate an ID
                docRef = try db.collection("activities").addDocument(from: activity)
            }
            
            // Fetch the newly created document
            docRef.getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists else {
                        let error = NSError(domain: "ActivityViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create activity"])
                        self.error = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    // Try to decode the document first using Codable
                    if let createdActivity = try? document.data(as: Activity.self) {
                        completion(.success(createdActivity))
                        return
                    }
                    
                    // Fallback to manual conversion
                    let rawData = document.data() ?? [:]
                    let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                    let documentID = document.documentID
                    
                    // Extract minimally required fields
                    guard 
                        let name = FirebaseSafetyKit.getString(from: data, forKey: "name"),
                        let typeStr = FirebaseSafetyKit.getString(from: data, forKey: "type")
                    else {
                        let error = NSError(domain: "ActivityViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Document missing required fields"])
                        self.error = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    let type = ActivityType(rawValue: typeStr) ?? .other
                    let description = FirebaseSafetyKit.getString(from: data, forKey: "description") ?? ""
                    
                    // Create default location
                    let location = Location(name: "Unknown", address: "Unknown", latitude: 0, longitude: 0)
                    
                    // Create a minimal Activity
                    let activity = Activity(
                        id: documentID,
                        name: name,
                        description: description,
                        type: type,
                        location: location
                    )
                    
                    completion(.success(activity))
                }
            }
        } catch {
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    func updateActivity(_ activity: Activity, completion: @escaping (Result<Activity, Error>) -> Void) {
        guard let id = activity.id else {
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                let error = NSError(domain: "ActivityViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Activity has no ID"])
                self.error = error.localizedDescription
                completion(.failure(error))
            }
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Firebase recommended approach for updating documents with Codable support
            try db.collection("activities").document(id).setData(from: activity)
            
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                completion(.success(activity))
            }
        } catch {
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    func deleteActivity(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        db.collection("activities").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Activity Search
    
    func searchActivities(query: String, completion: @escaping (Result<[Activity], Error>) -> Void) {
        guard !query.isEmpty else {
            completion(.success([]))
            return
        }
        
        isLoading = true
        error = nil
        
        db.collection("activities")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                // IMPORTANT: Dispatch UI updates to the main thread
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion(.success([]))
                        return
                    }
                    
                    // Parse activities with safe data handling
                    let allActivities = self.parseActivities(from: documents)
                    
                    // Filter activities based on query
                    let lowercasedQuery = query.lowercased()
                    let matchingActivities = allActivities.filter { activity in
                        // Name is non-optional in Activity model
                        if activity.name.lowercased().contains(lowercasedQuery) {
                            return true
                        }
                        
                        // Description is optional, safely unwrap
                        if let description = activity.description, description.lowercased().contains(lowercasedQuery) {
                            return true
                        }
                        
                        // Category is optional in Activity model
                        if let category = activity.category, category.lowercased().contains(lowercasedQuery) {
                            return true
                        }
                        
                        if let tags = activity.tags, tags.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                            return true
                        }
                        
                        return false
                    }
                    
                    completion(.success(matchingActivities))
                }
            }
    }
    
    // MARK: - Activity Popularity
    
    func incrementActivityPopularity(activityID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let docRef = db.collection("activities").document(activityID)
        
        // Use Firebase transaction for atomic updates as recommended in documentation
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let rawData = document.data() else {
                let error = NSError(domain: "ActivityViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Activity not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Sanitize data
            let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
            
            // Get current popularity safely
            let currentPopularity = FirebaseSafetyKit.getInt(from: data, forKey: "popularity") ?? 0
            
            // Increment popularity
            let newPopularity = currentPopularity + 1
            
            // Update the document
            transaction.updateData(["popularity": newPopularity], forDocument: docRef)
            
            return nil
        }) { [weak self] (_, error) in
            guard let self = self else { return }
            
            // IMPORTANT: Dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
}
