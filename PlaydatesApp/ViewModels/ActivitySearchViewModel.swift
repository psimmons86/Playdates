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
    @Published var selectedActivity: ActivityPlaceDetail?
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
        
        guard let location = locationManager.location else {
            error = "Location not available. Please enable location services."
            print("Debug: Location is nil when searching")
            return
        }
        
        print("Debug: Searching for '\(searchQuery)' at location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLoading = true
        error = nil
        
        placesService.searchNearbyActivities(
            location: location,
            activityType: searchQuery
        ) { [weak self] (result: Result<[ActivityPlace], Error>) in // Added explicit type annotation
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let activities):
                print("Debug: Received \(activities.count) activities from API")
                self.activities = activities
                if activities.isEmpty {
                    self.error = "No activities found for '\(self.searchQuery)'. Try a different search term."
                    print("Debug: API returned empty activities array")
                }
            case .failure(let error):
                print("Debug: API error: \(error.localizedDescription)")
                self.error = "Failed to search activities: \(error.localizedDescription)"
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
        
        placesService.getPlaceDetails(placeId: activity.id) { [weak self] (result: Result<ActivityPlaceDetail, Error>) in // Added explicit type annotation
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
        let location = Location(
            name: activity.name,
            address: activity.address ?? "Unknown address",
            latitude: 0, // We need to get these from the original ActivityPlace
            longitude: 0
        )
        
        // Find the original activity to get coordinates
        if let originalActivity = activities.first(where: { $0.id == activity.id }) {
            let location = Location(
                name: activity.name,
                address: activity.address ?? "Unknown address",
                latitude: originalActivity.location.latitude,
                longitude: originalActivity.location.longitude
            )
            
            // Create the playdate
            let playdate = Playdate(
                hostID: hostID,
                title: title,
                description: description,
                activityType: searchQuery,
                location: location,
                address: activity.address,
                startDate: startDate,
                endDate: endDate,
                attendeeIDs: [hostID],
                isPublic: true,
                createdAt: Date()
            )
            
            // Use the PlaydateViewModel to create the playdate
            let playdateViewModel = PlaydateViewModel()
            playdateViewModel.createPlaydate(playdate, completion: completion)
        } else {
            // If we can't find the original activity, create a playdate without coordinates
            let playdate = Playdate(
                hostID: hostID,
                title: title,
                description: description,
                activityType: searchQuery,
                location: location,
                address: activity.address,
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
}
