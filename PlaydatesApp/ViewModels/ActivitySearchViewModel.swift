import Foundation
import CoreLocation
import Combine

/**
 ViewModel for searching and managing activities using the Google Places API.
 */
class ActivitySearchViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var searchQuery = ""
    @Published var activities: [ActivityPlace] = []
    @Published var selectedActivity: ActivityPlace?
    @Published var isLoading = false
    @Published var error: String?
    
    // Service for Google Places API
    private let placesService = GooglePlacesService.shared
    
    // Location manager for getting user's location
    private let locationManager = LocationManager.shared
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up location updates
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] _ in
                // Location updated, but we'll wait for explicit search
            }
            .store(in: &cancellables)
        
        // Handle location errors - removed the problematic error subscription
        // since LocationManager doesn't have a published $error property
    }
    
    /**
     Search for activities based on the current search query and user's location.
     */
    func searchActivities() {
        guard !searchQuery.isEmpty else {
            error = "Please enter an activity type to search for"
            return
        }
        
        // Check if location services are authorized
        let authStatus = locationManager.authorizationStatus
        print("Debug: LocationManager authorization status: \(authStatus.rawValue)")
        
        if authStatus == .denied || authStatus == .restricted {
            error = "Location access is denied. Please enable location services in Settings to search for nearby activities."
            print("Debug: Location access denied or restricted")
            return
        }
        
        // Check if we have a valid location
        guard let location = locationManager.location else {
            // If location is nil but we're authorized, it might be that location services
            // haven't returned a location yet. Use a default location as fallback.
            let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
            
            error = "Your current location is not available yet. Using San Francisco as a default location for search."
            print("Debug: Location is nil when trying to fetch nearby activities")
            print("Debug: Using default location for search: \(defaultLocation.coordinate.latitude), \(defaultLocation.coordinate.longitude)")
            
            // Continue with the default location
            performSearch(with: defaultLocation)
            return
        }
        
        print("Debug: Current location available: true")
        print("Debug: Searching for '\(searchQuery)' at location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Perform the search with the actual location
        performSearch(with: location)
    }
    
    /**
     Perform the actual search with a given location
     */
    private func performSearch(with location: CLLocation) {
        isLoading = true
        error = nil
        
        // Use a larger radius to ensure we get results
        placesService.searchNearbyActivities(
            location: location,
            radius: 50000, // 50km radius to ensure we get results
            activityType: searchQuery
        ) { [weak self] (result: Result<[ActivityPlace], Error>) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let activities):
                print("Debug: Received \(activities.count) activities from API")
                self.activities = activities
                if activities.isEmpty {
                    self.error = "No activities found for '\(self.searchQuery)'. Try a different search term or increase search area."
                    print("Debug: API returned empty activities array")
                }
            case .failure(let error):
                print("Debug: API error: \(error.localizedDescription)")
                
                // Provide more helpful error messages based on error type
                let nsError = error as NSError
                print("Debug: Error domain: \(nsError.domain), code: \(nsError.code)")
                
                // Always update UI on the main thread
                DispatchQueue.main.async {
                    if nsError.domain == NSURLErrorDomain {
                        switch nsError.code {
                        case NSURLErrorNotConnectedToInternet:
                            self.error = "No internet connection. Please check your network settings and try again."
                        case NSURLErrorTimedOut:
                            self.error = "Request timed out. Please try again."
                        case NSURLErrorCancelled:
                            self.error = "Request was cancelled. Please try again."
                        default:
                            self.error = "Network error: \(nsError.localizedDescription)"
                        }
                    } else if nsError.domain == "GooglePlacesService" {
                        self.error = "Google Places API error: \(nsError.localizedDescription)"
                    } else {
                        self.error = "Failed to search activities: \(nsError.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /**
     Get details for a specific activity.
     
     - Parameter activity: The activity to get details for
     */
    func getActivityDetails(for activity: ActivityPlace) {
        isLoading = true
        error = nil
        
        placesService.getPlaceDetails(placeId: activity.id) { [weak self] (result: Result<ActivityPlace, Error>) in // Added explicit type annotation
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let details):
                self.selectedActivity = details
            case .failure(let error):
                self.error = "Failed to get activity details: \(error.localizedDescription)"
            }
        }
    }
    
    /**
     Clear the selected activity.
     */
    func clearSelectedActivity() {
        selectedActivity = nil
    }
    
    /**
     Get a URL for a photo of an activity.
     
     - Parameter activity: The activity to get a photo for
     - Returns: URL for the photo, if available
     */
    func getPhotoURL(for activity: ActivityPlace) -> URL? {
        guard let photoReference = activity.photoReference else {
            return nil
        }
        
        return placesService.getPhotoURL(photoReference: photoReference)
    }
    
    /**
     Get a URL for a photo from a photo reference.
     
     - Parameter photo: The photo to get a URL for
     - Returns: URL for the photo
     */
    func getPhotoURL(for photo: PlacePhoto) -> URL? {
        return placesService.getPhotoURL(photoReference: photo.reference)
    }
    
    /**
     Create a playdate at the selected activity location.
     
     - Parameters:
        - title: Title for the playdate
        - description: Description for the playdate
        - startDate: Start date and time
        - endDate: End date and time
        - hostID: ID of the user hosting the playdate
        - completion: Callback with result
     */
    func createPlaydateAtSelectedActivity(
        title: String,
        description: String,
        startDate: Date,
        endDate: Date,
        hostID: String,
        completion: @escaping (Result<Playdate, Error>) -> Void
    ) {
        guard let activity = selectedActivity else {
            let error = NSError(domain: "ActivitySearchViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "No activity selected"])
            completion(.failure(error))
            return
        }
        
        // Create a location from the activity
        // Create the playdate
        let playdate = Playdate(
            hostID: hostID,
            title: title,
            description: description,
            activityType: searchQuery,
            location: activity.location,
            address: activity.location.address,
            startDate: startDate,
            endDate: endDate,
            attendeeIDs: [hostID],
            isPublic: true,
            createdAt: Date()
        )
        
        // Use the PlaydateViewModel to create the playdate
        let playdateViewModel = PlaydateViewModel()
        playdateViewModel.createPlaydate(playdate, completion: completion)
    }
}
