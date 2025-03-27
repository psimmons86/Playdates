import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import CoreLocation

public enum ResourceType: String, Codable, CaseIterable {
    case physicalItem = "physical_item"
    case recommendation = "recommendation"
    case educationalResource = "educational_resource"
    case classifiedAd = "classified_ad"
    case carpoolOffer = "carpool_offer"
    case serviceProvider = "service_provider"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .physicalItem: return "Physical Item"
        case .recommendation: return "Recommendation"
        case .educationalResource: return "Educational Resource"
        case .classifiedAd: return "Classified Ad"
        case .carpoolOffer: return "Carpool Offer"
        case .serviceProvider: return "Service Provider"
        case .other: return "Other"
        }
    }
    
    public var icon: String {
        switch self {
        case .physicalItem: return "cube"
        case .recommendation: return "star"
        case .educationalResource: return "book"
        case .classifiedAd: return "tag"
        case .carpoolOffer: return "car"
        case .serviceProvider: return "person.fill.checkmark"
        case .other: return "square.and.pencil"
        }
    }
}

public enum ResourceAvailabilityStatus: String, Codable {
    case available = "available"
    case reserved = "reserved"
    case unavailable = "unavailable"
    case sold = "sold"
    case expired = "expired"
}

public struct SharedResource: Identifiable, Codable {
    @DocumentID public var id: String?
    public var title: String
    public var description: String
    public var resourceType: ResourceType
    public var ownerID: String
    public var ownerName: String?
    public var coverImageURL: String?
    @StoredOnHeap var additionalImageURLs: [String]?
    
    // For physical items
    public var condition: String?
    public var availabilityStatus: ResourceAvailabilityStatus
    @StoredOnHeap var reservationHistory: [ResourceReservation]?
    var location: Location?
    public var address: String?
    
    // For recommendations and service providers
    public var contactInfo: String?
    public var website: String?
    public var rating: Double?
    @StoredOnHeap var reviews: [ResourceReview]?
    
    // For classified ads
    public var price: Double?
    public var isFree: Bool
    public var isNegotiable: Bool
    
    // For carpool offers
    var startLocation: Location?
    var endLocation: Location?
    public var startAddress: String?
    public var endAddress: String?
    public var departureTime: Date?
    public var returnTime: Date?
    public var recurrencePattern: EventRecurrencePattern?
    public var availableSeats: Int?
    
    // For educational resources
    public var fileURL: String?
    public var fileType: String?
    public var ageRangeMin: Int?
    public var ageRangeMax: Int?
    
    // Common fields
    @StoredOnHeap var tags: [String]
    public var expirationDate: Date?
    public var createdAt: Date
    public var updatedAt: Date?
    
    // Custom initializer
    init(id: String? = nil,
         title: String,
         description: String,
         resourceType: ResourceType,
         ownerID: String,
         ownerName: String? = nil,
         coverImageURL: String? = nil,
         additionalImageURLs: [String]? = nil,
         condition: String? = nil,
         availabilityStatus: ResourceAvailabilityStatus = .available,
         reservationHistory: [ResourceReservation]? = nil,
         location: Location? = nil,
         address: String? = nil,
         contactInfo: String? = nil,
         website: String? = nil,
         rating: Double? = nil,
         reviews: [ResourceReview]? = nil,
         price: Double? = nil,
         isFree: Bool = false,
         isNegotiable: Bool = false,
         startLocation: Location? = nil,
         endLocation: Location? = nil,
         startAddress: String? = nil,
         endAddress: String? = nil,
         departureTime: Date? = nil,
         returnTime: Date? = nil,
         recurrencePattern: EventRecurrencePattern? = nil,
         availableSeats: Int? = nil,
         fileURL: String? = nil,
         fileType: String? = nil,
         ageRangeMin: Int? = nil,
         ageRangeMax: Int? = nil,
         tags: [String] = [],
         expirationDate: Date? = nil,
         createdAt: Date = Date(),
         updatedAt: Date? = nil) {
        
        self.id = id
        self.title = title
        self.description = description
        self.resourceType = resourceType
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.coverImageURL = coverImageURL
        self.additionalImageURLs = additionalImageURLs
        self.condition = condition
        self.availabilityStatus = availabilityStatus
        self.reservationHistory = reservationHistory
        self.location = location
        self.address = address
        self.contactInfo = contactInfo
        self.website = website
        self.rating = rating
        self.reviews = reviews
        self.price = price
        self.isFree = isFree
        self.isNegotiable = isNegotiable
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.departureTime = departureTime
        self.returnTime = returnTime
        self.recurrencePattern = recurrencePattern
        self.availableSeats = availableSeats
        self.fileURL = fileURL
        self.fileType = fileType
        self.ageRangeMin = ageRangeMin
        self.ageRangeMax = ageRangeMax
        self.tags = tags
        self.expirationDate = expirationDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case resourceType
        case ownerID
        case ownerName
        case coverImageURL
        case additionalImageURLs
        case condition
        case availabilityStatus
        case reservationHistory
        case location
        case address
        case contactInfo
        case website
        case rating
        case reviews
        case price
        case isFree
        case isNegotiable
        case startLocation
        case endLocation
        case startAddress
        case endAddress
        case departureTime
        case returnTime
        case recurrencePattern
        case availableSeats
        case fileURL
        case fileType
        case ageRangeMin
        case ageRangeMax
        case tags
        case expirationDate
        case createdAt
        case updatedAt
    }
    
