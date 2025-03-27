import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import CoreLocation

public enum EventCategory: String, Codable, CaseIterable {
    case holiday = "holiday"
    case fundraiser = "fundraiser"
    case workshop = "workshop"
    case playdate = "playdate"
    case sports = "sports"
    case arts = "arts"
    case education = "education"
    case outdoors = "outdoors"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .holiday: return "Holiday Celebration"
        case .fundraiser: return "Fundraiser"
        case .workshop: return "Workshop"
        case .playdate: return "Playdate"
        case .sports: return "Sports"
        case .arts: return "Arts & Crafts"
        case .education: return "Educational"
        case .outdoors: return "Outdoor Activity"
        case .other: return "Other"
        }
    }
    
    public var icon: String {
        switch self {
        case .holiday: return "gift"
        case .fundraiser: return "dollarsign.circle"
        case .workshop: return "hammer"
        case .playdate: return "person.3"
        case .sports: return "sportscourt"
        case .arts: return "paintpalette"
        case .education: return "book"
        case .outdoors: return "leaf"
        case .other: return "star"
        }
    }
}

public enum EventRecurrencePattern: String, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

public struct CommunityEvent: Identifiable, Codable {
    @DocumentID public var id: String?
    public var title: String
    public var description: String
    public var category: EventCategory
    public var startDate: Date
    public var endDate: Date
    var location: Location?
    public var address: String?
    public var isVirtual: Bool
    public var virtualMeetingURL: String?
    public var coverImageURL: String?
    
    // Capacity and attendance
    public var maxCapacity: Int?
    @StoredOnHeap var attendeeIDs: [String]
    @StoredOnHeap var waitlistIDs: [String]
    
    // Organization
    public var organizerID: String
    public var organizerName: String?
    public var sponsoringOrganization: String?
    
    // Visibility
    public var isPublic: Bool
    @StoredOnHeap var invitedGroupIDs: [String]
    
    // Recurrence
    public var recurrencePattern: EventRecurrencePattern
    public var recurrenceEndDate: Date?
    public var parentEventID: String?
    
    // Additional details
    public var cost: Double?
    public var isFree: Bool
    public var ageMin: Int?
    public var ageMax: Int?
    @StoredOnHeap var tags: [String]
    
    // Timestamps
    public var createdAt: Date
    public var updatedAt: Date?
    
    // Custom initializer
    init(id: String? = nil,
         title: String,
         description: String,
         category: EventCategory = .other,
         startDate: Date,
         endDate: Date,
         location: Location? = nil,
         address: String? = nil,
         isVirtual: Bool = false,
         virtualMeetingURL: String? = nil,
         coverImageURL: String? = nil,
         maxCapacity: Int? = nil,
         attendeeIDs: [String] = [],
         waitlistIDs: [String] = [],
         organizerID: String,
         organizerName: String? = nil,
         sponsoringOrganization: String? = nil,
         isPublic: Bool = true,
         invitedGroupIDs: [String] = [],
         recurrencePattern: EventRecurrencePattern = .none,
         recurrenceEndDate: Date? = nil,
         parentEventID: String? = nil,
         cost: Double? = nil,
         isFree: Bool = true,
         ageMin: Int? = nil,
         ageMax: Int? = nil,
         tags: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date? = nil) {
        
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.address = address
        self.isVirtual = isVirtual
        self.virtualMeetingURL = virtualMeetingURL
        self.coverImageURL = coverImageURL
        self.maxCapacity = maxCapacity
        self.attendeeIDs = attendeeIDs
        self.waitlistIDs = waitlistIDs
        self.organizerID = organizerID
        self.organizerName = organizerName
        self.sponsoringOrganization = sponsoringOrganization
        self.isPublic = isPublic
        self.invitedGroupIDs = invitedGroupIDs
        self.recurrencePattern = recurrencePattern
        self.recurrenceEndDate = recurrenceEndDate
        self.parentEventID = parentEventID
        self.cost = cost
        self.isFree = isFree
        self.ageMin = ageMin
        self.ageMax = ageMax
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case startDate
        case endDate
        case location
        case address
        case isVirtual
        case virtualMeetingURL
        case coverImageURL
        case maxCapacity
        case attendeeIDs
        case waitlistIDs
        case organizerID
        case organizerName
        case sponsoringOrganization
        case isPublic
        case invitedGroupIDs
        case recurrencePattern
        case recurrenceEndDate
        case parentEventID
        case cost
        case isFree
        case ageMin
        case ageMax
        case tags
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
        organizerID = try container.decode(String.self, forKey: .organizerID)
        
        // Decode optional fields
        address = try container.decodeIfPresent(String.self, forKey: .address)
        virtualMeetingURL = try container.decodeIfPresent(String.self, forKey: .virtualMeetingURL)
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        organizerName = try container.decodeIfPresent(String.self, forKey: .organizerName)
        sponsoringOrganization = try container.decodeIfPresent(String.self, forKey: .sponsoringOrganization)
        parentEventID = try container.decodeIfPresent(String.self, forKey: .parentEventID)
        
        // Decode enums
        if let categoryString = try container.decodeIfPresent(String.self, forKey: .category),
           let decodedCategory = EventCategory(rawValue: categoryString) {
            category = decodedCategory
        } else {
            category = .other
        }
        
        if let recurrenceString = try container.decodeIfPresent(String.self, forKey: .recurrencePattern),
           let decodedRecurrence = EventRecurrencePattern(rawValue: recurrenceString) {
            recurrencePattern = decodedRecurrence
        } else {
            recurrencePattern = .none
        }
        
        // Decode dates
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
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .recurrenceEndDate) {
            recurrenceEndDate = timestamp.dateValue()
        } else {
            recurrenceEndDate = try container.decodeIfPresent(Date.self, forKey: .recurrenceEndDate)
        }
        
