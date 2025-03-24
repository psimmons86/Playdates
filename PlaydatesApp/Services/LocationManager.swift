import Foundation
import CoreLocation
import MapKit
import Combine

// Cache class for LocationManager
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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Singleton instance for easy access throughout the app
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var placemark: CLPlacemark?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    // Geocoding throttling and caching
    private var geocodingTimer: Timer?
    private var geocodingCache: [String: CLPlacemark] = [:]
    private var lastGeocodingTime: Date?
    private let geocodingThrottleInterval: TimeInterval = 1.0 // 1 second between requests
    
    override init() {
        super.init()
        locationManager.delegate = self
        
        // Reduce accuracy to save battery and reduce update frequency
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // Only update when user moves at least 100 meters
        locationManager.distanceFilter = 100
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Start monitoring significant location changes
    /// This is more battery efficient for background updates
    func startMonitoringSignificantLocationChanges() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    /// Stop monitoring significant location changes
    func stopMonitoringSignificantLocationChanges() {
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.stopMonitoringSignificantLocationChanges()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access is denied. Please enable it in Settings."
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        self.location = location
        self.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        // Use safe geocoding method from MainTabView extension
        safeReverseGeocode(location: location)
    }
    
    // Add this method to throttle reverse geocoding requests
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
    
    // MARK: - Geocoding with Throttling and Caching
    
    /// Throttled reverse geocoding to prevent hitting API limits
    func reverseGeocode(location: CLLocation) {
        // Cancel any existing timer
        geocodingTimer?.invalidate()
        
        // Check if we need to throttle based on last request time
        if let lastTime = lastGeocodingTime, 
           Date().timeIntervalSince(lastTime) < geocodingThrottleInterval {
            // Set a timer to delay the request
            geocodingTimer = Timer.scheduledTimer(withTimeInterval: geocodingThrottleInterval, repeats: false) { [weak self] _ in
                self?.performReverseGeocoding(location: location)
            }
        } else {
            // No need to throttle, perform immediately
            performReverseGeocoding(location: location)
        }
    }
    
    /// Perform actual reverse geocoding with caching
    private func performReverseGeocoding(location: CLLocation) {
        // Update last geocoding time
        lastGeocodingTime = Date()
        
        // Create a cache key based on rounded coordinates (3 decimal places ≈ 100m precision)
        let roundedLat = round(location.coordinate.latitude * 1000) / 1000
        let roundedLng = round(location.coordinate.longitude * 1000) / 1000
        let cacheKey = "\(roundedLat),\(roundedLng)"
        
        // Check cache first
        if let cachedPlacemark = geocodingCache[cacheKey] {
            self.placemark = cachedPlacemark
            return
        }
        
        // Not in cache, perform geocoding
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "Geocoding error: \(error.localizedDescription)"
                return
            }
            
            if let placemark = placemarks?.first {
                // Store in cache
                self.geocodingCache[cacheKey] = placemark
                self.placemark = placemark
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
    
    // MARK: - Local Search with Throttling and Caching
    
    // Cache for local search results
    private var localSearchCache: [String: [MKMapItem]] = [:]
    private var lastSearchTime: Date?
    private let searchThrottleInterval: TimeInterval = 2.0 // 2 seconds between searches
    private var searchTimer: Timer?
    
    /// Generic search method for any activity type with throttling and caching
    func searchNearbyActivities(for activityType: String, radius: CLLocationDistance = 5000) {
        guard let location = location else {
            errorMessage = "Location not available"
            return
        }
        
        isSearching = true
        
        // Just use the string directly for the search term
        let searchTerm: String
        switch activityType.lowercased() {
        case "park":
            searchTerm = "park"
        case "theme park":
            searchTerm = "theme park"
        case "beach":
            searchTerm = "beach"
        case "museum":
            searchTerm = "museum"
        case "summer camp":
            searchTerm = "summer camp"
        case "zoo":
            searchTerm = "zoo"
        case "aquarium":
            searchTerm = "aquarium"
        case "library":
            searchTerm = "library"
        case "playground":
            searchTerm = "playground"
        case "sporting event":
            searchTerm = "sports venue"
        case "movie theater":
            searchTerm = "movie theater"
        case "swimming pool":
            searchTerm = "swimming pool"
        case "hiking trail":
            searchTerm = "hiking trail"
        case "indoor play area":
            searchTerm = "indoor playground"
        default:
            searchTerm = activityType.lowercased() // Use the provided string directly
        }
        
        // Create a cache key based on search term and rounded location
        let roundedLat = round(location.coordinate.latitude * 10) / 10 // ~10km precision
        let roundedLng = round(location.coordinate.longitude * 10) / 10
        let cacheKey = "\(searchTerm)|\(roundedLat),\(roundedLng)|\(Int(radius))"
        
        // Check cache first
        if let cachedResults = localSearchCache[cacheKey] {
            self.searchResults = cachedResults
            self.isSearching = false
            return
        }
        
        // Cancel any existing timer
        searchTimer?.invalidate()
        
        // Check if we need to throttle
        if let lastTime = lastSearchTime,
           Date().timeIntervalSince(lastTime) < searchThrottleInterval {
            
            // Set a timer to delay the request
            searchTimer = Timer.scheduledTimer(withTimeInterval: searchThrottleInterval, repeats: false) { [weak self] _ in
                self?.performLocalSearch(searchTerm: searchTerm, location: location, radius: radius, cacheKey: cacheKey)
            }
        } else {
            // No need to throttle
            performLocalSearch(searchTerm: searchTerm, location: location, radius: radius, cacheKey: cacheKey)
        }
    }
    
    /// Perform actual local search with caching
    private func performLocalSearch(searchTerm: String, location: CLLocation, radius: CLLocationDistance, cacheKey: String) {
        // Update last search time
        lastSearchTime = Date()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            defer { self.isSearching = false }
            
            if let error = error {
                self.errorMessage = "Search error: \(error.localizedDescription)"
                return
            }
            
            guard let response = response else {
                self.errorMessage = "No results found"
                return
            }
            
            // Store in cache
            self.localSearchCache[cacheKey] = response.mapItems
            
            // Update results
            self.searchResults = response.mapItems
        }
    }
    
    // MARK: - Directions with Throttling and Caching
    
    // Cache for directions
    private var directionsCache: [String: MKRoute] = [:]
    private var lastDirectionsTime: Date?
    private let directionsThrottleInterval: TimeInterval = 2.0 // 2 seconds between directions requests
    
    /// Get directions with throttling and caching
    func getDirections(to destination: CLLocationCoordinate2D, transportType: MKDirectionsTransportType = .automobile) -> AnyPublisher<MKRoute, Error> {
        guard let location = location else {
            return Fail(error: NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Current location not available"]))
                .eraseToAnyPublisher()
        }
        
        // Create a cache key based on rounded coordinates and transport type
        let roundedSourceLat = round(location.coordinate.latitude * 1000) / 1000
        let roundedSourceLng = round(location.coordinate.longitude * 1000) / 1000
        let roundedDestLat = round(destination.latitude * 1000) / 1000
        let roundedDestLng = round(destination.longitude * 1000) / 1000
        let cacheKey = "\(roundedSourceLat),\(roundedSourceLng)|\(roundedDestLat),\(roundedDestLng)|\(transportType.rawValue)"
        
        return Future<MKRoute, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "LocationManager not available"])))
                return
            }
            
            // Check cache first
            if let cachedRoute = self.directionsCache[cacheKey] {
                promise(.success(cachedRoute))
                return
            }
            
            // Check if we need to throttle
            if let lastTime = self.lastDirectionsTime,
               Date().timeIntervalSince(lastTime) < self.directionsThrottleInterval {
                
                // Delay the request
                DispatchQueue.main.asyncAfter(deadline: .now() + self.directionsThrottleInterval) {
                    self.performDirectionsRequest(
                        sourceCoordinate: location.coordinate,
                        destinationCoordinate: destination,
                        transportType: transportType,
                        cacheKey: cacheKey,
                        promise: promise
                    )
                }
            } else {
                // No need to throttle
                self.performDirectionsRequest(
                    sourceCoordinate: location.coordinate,
                    destinationCoordinate: destination,
                    transportType: transportType,
                    cacheKey: cacheKey,
                    promise: promise
                )
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Perform actual directions request with caching
    private func performDirectionsRequest(
        sourceCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType,
        cacheKey: String,
        promise: @escaping (Result<MKRoute, Error>) -> Void
    ) {
        // Update last directions time
        lastDirectionsTime = Date()
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = sourceItem
        request.destination = destinationItem
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                promise(.failure(error))
                return
            }
            
            guard let route = response?.routes.first else {
                promise(.failure(NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No route found"])))
                return
            }
            
            // Store in cache
            self.directionsCache[cacheKey] = route
            
            promise(.success(route))
        }
    }
    
    // MARK: - Forward Geocoding with Throttling and Caching
    
    // Cache for forward geocoding (address to location)
    private var forwardGeocodingCache: [String: CLLocation] = [:]
    
    /// Geocode an address to coordinates with throttling and caching
    func geocodeAddress(_ address: String) -> AnyPublisher<CLLocation, Error> {
        return Future<CLLocation, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "LocationManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "LocationManager not available"])))
                return
            }
            
            // Normalize address for caching
            let normalizedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            // Check cache first
            if let cachedLocation = self.forwardGeocodingCache[normalizedAddress] {
                promise(.success(cachedLocation))
                return
            }
            
            // Check if we need to throttle
            if let lastTime = self.lastGeocodingTime, 
               Date().timeIntervalSince(lastTime) < self.geocodingThrottleInterval {
                
                // Delay the request
                DispatchQueue.main.asyncAfter(deadline: .now() + self.geocodingThrottleInterval) {
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
        // Update last geocoding time
        lastGeocodingTime = Date()
        
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
            self.forwardGeocodingCache[address] = location
            
            promise(.success(location))
        }
    }
}
