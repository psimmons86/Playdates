import Foundation
import CoreLocation

// Cache class for GooglePlacesService
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

/**
 Service for interacting with Google Places API to find activities and points of interest.
 */
class GooglePlacesService {
    // The API key for Google Places API
    private let apiKey = "AIzaSyBLEgfEKCQbkMR4kCgy77bGOJVcTwPv7iI"
    
    // Base URL for Google Places API
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    // Singleton instance
    static let shared = GooglePlacesService()
    
    // Throttling and caching properties
    private var lastRequestTime: Date?
    private let requestThrottleInterval: TimeInterval = 1.0 // 1 second between requests
    
    // Cache for nearby search results
    private var nearbySearchCache: [String: [ActivityPlace]] = [:]
    private let nearbySearchCacheExpiration: TimeInterval = 300 // 5 minutes
    private var nearbySearchCacheTimestamps: [String: Date] = [:]
    
    // Cache for place details
    private var placeDetailsCache: [String: ActivityPlaceDetail] = [:]
    private let placeDetailsCacheExpiration: TimeInterval = 3600 // 1 hour
    private var placeDetailsCacheTimestamps: [String: Date] = [:]
    
    private init() {
        // Set up a timer to clean expired cache entries every 10 minutes
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.cleanExpiredCacheEntries()
        }
    }
    
    /// Clean expired cache entries
    private func cleanExpiredCacheEntries() {
        let now = Date()
        
        // Clean nearby search cache
        for (key, timestamp) in nearbySearchCacheTimestamps {
            if now.timeIntervalSince(timestamp) > nearbySearchCacheExpiration {
                nearbySearchCache.removeValue(forKey: key)
                nearbySearchCacheTimestamps.removeValue(forKey: key)
            }
        }
        
        // Clean place details cache
        for (key, timestamp) in placeDetailsCacheTimestamps {
            if now.timeIntervalSince(timestamp) > placeDetailsCacheExpiration {
                placeDetailsCache.removeValue(forKey: key)
                placeDetailsCacheTimestamps.removeValue(forKey: key)
            }
        }
    }
    
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
        
        // Check cache first
        if let cachedResults = nearbySearchCache[cacheKey],
           let timestamp = nearbySearchCacheTimestamps[cacheKey],
           Date().timeIntervalSince(timestamp) < nearbySearchCacheExpiration {
            // Cache hit - return cached results
            DispatchQueue.main.async {
                completion(.success(cachedResults))
            }
            return
        }
        
        // Cache miss - need to make API request
        // Construct the URL for the Nearby Search request
        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")!
        
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: mapActivityTypeToPlaceType(activityType)),
            URLQueryItem(name: "keyword", value: activityType),
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
                    // Parse the JSON response
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    // Check if the request was successful
                    guard response.status == "OK" || response.status == "ZERO_RESULTS" else {
                        throw NSError(domain: "GooglePlacesService", code: 3, userInfo: [NSLocalizedDescriptionKey: "API Error: \(response.status)"])
                    }
                    
                    // Map the results to ActivityPlace objects
                    let activities = response.results.map { result -> ActivityPlace in
                        let location = Location(
                            name: result.name,
                            address: result.vicinity,
                            latitude: result.geometry.location.lat,
                            longitude: result.geometry.location.lng
                        )
                        
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
                    self.nearbySearchCache[cacheKey] = activities
                    self.nearbySearchCacheTimestamps[cacheKey] = Date()
                    
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
        completion: @escaping (Result<ActivityPlaceDetail, Error>) -> Void
    ) {
        // Check cache first
        if let cachedDetail = placeDetailsCache[placeId],
           let timestamp = placeDetailsCacheTimestamps[placeId],
           Date().timeIntervalSince(timestamp) < placeDetailsCacheExpiration {
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
                    // Parse the JSON response
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlaceDetailsResponse.self, from: data)
                    
                    // Check if the request was successful
                    guard response.status == "OK" else {
                        throw NSError(domain: "GooglePlacesService", code: 3, userInfo: [NSLocalizedDescriptionKey: "API Error: \(response.status)"])
                    }
                    
                    // Map the result to an ActivityPlaceDetail object
                    let result = response.result
                    let detail = ActivityPlaceDetail(
                        id: placeId,
                        name: result.name,
                        address: result.formattedAddress,
                        phoneNumber: result.formattedPhoneNumber,
                        website: result.website,
                        isOpen: result.openingHours?.openNow,
                        weekdayHours: result.openingHours?.weekdayText,
                        rating: result.rating,
                        reviews: result.reviews?.map { review in
                            return PlaceReview(
                                authorName: review.authorName,
                                rating: review.rating,
                                text: review.text,
                                time: Date(timeIntervalSince1970: TimeInterval(review.time))
                            )
                        },
                        priceLevel: result.priceLevel,
                        photos: result.photos?.map { photo in
                            return PlacePhoto(
                                reference: photo.photoReference,
                                width: photo.width,
                                height: photo.height
                            )
                        }
                    )
                    
                    // Store in cache
                    self.placeDetailsCache[placeId] = detail
                    self.placeDetailsCacheTimestamps[placeId] = Date()
                    
                    DispatchQueue.main.async {
                        completion(.success(detail))
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
     Map activity types from the app's terminology to Google Places API types.
     
     - Parameter activityType: The app's activity type
     - Returns: Corresponding Google Places API type
     */
    private func mapActivityTypeToPlaceType(_ activityType: String) -> String {
        // Map common activity types to Google Places API types
        switch activityType.lowercased() {
        case "park", "playground":
            return "park"
        case "museum":
            return "museum"
        case "zoo":
            return "zoo"
        case "aquarium":
            return "aquarium"
        case "library":
            return "library"
        case "swimming", "pool":
            return "swimming_pool"
        case "sports", "athletics":
            return "stadium"
        case "amusement", "theme park":
            return "amusement_park"
        case "art":
            return "art_gallery"
        case "bowling":
            return "bowling_alley"
        case "movie", "cinema":
            return "movie_theater"
        default:
            // For other types, just use the original term as a keyword
            return "point_of_interest"
        }
    }
}

// MARK: - Data Models

/**
 Represents a place found through the Google Places API.
 */
struct ActivityPlace: Identifiable {
    let id: String
    let name: String
    let location: Location
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let photoReference: String?
    
    var formattedRating: String {
        guard let rating = rating else { return "No ratings" }
        return String(format: "%.1f/5", rating)
    }
}

/**
 Detailed information about a place.
 */
struct ActivityPlaceDetail {
    let id: String
    let name: String
    let address: String?
    let phoneNumber: String?
    let website: String?
    let isOpen: Bool?
    let weekdayHours: [String]?
    let rating: Double?
    let reviews: [PlaceReview]?
    let priceLevel: Int?
    let photos: [PlacePhoto]?
    
    var formattedRating: String {
        guard let rating = rating else { return "No ratings" }
        return String(format: "%.1f/5", rating)
    }
    
    var formattedPriceLevel: String {
        guard let priceLevel = priceLevel else { return "Price not available" }
        return String(repeating: "$", count: priceLevel)
    }
}

/**
 Review for a place.
 */
struct PlaceReview {
    let authorName: String
    let rating: Int
    let text: String
    let time: Date
}

/**
 Photo information for a place.
 */
struct PlacePhoto {
    let reference: String
    let width: Int
    let height: Int
}

// MARK: - API Response Models

/**
 Response from the Places API Nearby Search.
 */
struct PlacesResponse: Decodable {
    let results: [PlaceResult]
    let status: String
}

/**
 Result from the Places API Nearby Search.
 */
struct PlaceResult: Decodable {
    let placeId: String
    let name: String
    let vicinity: String
    let geometry: Geometry
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let photos: [PhotoResult]?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case geometry
        case types
        case rating
        case userRatingsTotal = "user_ratings_total"
        case photos
    }
}

