import Foundation
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

class ActivityViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var popularActivities: [Activity] = []
    @Published var nearbyActivities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var activitiesListener: ListenerRegistration?
    
    deinit {
        activitiesListener?.remove()
    }
    
    // MARK: - Fetch Activities
    
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
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.popularActivities = []
                        return
                    }
                    
                    // Parse activities with safe data handling
                    self.popularActivities = self.parseActivities(from: documents)
                }
            }
    }
    
    // Add method that accepts CLLocation parameter with throttling
    func fetchNearbyActivities(location: CLLocation, radiusInKm: Double = 50.0) {
        isLoading = true
        error = nil
        
        // Convert radius to meters for Google Places API
        let radiusInMeters = Int(radiusInKm * 1000)
        
        // Use regular search for nearby activities
        // We'll implement throttling and caching in the service layer
        GooglePlacesService.shared.searchNearbyActivities(
            location: location,
            radius: radiusInMeters,
            activityType: "family_friendly",
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
                            
                            return Activity(
                                id: place.id,
                                name: place.name,
                                description: "A family-friendly activity",
                                type: activityType,
                                location: location,
                                rating: place.rating,
                                reviewCount: place.userRatingsTotal
                            )
                        }
                        
                        self.nearbyActivities = mappedActivities
                        
                    case .failure(let error):
                        self.error = error.localizedDescription
                        
                        // Fallback to Firebase method if Google Places fails
                        let latitude = location.coordinate.latitude
                        let longitude = location.coordinate.longitude
                        self.fetchNearbyActivities(latitude: latitude, longitude: longitude, radiusInKm: radiusInKm)
                    }
                }
            }
        )
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
    
    private func parseActivities(from documents: [QueryDocumentSnapshot]) -> [Activity] {
        return documents.compactMap { document -> Activity? in
            do {
                // Try to directly decode the document using Firestore's built-in support
                // This is Firebase's recommended approach for Codable models
                return try document.data(as: Activity.self)
            } catch {
                // Fallback to manual parsing if direct decoding fails
                
                // Get the document data and sanitize it immediately
                let rawData = document.data()
                let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                
                let id = document.documentID
                
                // Extract data using safe methods
                guard let name = FirebaseSafetyKit.getString(from: data, forKey: "name") else {
                    print("Error parsing activity: missing name field")
                    return nil
                }
                
                // Get description (handle optional type)
                let description = FirebaseSafetyKit.getString(from: data, forKey: "description") ?? ""
                
                // Get activity type (required parameter)
                let typeStr = FirebaseSafetyKit.getString(from: data, forKey: "type") ?? "other"
                let type = ActivityType(rawValue: typeStr) ?? .other
                
                // Get location (required parameter)
                var location: Location?
                if let locationData = data["location"] as? [String: Any] {
                    let sanitizedLocationData = FirebaseSafetyKit.sanitizeData(locationData) ?? [:]
                    let locationName = FirebaseSafetyKit.getString(from: sanitizedLocationData, forKey: "name") ?? "Unknown"
                    let address = FirebaseSafetyKit.getString(from: sanitizedLocationData, forKey: "address") ?? "Unknown"
                    
                    if let latitude = sanitizedLocationData["latitude"] as? Double,
                       let longitude = sanitizedLocationData["longitude"] as? Double {
                        location = Location(name: locationName, address: address, latitude: latitude, longitude: longitude)
                    }
                }
                
                // Create default location if none provided
                if location == nil {
                    location = Location(name: "Unknown", address: "Unknown", latitude: 0, longitude: 0)
                }
                
                // Optional fields
                let iconName = FirebaseSafetyKit.getString(from: data, forKey: "iconName")
                let category = FirebaseSafetyKit.getString(from: data, forKey: "category")
                let website = FirebaseSafetyKit.getString(from: data, forKey: "website")
                let phoneNumber = FirebaseSafetyKit.getString(from: data, forKey: "phoneNumber")
                
                // Parse arrays
                let tags = FirebaseSafetyKit.getStringArray(from: data, forKey: "tags") ?? []
                let photos = FirebaseSafetyKit.getStringArray(from: data, forKey: "photos")
                
                // Parse numeric values
                let minAge = FirebaseSafetyKit.getInt(from: data, forKey: "minAge")
                let maxAge = FirebaseSafetyKit.getInt(from: data, forKey: "maxAge")
                
                var rating: Double?
                if let ratingValue = data["rating"] as? Double {
                    rating = ratingValue
                } else if let ratingValue = data["rating"] as? Int {
                    rating = Double(ratingValue)
                } else if let ratingStr = FirebaseSafetyKit.getString(from: data, forKey: "rating"), 
                          let ratingValue = Double(ratingStr) {
                    rating = ratingValue
                }
                
                let reviewCount = FirebaseSafetyKit.getInt(from: data, forKey: "reviewCount")
                
                // Parse boolean values
                let isPublic = FirebaseSafetyKit.getBool(from: data, forKey: "isPublic", defaultValue: true)
                let isFeatured = FirebaseSafetyKit.getBool(from: data, forKey: "isFeatured", defaultValue: false)
                
                // Parse dates
                var createdAt = Date()
                if let timestamp = data["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                }
                
                var updatedAt = Date()
                if let timestamp = data["updatedAt"] as? Timestamp {
                    updatedAt = timestamp.dateValue()
                }
                
                // Create the activity with all required parameters
                return Activity(
                    id: id,
                    name: name,
                    description: description,
                    type: type,
                    location: location!,
                    website: website,
                    phoneNumber: phoneNumber,
                    photos: photos,
                    rating: rating,
                    reviewCount: reviewCount,
                    isPublic: isPublic,
                    isFeatured: isFeatured,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            }
        }
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
                        
                        // Description is non-optional in Activity model
                        if activity.description.lowercased().contains(lowercasedQuery) {
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
