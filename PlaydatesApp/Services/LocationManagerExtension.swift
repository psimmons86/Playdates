import Foundation
import CoreLocation
import MapKit
import Combine

// Extension to LocationManager to add geocoding and search functionality
extension LocationManager {
    
    // MARK: - Reverse Geocoding with Throttling and Caching
    
    /// Safely reverse geocode a location with throttling and caching
    func safeReverseGeocode(location: CLLocation) {
        let cache = LocationManagerCache.shared
        
        // Create a key based on coordinates with reduced precision to use fewer distinct geocoding requests
        let roundedLat = round(location.coordinate.latitude * 100) / 100
        let roundedLng = round(location.coordinate.longitude * 100) / 100
        let key = "\(roundedLat),\(roundedLng)"
        
        // If this location is already in the cache, use the cached result
        if let cachedPlacemark = cache.geocodingCache[key] {
            self.placemark = cachedPlacemark
            return
        }
        
        // Otherwise, add to queue and process if not already processing
        cache.geocodingQueue.append(location)
        processGeocodingQueue()
    }
    
    /// Process the geocoding queue with rate limiting
    private func processGeocodingQueue() {
        let cache = LocationManagerCache.shared
        
        // If already processing or queue is empty, return
        if cache.isProcessingGeocodingQueue || cache.geocodingQueue.isEmpty {
            return
        }
        
        cache.isProcessingGeocodingQueue = true
        
        // Rate limit: max 1 request per 1.2 seconds
        let now = Date()
        if let lastRequest = cache.lastGeocodingTime, now.timeIntervalSince(lastRequest) < 1.2 {
            // Need to wait before making another request
            let delay = 1.2 - now.timeIntervalSince(lastRequest)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.processGeocodingQueue()
            }
            return
        }
        
        // Take the next location from the queue
        let location = cache.geocodingQueue.removeFirst()
        cache.lastGeocodingTime = now
        
        // Perform the geocoding
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            // Store the result if successful
            if let placemark = placemarks?.first {
                self.placemark = placemark
                
                // Cache the result
                let roundedLat = round(location.coordinate.latitude * 100) / 100
                let roundedLng = round(location.coordinate.longitude * 100) / 100
                let key = "\(roundedLat),\(roundedLng)"
                cache.geocodingCache[key] = placemark
            }
            
            // Mark as done processing and continue with queue if needed
            cache.isProcessingGeocodingQueue = false
            
            // If there are more items, continue processing after a delay
            if !cache.geocodingQueue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.processGeocodingQueue()
                }
            }
        }
    }
    
    // MARK: - Forward Geocoding with Throttling and Caching
    
    /// Geocode an address to coordinates with throttling and caching
    func safeGeocodeAddress(_ address: String) -> AnyPublisher<CLLocation, Error> {
        let cache = LocationManagerCache.shared
        
        return Future<CLLocation, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "LocationManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "LocationManager not available"])))
                return
            }
            
            // Normalize address for caching
            let normalizedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Check cache first
            if let cachedLocation = cache.forwardGeocodingCache[normalizedAddress] {
                promise(.success(cachedLocation))
                return
            }
            
            // Check if we need to throttle
            if let lastTime = cache.lastGeocodingTime, 
               Date().timeIntervalSince(lastTime) < 1.2 {
                
                // Delay the request
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.performForwardGeocoding(address: normalizedAddress, promise: promise)
                }
            } else {
                // No need to throttle
                self.performForwardGeocoding(address: normalizedAddress, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Perform actual forward geocoding with caching
    private func performForwardGeocoding(address: String, promise: @escaping (Result<CLLocation, Error>) -> Void) {
        let cache = LocationManagerCache.shared
        
        // Update last geocoding time
        cache.lastGeocodingTime = Date()
        
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                promise(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                promise(.failure(NSError(domain: "LocationManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not geocode address"])))
                return
            }
            
            // Store in cache
            cache.forwardGeocodingCache[address] = location
            
            promise(.success(location))
        }
    }
}
