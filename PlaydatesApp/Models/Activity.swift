import Foundation
import CoreLocation
import FirebaseFirestore // Import needed for GeoPoint

import FirebaseFirestoreSwift // Needed for @DocumentID

struct Activity: Identifiable, Codable {
    // Using DocumentID for Firestore integration
    @DocumentID var id: String? // Added @DocumentID wrapper
    
    // Core properties
    var name: String
    var description: String? // Made optional
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
    var photoReference: String? // Added for Google Places photos
    var features: [String]? // Added features
    var isPublic: Bool
    var isFeatured: Bool
    var editorialSummary: String? // Added for Google Places summary
    var openingHours: [String]? // Added for Google Places hours
    var createdAt: Date
    var updatedAt: Date

    // Fixed CodingKeys to ensure consistency
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description // Keep in CodingKeys even if optional
        case type
        case location
        case website
        case phoneNumber
        case photos
        case tags
        case category
        case rating
        case reviewCount
        case photoReference // Added for Google Places photos
        case features // Added features
        case isPublic
        case isFeatured
        case editorialSummary // Added coding key
        case openingHours // Added coding key
        case createdAt
        case updatedAt
    }

    // Minimal initializer with required fields only (description is now optional)
    init(id: String? = nil, name: String, description: String? = nil, type: ActivityType, location: Location) {
        self.id = id
        self.name = name
        self.description = description // Assign optional value
        self.type = type
        self._location = StoredOnHeap(wrappedValue: location)
        self.website = nil
        self.phoneNumber = nil
        self._photos = StoredOnHeap(wrappedValue: nil)
        self._tags = StoredOnHeap(wrappedValue: nil)
        self.category = nil
        self.rating = nil
        self.reviewCount = nil
        self.photoReference = nil // Added for Google Places photos
        self.features = nil // Added features
        self.isPublic = true
        self.isFeatured = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Full initializer with all properties (description is optional)
    init(id: String? = nil, name: String, description: String? = nil, type: ActivityType, location: Location,
         website: String? = nil, phoneNumber: String? = nil, photos: [String]? = nil,
         tags: [String]? = nil, category: String? = nil, rating: Double? = nil, reviewCount: Int? = nil,
         photoReference: String? = nil, // Added for Google Places photos
         features: [String]? = nil, // Added features
         isPublic: Bool = true, isFeatured: Bool = false,
         editorialSummary: String? = nil, openingHours: [String]? = nil, // Added to initializer
         createdAt: Date = Date(), updatedAt: Date = Date()) {

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
        self.photoReference = photoReference // Added for Google Places photos
        self.features = features // Added features
        self.isPublic = isPublic
        self.isFeatured = isFeatured
        self.editorialSummary = editorialSummary // Initialize new property
        self.openingHours = openingHours // Initialize new property
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder implementation with enhanced safety
    init(from decoder: Decoder) throws {
        // Initialize ALL properties with default/nil values first
        self.id = nil
        self.name = "Unnamed Activity" // Default for required String
        self.description = nil
        self.type = .other // Default for required Enum
        self._location = StoredOnHeap(wrappedValue: Location(name: "Pending Decode", address: "", latitude: 0, longitude: 0)) // Initial default
        self.website = nil
        self.phoneNumber = nil
        self._photos = StoredOnHeap(wrappedValue: nil)
        self._tags = StoredOnHeap(wrappedValue: nil)
        self.category = nil
        self.rating = nil
        self.reviewCount = nil
        self.photoReference = nil
        self.features = nil
        self.isPublic = true // Default
        self.isFeatured = false // Default
        self.editorialSummary = nil
        self.openingHours = nil
        self.createdAt = Date() // Default
        self.updatedAt = Date() // Default

        // Now, decode values from the container
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID safely (overwrites initial nil)
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode required fields with safe fallbacks (overwrites initial defaults)
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
        } else if let nameNumber = try? container.decode(Double.self, forKey: .name) {
            // Handle unexpected number type for a string field
            name = String(nameNumber)
        } else {
            // Provide a default to avoid crash
            name = "Unnamed Activity"
        }
        
        // Safe description decoding (optional)
        description = try? container.decodeIfPresent(String.self, forKey: .description)

        // Decode type safely
        if let typeString = try? container.decode(String.self, forKey: .type) {
            type = ActivityType(rawValue: typeString) ?? .other
        } else {
            type = .other // Overwrites initial default
        }

        // Now, attempt to decode the actual location, overwriting the initial default
        do {
            // Attempt 1: Decode as GeoPoint (common Firestore type)
            let geoPoint = try container.decode(GeoPoint.self, forKey: .location)
            // If successful, create Location from GeoPoint coordinates. Name/Address might be missing.
            // Removed print statement that accessed 'id' before '_location' was initialized in this path.
            _location = StoredOnHeap(wrappedValue: Location(name: "From GeoPoint", address: "Address unavailable", latitude: geoPoint.latitude, longitude: geoPoint.longitude))
        } catch {
            // If GeoPoint decoding fails, try decoding as the nested Location struct (map)
            do {
                // Attempt 2: Decode as nested Location struct
                let decodedLocation = try container.decode(Location.self, forKey: .location)
                // Removed print statement that accessed 'id' before '_location' was initialized in this path.
                _location = StoredOnHeap(wrappedValue: decodedLocation)
            } catch let nestedError {
                // Attempt 3: Assign final default if both attempts fail (overwrites the initial default)
                _location = StoredOnHeap(wrappedValue: Location(name: "Unknown (Decode Error)", address: "Unknown", latitude: 0, longitude: 0))
                // No print needed here
            }
        }

        // Decode optional string fields (overwrites initial nils)
        website = try? container.decodeIfPresent(String.self, forKey: .website)
        phoneNumber = try? container.decodeIfPresent(String.self, forKey: .phoneNumber)
        
        // Decode collections
        let decodedPhotos = try? container.decodeIfPresent([String].self, forKey: .photos)
        _photos = StoredOnHeap(wrappedValue: decodedPhotos)
        
        let decodedTags = try? container.decodeIfPresent([String].self, forKey: .tags)
        _tags = StoredOnHeap(wrappedValue: decodedTags)
        
        // Decode other optional fields
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        photoReference = try? container.decodeIfPresent(String.self, forKey: .photoReference) // Added for Google Places photos
        features = try? container.decodeIfPresent([String].self, forKey: .features) // Added features
        editorialSummary = try? container.decodeIfPresent(String.self, forKey: .editorialSummary) // Decode new property
        openingHours = try? container.decodeIfPresent([String].self, forKey: .openingHours) // Decode new property

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

        // Decode isPublic with fallback
        if let publicBool = try? container.decode(Bool.self, forKey: .isPublic) {
            isPublic = publicBool
        } else if let publicInt = try? container.decode(Int.self, forKey: .isPublic) {
            isPublic = publicInt != 0
        } else if let publicString = try? container.decode(String.self, forKey: .isPublic) {
            isPublic = publicString.lowercased() == "true" || publicString == "1"
        } else {
            // Assign default value FIRST
            isPublic = true // Default to public
            // Removed print statement
        }

        // Decode isFeatured with fallback
        if let featuredBool = try? container.decode(Bool.self, forKey: .isFeatured) {
            isFeatured = featuredBool
        } else if let featuredInt = try? container.decode(Int.self, forKey: .isFeatured) {
            isFeatured = featuredInt != 0
        } else if let featuredString = try? container.decode(String.self, forKey: .isFeatured) {
            isFeatured = featuredString.lowercased() == "true" || featuredString == "1"
        } else {
            // Assign default value FIRST
            isFeatured = false // Default to false
            // Removed print statement
        }

        // Decode dates with robust fallbacks and explicitly named errors
        do {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        } catch let createdAtError {
            // Assign default value FIRST
            createdAt = Date() // Default to current date/time if decoding fails
            // Removed print statement
        }

        do {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        } catch let updatedAtError {
            // Assign default value FIRST
            updatedAt = Date() // Default to current date/time if decoding fails
            // Removed print statement
        }
    }

    // Explicit encode method for complete control over encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode optional ID
        try container.encodeIfPresent(id, forKey: .id)

        // Encode required fields
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description) // Encode if present
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(location, forKey: .location)

        // Encode other optional fields
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(photos, forKey: .photos)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(reviewCount, forKey: .reviewCount)
        try container.encodeIfPresent(photoReference, forKey: .photoReference) // Added for Google Places photos
        try container.encodeIfPresent(features, forKey: .features) // Added features
        try container.encodeIfPresent(editorialSummary, forKey: .editorialSummary) // Encode new property
        try container.encodeIfPresent(openingHours, forKey: .openingHours) // Encode new property

        // Encode other fields
        try container.encode(isPublic, forKey: .isPublic)
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