    // Custom decoder implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Decode required fields
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        ownerID = try container.decode(String.self, forKey: .ownerID)
        
        // Decode enums
        if let typeString = try container.decodeIfPresent(String.self, forKey: .resourceType),
           let decodedType = ResourceType(rawValue: typeString) {
            resourceType = decodedType
        } else {
            resourceType = .other
        }
        
        if let statusString = try container.decodeIfPresent(String.self, forKey: .availabilityStatus),
           let decodedStatus = ResourceAvailabilityStatus(rawValue: statusString) {
            availabilityStatus = decodedStatus
        } else {
            availabilityStatus = .available
        }
        
        if let patternString = try container.decodeIfPresent(String.self, forKey: .recurrencePattern),
           let decodedPattern = EventRecurrencePattern(rawValue: patternString) {
            recurrencePattern = decodedPattern
        } else {
            recurrencePattern = nil
        }
        
        // Decode optional fields
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        additionalImageURLs = try container.decodeIfPresent([String].self, forKey: .additionalImageURLs)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        contactInfo = try container.decodeIfPresent(String.self, forKey: .contactInfo)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        startAddress = try container.decodeIfPresent(String.self, forKey: .startAddress)
        endAddress = try container.decodeIfPresent(String.self, forKey: .endAddress)
        fileURL = try container.decodeIfPresent(String.self, forKey: .fileURL)
        fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
        
        // Decode numeric fields
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        availableSeats = try container.decodeIfPresent(Int.self, forKey: .availableSeats)
        ageRangeMin = try container.decodeIfPresent(Int.self, forKey: .ageRangeMin)
        ageRangeMax = try container.decodeIfPresent(Int.self, forKey: .ageRangeMax)
        
        // Decode boolean fields
        isFree = try container.decodeIfPresent(Bool.self, forKey: .isFree) ?? false
        isNegotiable = try container.decodeIfPresent(Bool.self, forKey: .isNegotiable) ?? false
        
        // Decode dates
        if let timestamp = try? container.decode(Timestamp.self, forKey: .departureTime) {
            departureTime = timestamp.dateValue()
        } else {
            departureTime = try container.decodeIfPresent(Date.self, forKey: .departureTime)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .returnTime) {
            returnTime = timestamp.dateValue()
        } else {
            returnTime = try container.decodeIfPresent(Date.self, forKey: .returnTime)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .expirationDate) {
            expirationDate = timestamp.dateValue()
        } else {
            expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        }
        
