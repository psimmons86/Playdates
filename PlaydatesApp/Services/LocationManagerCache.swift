import Foundation
import CoreLocation

/// Singleton class to store cache and state for LocationManager
/// This is needed because Swift extensions cannot contain stored properties
class LocationManagerCache {
    // Singleton instance
    static let shared = LocationManagerCache()
    
    // Private initializer for singleton
    private init() {}
    
    // Cache for geocoding results
    var geocodingCache: [String: CLPlacemark] = [:]
    
    // Geocoding request management
    var geocodingQueue: [CLLocation] = []
    var isProcessingGeocodingQueue = false
    var lastGeocodingTime: Date? = nil
    
    // Cache for local search results
    var localSearchCache: [String: [MKMapItem]] = [:]
    var lastSearchTime: Date? = nil
    
    // Cache for directions
    var directionsCache: [String: MKRoute] = [:]
    var lastDirectionsTime: Date? = nil
    
    // Cache for forward geocoding (address to location)
    var forwardGeocodingCache: [String: CLLocation] = [:]
}