        // Decode numeric fields
        maxCapacity = try container.decodeIfPresent(Int.self, forKey: .maxCapacity)
        cost = try container.decodeIfPresent(Double.self, forKey: .cost)
        ageMin = try container.decodeIfPresent(Int.self, forKey: .ageMin)
        ageMax = try container.decodeIfPresent(Int.self, forKey: .ageMax)
        
        // Decode boolean fields
        isVirtual = try container.decodeIfPresent(Bool.self, forKey: .isVirtual) ?? false
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        isFree = try container.decodeIfPresent(Bool.self, forKey: .isFree) ?? true
        
        // Decode arrays
        attendeeIDs = try container.decodeIfPresent([String].self, forKey: .attendeeIDs) ?? []
        waitlistIDs = try container.decodeIfPresent([String].self, forKey: .waitlistIDs) ?? []
        invitedGroupIDs = try container.decodeIfPresent([String].self, forKey: .invitedGroupIDs) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // Decode complex objects
        location = try container.decodeIfPresent(Location.self, forKey: .location)
    }
    
    // Custom encoder implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(Timestamp(date: startDate), forKey: .startDate)
        try container.encode(Timestamp(date: endDate), forKey: .endDate)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encode(isVirtual, forKey: .isVirtual)
        try container.encodeIfPresent(virtualMeetingURL, forKey: .virtualMeetingURL)
        try container.encodeIfPresent(coverImageURL, forKey: .coverImageURL)
        try container.encodeIfPresent(maxCapacity, forKey: .maxCapacity)
        try container.encode(attendeeIDs, forKey: .attendeeIDs)
        try container.encode(waitlistIDs, forKey: .waitlistIDs)
        try container.encode(organizerID, forKey: .organizerID)
        try container.encodeIfPresent(organizerName, forKey: .organizerName)
        try container.encodeIfPresent(sponsoringOrganization, forKey: .sponsoringOrganization)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(invitedGroupIDs, forKey: .invitedGroupIDs)
        try container.encode(recurrencePattern.rawValue, forKey: .recurrencePattern)
        
        if let recurrenceEndDateValue = recurrenceEndDate {
            try container.encode(Timestamp(date: recurrenceEndDateValue), forKey: .recurrenceEndDate)
        }
        
        try container.encodeIfPresent(parentEventID, forKey: .parentEventID)
        try container.encodeIfPresent(cost, forKey: .cost)
        try container.encode(isFree, forKey: .isFree)
        try container.encodeIfPresent(ageMin, forKey: .ageMin)
        try container.encodeIfPresent(ageMax, forKey: .ageMax)
        try container.encode(tags, forKey: .tags)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        
        if let updatedAtValue = updatedAt {
            try container.encode(Timestamp(date: updatedAtValue), forKey: .updatedAt)
        }
    }
    
    // Helper method to check if event is at capacity
    public var isAtCapacity: Bool {
        if let capacity = maxCapacity {
            return attendeeIDs.count >= capacity
        }
        return false
    }
    
    // Helper method to check if event is happening now
    public var isHappeningNow: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    // Helper method to check if event is in the past
    public var isPast: Bool {
        return Date() > endDate
    }
    
    // Helper method to check if event is in the future
    public var isFuture: Bool {
        return Date() < startDate
    }
}