/**
 Geometry information for a place.
 */
struct Geometry: Decodable {
    let location: GeometryLocation
}

/**
 Location coordinates.
 */
struct GeometryLocation: Decodable {
    let lat: Double
    let lng: Double
}

/**
 Photo information from the API.
 */
struct PhotoResult: Decodable {
    let photoReference: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case width
        case height
    }
}

/**
 Response from the Places API Place Details.
 */
struct PlaceDetailsResponse: Decodable {
    let result: PlaceDetailResult
    let status: String
}

/**
 Detailed result from the Places API Place Details.
 */
struct PlaceDetailResult: Decodable {
    let name: String
    let formattedAddress: String?
    let formattedPhoneNumber: String?
    let website: String?
    let openingHours: OpeningHours?
    let rating: Double?
    let reviews: [ReviewResult]?
    let priceLevel: Int?
    let photos: [PhotoResult]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case website
        case openingHours = "opening_hours"
        case rating
        case reviews
        case priceLevel = "price_level"
        case photos
    }
}

/**
 Opening hours information.
 */
struct OpeningHours: Decodable {
    let openNow: Bool?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case weekdayText = "weekday_text"
    }
}

/**
 Review information from the API.
 */
struct ReviewResult: Decodable {
    let authorName: String
    let rating: Int
    let text: String
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating
        case text
        case time
    }
}