        // Decode arrays
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // Decode complex objects
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        startLocation = try container.decodeIfPresent(Location.self, forKey: .startLocation)
        endLocation = try container.decodeIfPresent(Location.self, forKey: .endLocation)
        reservationHistory = try container.decodeIfPresent([ResourceReservation].self, forKey: .reservationHistory)
        reviews = try container.decodeIfPresent([ResourceReview].self, forKey: .reviews)
    }
    
    // Custom encoder implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(resourceType.rawValue, forKey: .resourceType)
        try container.encode(ownerID, forKey: .ownerID)
        try container.encodeIfPresent(ownerName, forKey: .ownerName)
        try container.encodeIfPresent(coverImageURL, forKey: .coverImageURL)
        try container.encodeIfPresent(additionalImageURLs, forKey: .additionalImageURLs)
        try container.encodeIfPresent(condition, forKey: .condition)
        try container.encode(availabilityStatus.rawValue, forKey: .availabilityStatus)
        try container.encodeIfPresent(reservationHistory, forKey: .reservationHistory)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(contactInfo, forKey: .contactInfo)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(isFree, forKey: .isFree)
        try container.encode(isNegotiable, forKey: .isNegotiable)
        try container.encodeIfPresent(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(endLocation, forKey: .endLocation)
        try container.encodeIfPresent(startAddress, forKey: .startAddress)
        try container.encodeIfPresent(endAddress, forKey: .endAddress)
        
        if let departureTimeValue = departureTime {
            try container.encode(Timestamp(date: departureTimeValue), forKey: .departureTime)
        }
        
        if let returnTimeValue = returnTime {
            try container.encode(Timestamp(date: returnTimeValue), forKey: .returnTime)
        }
        
        if let recurrencePatternValue = recurrencePattern {
            try container.encode(recurrencePatternValue.rawValue, forKey: .recurrencePattern)
        }
        
        try container.encodeIfPresent(availableSeats, forKey: .availableSeats)
        try container.encodeIfPresent(fileURL, forKey: .fileURL)
        try container.encodeIfPresent(fileType, forKey: .fileType)
        try container.encodeIfPresent(ageRangeMin, forKey: .ageRangeMin)
        try container.encodeIfPresent(ageRangeMax, forKey: .ageRangeMax)
        try container.encode(tags, forKey: .tags)
        
        if let expirationDateValue = expirationDate {
            try container.encode(Timestamp(date: expirationDateValue), forKey: .expirationDate)
        }
        
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        
        if let updatedAtValue = updatedAt {
            try container.encode(Timestamp(date: updatedAtValue), forKey: .updatedAt)
        }
    }
    
    // Helper method to check if resource is expired
    public var isExpired: Bool {
        if let expirationDate = expirationDate {
            return Date() > expirationDate
        }
        return false
    }
    
    // Helper method to check if resource is available
    public var isAvailable: Bool {
        return availabilityStatus == .available && !isExpired
    }
}

// Resource reservation model
public struct ResourceReservation: Codable, Identifiable {
    public var id: String
    public var userID: String
    public var userName: String?
    public var startDate: Date
    public var endDate: Date
    public var status: String // "pending", "confirmed", "completed", "cancelled"
    public var notes: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString,
                userID: String,
                userName: String? = nil,
                startDate: Date,
                endDate: Date,
                status: String = "pending",
                notes: String? = nil,
                createdAt: Date = Date()) {
        
        self.id = id
        self.userID = userID
        self.userName = userName
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case userName
        case startDate
        case endDate
        case status
        case notes
        case createdAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        status = try container.decode(String.self, forKey: .status)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .startDate) {
            startDate = timestamp.dateValue()
        } else {
            startDate = try container.decode(Date.self, forKey: .startDate)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .endDate) {
            endDate = timestamp.dateValue()
        } else {
            endDate = try container.decode(Date.self, forKey: .endDate)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encode(Timestamp(date: startDate), forKey: .startDate)
        try container.encode(Timestamp(date: endDate), forKey: .endDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}

// Resource review model
public struct ResourceReview: Codable, Identifiable {
    public var id: String
    public var userID: String
    public var userName: String?
    public var rating: Double
    public var comment: String?
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString,
                userID: String,
                userName: String? = nil,
                rating: Double,
                comment: String? = nil,
                createdAt: Date = Date()) {
        
        self.id = id
        self.userID = userID
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case userName
        case rating
        case comment
        case createdAt
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        rating = try container.decode(Double.self, forKey: .rating)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
