import Foundation
import FirebaseFirestoreSwift
import CoreLocation

struct Activity: Identifiable, Codable {
    // Using DocumentID for Firestore integration
    @DocumentID var id: String?
    
    // Core properties
    var name: String
    var description: String
    var type: ActivityType
    
    // Using the improved StoredOnHeap wrapper to prevent stack overflow
    @StoredOnHeap var location: Location
    
    // Optional properties
    var website: String?
    var phoneNumber: String?
    
    // Collections that benefit from heap storage
    @StoredOnHeap var photos: [String]?
    @StoredOnHeap var tags: [String]?
    
    // Additional properties
    var category: String?
    var rating: Double?
    var reviewCount: Int?
    var isFeatured: Bool
    var createdAt: Date
    var updatedAt: Date

    // Fixed CodingKeys to ensure consistency
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case type
        case location
        case website
        case phoneNumber
        case photos
        case tags
        case category
        case rating
        case reviewCount
        case isFeatured
        case createdAt
        case updatedAt
    }

    // Minimal initializer with required fields only
    init(id: String? = nil, name: String, description: String, type: ActivityType, location: Location) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self._location = StoredOnHeap(wrappedValue: location)
        self.website = nil
        self.phoneNumber = nil
        self._photos = StoredOnHeap(wrappedValue: nil)
        self._tags = StoredOnHeap(wrappedValue: nil)
        self.category = nil
        self.rating = nil
        self.reviewCount = nil
        self.isFeatured = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Full initializer with all properties
    init(id: String? = nil, name: String, description: String, type: ActivityType, location: Location,
         website: String? = nil, phoneNumber: String? = nil, photos: [String]? = nil,
         tags: [String]? = nil, category: String? = nil, rating: Double? = nil, reviewCount: Int? = nil,
         isFeatured: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {

        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self._location = StoredOnHeap(wrappedValue: location)
        self.website = website
        self.phoneNumber = phoneNumber
        self._photos = StoredOnHeap(wrappedValue: photos)
        self._tags = StoredOnHeap(wrappedValue: tags)
        self.category = category
        self.rating = rating
        self.reviewCount = reviewCount
        self.isFeatured = isFeatured
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder implementation with enhanced safety
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID safely
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode required fields with safe fallbacks
        // Using `try?` to prevent crashes from unexpected types
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
        } else if let nameNumber = try? container.decode(Double.self, forKey: .name) {
            // Handle unexpected number type for a string field
            name = String(nameNumber)
        } else {
            // Provide a default to avoid crash
            name = "Unnamed Activity"
        }
        
        // Safe description decoding
        if let descString = try? container.decode(String.self, forKey: .description) {
            description = descString
        } else {
            description = ""
        }

        // Decode type safely
        if let typeString = try? container.decode(String.self, forKey: .type) {
            type = ActivityType(rawValue: typeString) ?? .other
        } else {
            type = .other
        }

        // Decode location with error handling
        do {
            let decodedLocation = try container.decode(Location.self, forKey: .location)
            _location = StoredOnHeap(wrappedValue: decodedLocation)
        } catch {
            // Default location if decoding fails
            _location = StoredOnHeap(wrappedValue: Location(name: "Unknown", address: "Unknown", latitude: 0, longitude: 0))
        }

        // Decode optional string fields
        website = try? container.decodeIfPresent(String.self, forKey: .website)
        phoneNumber = try? container.decodeIfPresent(String.self, forKey: .phoneNumber)
        
        // Decode collections
        let decodedPhotos = try? container.decodeIfPresent([String].self, forKey: .photos)
        _photos = StoredOnHeap(wrappedValue: decodedPhotos)
        
        let decodedTags = try? container.decodeIfPresent([String].self, forKey: .tags)
        _tags = StoredOnHeap(wrappedValue: decodedTags)
        
        // Decode other optional fields
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        
        // Carefully decode numerical values with fallbacks
        if let ratingDouble = try? container.decode(Double.self, forKey: .rating) {
            rating = ratingDouble
        } else if let ratingInt = try? container.decode(Int.self, forKey: .rating) {
            rating = Double(ratingInt)
        } else if let ratingString = try? container.decode(String.self, forKey: .rating),
                  let parsedRating = Double(ratingString) {
            rating = parsedRating
        } else {
            rating = nil
        }
        
        if let countInt = try? container.decode(Int.self, forKey: .reviewCount) {
            reviewCount = countInt
        } else if let countDouble = try? container.decode(Double.self, forKey: .reviewCount) {
            reviewCount = Int(countDouble)
        } else if let countString = try? container.decode(String.self, forKey: .reviewCount),
                  let parsedCount = Int(countString) {
            reviewCount = parsedCount
        } else {
            reviewCount = nil
        }

        // Decode boolean with fallback
        if let featuredBool = try? container.decode(Bool.self, forKey: .isFeatured) {
            isFeatured = featuredBool
        } else if let featuredInt = try? container.decode(Int.self, forKey: .isFeatured) {
            isFeatured = featuredInt != 0
        } else if let featuredString = try? container.decode(String.self, forKey: .isFeatured) {
            isFeatured = featuredString.lowercased() == "true" || featuredString == "1"
        } else {
            isFeatured = false
        }

        // Decode dates with fallbacks
        if let timestamp = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = timestamp
        } else {
            createdAt = Date()
        }
        
        if let timestamp = try? container.decode(Date.self, forKey: .updatedAt) {
            updatedAt = timestamp
        } else {
            updatedAt = Date()
        }
    }

    // Explicit encode method for complete control over encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode optional ID
        try container.encodeIfPresent(id, forKey: .id)

        // Encode required fields
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(location, forKey: .location)

        // Encode optional fields
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(photos, forKey: .photos)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(reviewCount, forKey: .reviewCount)

        // Encode other fields
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// ActivityType is now defined in ActivityType.swift

// Extension on Activity for convenient operations
extension Activity {
    // Helper to get formatted rating string
    var ratingFormatted: String {
        guard let rating = rating else { return "No ratings" }
        return String(format: "%.1f", rating)
    }
    
    // Helper for formatted address
    var formattedAddress: String {
        return location.address.isEmpty ? "No address available" : location.address
    }
}
