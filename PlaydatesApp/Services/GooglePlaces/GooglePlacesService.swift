import Foundation
import CoreLocation
import FirebaseFirestore


/**
 Service for interacting with Google Places API to find activities and points of interest.
 */
class GooglePlacesService {
    // The API key for Google Places API
    private let apiKey = "AIzaSyAizodPXBx6YTkwV09flC0tKwwHSXP5ESI"
    
    // Base URL for Google Places API
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    // Singleton instance
    static let shared = GooglePlacesService()
    
    // Throttling properties
    private var lastRequestTime: Date?
    private let requestThrottleInterval: TimeInterval = 1.0 // 1 second between requests
    
    // Cache instance
    private let cache = GooglePlacesServiceCache.shared
    
    private init() {}
    
    /// Throttle API requests to prevent hitting rate limits
    private func throttleIfNeeded(completion: @escaping () -> Void) {
        if let lastTime = lastRequestTime, 
           Date().timeIntervalSince(lastTime) < requestThrottleInterval {
            // Need to throttle
            let delayTime = requestThrottleInterval - Date().timeIntervalSince(lastTime)
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                self.lastRequestTime = Date()
                completion()
            }
        } else {
            // No need to throttle
            lastRequestTime = Date()
            completion()
        }
    }
    
    /**
     Search for nearby activities based on location and activity type.
     
     - Parameters:
        - location: The location to search around
        - radius: Search radius in meters (max 50000)
        - activityType: Type of activity to search for (e.g., "park", "museum", "playground")
        - completion: Callback with search results or error
     */
    func searchNearbyActivities(
        location: CLLocation,
        radius: Int = 5000,
        activityType: String,
        completion: @escaping (Result<[ActivityPlace], Error>) -> Void
    ) {
        // Create a cache key based on location, radius, and activity type
        // Round coordinates to reduce precision for better cache hits
        let roundedLat = round(location.coordinate.latitude * 10) / 10 // ~10km precision
        let roundedLng = round(location.coordinate.longitude * 10) / 10
        let cacheKey = "\(roundedLat),\(roundedLng)|\(radius)|\(activityType.lowercased())"
        
        print("Debug: Searching for activities near \(location.coordinate.latitude),\(location.coordinate.longitude)")
        print("Debug: Activity type: \(activityType), mapped to: \(mapActivityTypeToPlaceType(activityType))")
        
        // Check cache first
        if let cachedResults = cache.placeSearchCache[cacheKey],
           let lastTime = cache.lastSearchTime,
           Date().timeIntervalSince(lastTime) < cache.searchThrottleInterval {
            // Cache hit - return cached results
            print("Debug: Returning \(cachedResults.count) cached results for \(activityType)")
            DispatchQueue.main.async {
                completion(.success(cachedResults))
            }
            return
        }
        
        // Cache miss - need to make API request
        // Construct the URL for the Nearby Search request
        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        
        // Enhance search with better parameters
        let placeType = mapActivityTypeToPlaceType(activityType)
        let enhancedKeyword = enhanceKeywordForFamilyFriendly(activityType)
        
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: placeType),
            URLQueryItem(name: "keyword", value: enhancedKeyword),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "GooglePlacesService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("Debug: Making Places API request to URL: \(url)")
        
        // Throttle the request if needed
        throttleIfNeeded {
            // Create and execute the request
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "GooglePlacesService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    // Log the raw response for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Debug: Google Places API raw response: \(jsonString)")
                    }
                    
                    // Parse the JSON response
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    print("Debug: Google Places API status: \(response.status)")
                    
                    // Check if the request was successful
                    guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                        print("Debug: Google Places API error status: \(response.status)")
                        throw NSError(domain: "GooglePlacesService", code: 3, userInfo: [NSLocalizedDescriptionKey: "API Error: \(response.status)"])
                    }
                    
                    print("Debug: Google Places API returned \(response.results.count) results")
                    
                    // Map the results to ActivityPlace objects
                    let activities = response.results.map { result -> ActivityPlace in
                        let location = Location(
                            name: result.name,
                            address: result.vicinity,
                            latitude: result.geometry.location.lat,
                            longitude: result.geometry.location.lng
                        )
                        
                        print("Debug: Found place: \(result.name) at \(result.geometry.location.lat), \(result.geometry.location.lng)")
                        
                        return ActivityPlace(
                            id: result.placeId,
                            name: result.name,
                            location: location,
                            types: result.types,
                            rating: result.rating,
                            userRatingsTotal: result.userRatingsTotal,
                            photoReference: result.photos?.first?.photoReference
                        )
                    }
                    
                    // Store in cache
                    self.cache.placeSearchCache[cacheKey] = activities
                    self.cache.lastSearchTime = Date()
                    
                    // Always update UI on the main thread
                    DispatchQueue.main.async {
                        completion(.success(activities))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    /**
     Get details for a specific place by its ID.
     
     - Parameters:
        - placeId: The Google Place ID
        - completion: Callback with place details or error
     */
    func getPlaceDetails(
        placeId: String,
        completion: @escaping (Result<ActivityPlace, Error>) -> Void
    ) {
        // Check cache first
        if let cachedDetail = cache.placeDetailsCache[placeId],
           let lastTime = cache.lastDetailsRequestTime,
           Date().timeIntervalSince(lastTime) < cache.detailsThrottleInterval {
            // Cache hit - return cached results
            DispatchQueue.main.async {
                completion(.success(cachedDetail))
            }
            return
        }
        
        // Cache miss - need to make API request
        // Construct the URL for the Place Details request
        var components = URLComponents(string: "\(baseURL)/details/json")!
        
        components.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,formatted_address,formatted_phone_number,website,opening_hours,rating,review,price_level,photo"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "GooglePlacesService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        print("Debug: Making Place Details API request to URL: \(url)")
        
        // Throttle the request if needed
        throttleIfNeeded {
            // Create and execute the request
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "GooglePlacesService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    }
                    return
                }
                
                do {
                    // Log the raw response for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Debug: Google Places Details API raw response: \(jsonString)")
                    }
                    
                    // Parse the JSON response
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlaceDetailsResponse.self, from: data)
                    
                    print("Debug: Google Places Details API status: \(response.status)")
                    
                    // Check if the request was successful
                    guard response.status == "OK" else {
                        print("Debug: Google Places Details API error status: \(response.status)")
                        throw NSError(domain: "GooglePlacesService", code: 3, userInfo: [NSLocalizedDescriptionKey: "API Error: \(response.status)"])
                    }
                    
                    // Map the result to an ActivityPlace object
                    let result = response.result
                    print("Debug: Got details for place: \(result.name)")
                    
                    let location = Location(
                        name: result.name,
                        address: result.formattedAddress ?? "",
                        latitude: 0.0, // We don't have coordinates in details response
                        longitude: 0.0
                    )
                    
                    let place = ActivityPlace(
                        id: placeId,
                        name: result.name,
                        location: location,
                        types: [], // We don't have types in details response
                        rating: result.rating,
                        userRatingsTotal: nil,
                        photoReference: result.photos?.first?.photoReference
                    )
                    
                    // Store in cache
                    self.cache.placeDetailsCache[placeId] = place
                    self.cache.lastDetailsRequestTime = Date()
                    
                    // Always update UI on the main thread
                    DispatchQueue.main.async {
                        completion(.success(place))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
            
            task.resume()
        }
    }
    
    /**
     Get a photo URL for a given photo reference.
     
     - Parameters:
        - photoReference: The photo reference from the Places API
        - maxWidth: Maximum width of the photo (optional)
        - maxHeight: Maximum height of the photo (optional)
        - completion: Callback with the URL or error
     */
    func getPhotoURL(photoReference: String, maxWidth: Int = 400, maxHeight: Int? = nil) -> URL? {
        // This method just constructs a URL, no need to throttle
        var components = URLComponents(string: "\(baseURL)/photo")!
        
        var queryItems = [
            URLQueryItem(name: "photoreference", value: photoReference),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let maxHeight = maxHeight {
            queryItems.append(URLQueryItem(name: "maxheight", value: "\(maxHeight)"))
        } else {
            queryItems.append(URLQueryItem(name: "maxwidth", value: "\(maxWidth)"))
        }
        
        components.queryItems = queryItems
        
        return components.url
    }
    
    /**
     Load a photo for a given photo reference with throttling.
     
     - Parameters:
        - photoReference: The photo reference from the Places API
        - maxWidth: Maximum width of the photo (optional)
        - maxHeight: Maximum height of the photo (optional)
        - completion: Callback with the data or error
     */
    func loadPhoto(photoReference: String, maxWidth: Int = 400, maxHeight: Int? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = getPhotoURL(photoReference: photoReference, maxWidth: maxWidth, maxHeight: maxHeight) else {
            completion(.failure(NSError(domain: "GooglePlacesService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid photo URL"])))
            return
        }
        
        // Throttle the request if needed
        throttleIfNeeded {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "GooglePlacesService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No photo data received"])))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            }
            
            task.resume()
        }
    }
    
    /**
     Enhance keyword for family-friendly activities
     
     - Parameter activityType: The app's activity type
     - Returns: Enhanced keyword for better search results
     */
    private func enhanceKeywordForFamilyFriendly(_ activityType: String) -> String {
        // If the activity type is generic, add "family friendly" or "kids"
        let lowercased = activityType.lowercased()
        
        if lowercased == "family_friendly" {
            return "family activities kids"
        }
        
        // Handle category names from ExploreView
        if lowercased.contains("park") {
            return "park playground family kids"
        } else if lowercased.contains("playground") {
            return "playground kids family"
        } else if lowercased.contains("museum") {
            return "museum family kids children educational"
        } else if lowercased.contains("zoo") {
            return "zoo animals family kids"
        } else if lowercased.contains("aquarium") {
            return "aquarium sea life family kids"
        } else if lowercased.contains("librar") {
            return "library books reading family kids"
        } else if lowercased.contains("swim") || lowercased.contains("pool") {
            return "swimming pool family kids"
        } else if lowercased.contains("sport") {
            return "sports recreation family kids"
        } else if lowercased.contains("theme park") || lowercased.contains("amusement") {
            return "theme park amusement rides family kids"
        } else if lowercased.contains("movie") || lowercased.contains("cinema") {
            return "movie theater cinema family kids"
        }
        
        // For other types, just add "family" to the search
        return "\(lowercased) family kids"
    }
    
    /**
     Map activity types from the app's terminology to Google Places API types.
     
     - Parameter activityType: The app's activity type
     - Returns: Corresponding Google Places API type
     */
    private func mapActivityTypeToPlaceType(_ activityType: String) -> String {
        // Map common activity types to Google Places API types
        // Handle both singular and plural forms, and case-insensitive matching
        let lowercased = activityType.lowercased()
        
        // Handle category names from ExploreView
        if lowercased.contains("park") || lowercased.contains("playground") {
            return "park"
        } else if lowercased.contains("museum") {
            return "museum"
        } else if lowercased.contains("zoo") {
            return "zoo"
        } else if lowercased.contains("aquarium") {
            return "aquarium"
        } else if lowercased.contains("librar") {
            return "library"
        } else if lowercased.contains("swim") || lowercased.contains("pool") {
            return "swimming_pool"
        } else if lowercased.contains("sport") || lowercased.contains("athletic") {
            return "stadium"
        } else if lowercased.contains("amusement") || lowercased.contains("theme park") {
            return "amusement_park"
        } else if lowercased.contains("art") {
            return "art_gallery"
        } else if lowercased.contains("bowl") {
            return "bowling_alley"
        } else if lowercased.contains("movie") || lowercased.contains("cinema") {
            return "movie_theater"
        } else if lowercased.contains("restaurant") || lowercased.contains("food") || lowercased.contains("dining") {
            return "restaurant"
        } else if lowercased.contains("cafe") || lowercased.contains("coffee") {
            return "cafe"
        } else if lowercased.contains("ice cream") {
            return "ice_cream"
        } else if lowercased.contains("shop") {
            return "shopping_mall"
        } else if lowercased == "family_friendly" {
            // For generic family-friendly search, use a broader type
            return "tourist_attraction"
        } else {
            // For other types, just use the original term as a keyword
            return "point_of_interest"
        }
    }
}
