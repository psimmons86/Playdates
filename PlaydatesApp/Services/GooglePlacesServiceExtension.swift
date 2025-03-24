import Foundation
import CoreLocation

// Extension to GooglePlacesService to add throttling and caching
extension GooglePlacesService {
    
    // MARK: - Helper Methods for Nearby Search
    
    /// Perform the actual nearby search
    func performNearbySearch(
        location: CLLocation,
        radius: Int,
        activityType: String,
        completion: @escaping (Result<[ActivityPlace], Error>) -> Void
    ) {
        // This method is implemented in the main GooglePlacesService class
        // Just call the main method
        searchNearbyActivities(location: location, radius: radius, activityType: activityType, completion: completion)
    }
    
    // MARK: - Helper Methods for Place Details
    
    /// Fetch place details
    func fetchPlaceDetails(
        placeID: String,
        completion: @escaping (Result<ActivityPlace, Error>) -> Void
    ) {
        // Get the place details
        getPlaceDetails(placeId: placeID) { result in
            switch result {
            case .success(let details):
                // Convert ActivityPlaceDetail to ActivityPlace
                let place = ActivityPlace(
                    id: details.id,
                    name: details.name,
                    location: Location(
                        name: details.name,
                        address: details.address ?? "Unknown",
                        latitude: 0, // We don't have coordinates in the details
                        longitude: 0
                    ),
                    types: [], // We don't have types in the details
                    rating: details.rating,
                    userRatingsTotal: details.reviews?.count,
                    photoReference: details.photos?.first?.reference
                )
                completion(.success(place))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
