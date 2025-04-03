import Foundation
import CoreLocation

// MARK: - Activity Place Models

/**
 Represents a place found through the Google Places API.
 */
struct ActivityPlace: Identifiable {
    let id: String
    let name: String
    let location: Location
    let types: [String]
    var rating: Double? // Changed from let to var
    let userRatingsTotal: Int?
    let photoReference: String?
    // Added fields to hold details fetched on demand
    var description: String?
    var website: String?
    var phoneNumber: String?
    
    var formattedRating: String {
        guard let rating = rating else { return "No ratings" }
        return String(format: "%.1f/5", rating)
    }
    
    // Explicit initializer to avoid ambiguity
    // Note: The initializer parameter 'rating' remains 'let' as it's just the initial value.
    init(id: String, name: String, location: Location, types: [String], rating: Double?, userRatingsTotal: Int?, photoReference: String?, description: String? = nil, website: String? = nil, phoneNumber: String? = nil) {
        self.id = id
        self.name = name
        self.location = location
        self.types = types
        self.rating = rating
        self.userRatingsTotal = userRatingsTotal
        self.photoReference = photoReference
        self.description = description
        self.website = website
        self.phoneNumber = phoneNumber
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
    let editorialSummary: EditorialSummary? // Added for consistency with PlaceDetailResult
    let openingHours: OpeningHours?       // Added for consistency with PlaceDetailResult
    
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
    let vicinity: String?
    let geometry: Geometry
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let photos: [PhotoResult]?
    let formattedAddress: String?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case geometry
        case types
        case rating
        case userRatingsTotal = "user_ratings_total"
        case photos
        case formattedAddress = "formatted_address"
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
    let editorialSummary: EditorialSummary? // Added editorial summary
    
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
        case editorialSummary = "editorial_summary" // Added coding key
    }
}

/**
 Editorial summary information from Place Details API.
 */
struct EditorialSummary: Decodable {
    let overview: String?
    // language field is also available if needed
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
