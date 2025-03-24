import Foundation
import CoreLocation

/// Singleton class to store cache and state for GooglePlacesService
/// This is needed because Swift extensions cannot contain stored properties
class GooglePlacesServiceCache {
    // Singleton instance
    static let shared = GooglePlacesServiceCache()
    
    // Private initializer for singleton
    private init() {}
    
    // Cache for place search results
    var placeSearchCache: [String: [ActivityPlace]] = [:]
    
    // Request management
    var searchQueue: [(location: CLLocation, radius: Int, activityType: String, completion: (Result<[ActivityPlace], Error>) -> Void)] = []
    var isProcessingSearchQueue = false
    var lastSearchTime: Date? = nil
    
    // Cache for place details
    var placeDetailsCache: [String: ActivityPlace] = [:]
    var lastDetailsRequestTime: Date? = nil
    
    // Rate limiting constants
    let searchThrottleInterval: TimeInterval = 2.0 // 2 seconds between searches
    let detailsThrottleInterval: TimeInterval = 1.0 // 1 second between details requests
    
    // Maximum number of requests per session
    let maxRequestsPerSession = 100
    var requestCount = 0
}
