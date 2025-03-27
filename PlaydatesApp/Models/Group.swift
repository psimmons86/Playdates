import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import CoreLocation

public enum GroupPrivacyType: String, Codable {
    case `public` = "public"
    case `private` = "private"
    case inviteOnly = "invite-only"
}

public enum GroupType: String, Codable {
    case neighborhood = "neighborhood"
    case ageBased = "age-based"
    case interestBased = "interest-based"
    case school = "school"
    case other = "other"
}

public struct Group: Identifiable, Codable {
    @DocumentID public var id: String?
    public var name: String
    public var description: String
    public var groupType: GroupType
    public var privacyType: GroupPrivacyType
    var location: Location?
    public var coverImageURL: String?
    
    // Search-optimized fields
    public var name_lowercase: String?
    
    // Use StoredOnHeap for potentially large arrays and collections
    @StoredOnHeap var memberIDs: [String]
    @StoredOnHeap var adminIDs: [String]
    @StoredOnHeap var moderatorIDs: [String]
    @StoredOnHeap var pendingMemberIDs: [String]
    @StoredOnHeap var tags: [String]
    
    public var createdAt: Date
    public var createdBy: String
    public var lastActive: Date
    
    // Group settings
    public var allowMemberPosts: Bool
    public var requirePostApproval: Bool
    public var allowEvents: Bool
    public var allowResourceSharing: Bool
    
    // Custom initializer to ensure all properties are properly initialized
    init(id: String? = nil, 
         name: String, 
         description: String, 
         groupType: GroupType, 
         privacyType: GroupPrivacyType = .public,
         location: Location? = nil,
         coverImageURL: String? = nil,
         memberIDs: [String] = [],
         adminIDs: [String],
         moderatorIDs: [String] = [],
         pendingMemberIDs: [String] = [],
         tags: [String] = [],
         createdAt: Date = Date(),
         createdBy: String,
         lastActive: Date = Date(),
         allowMemberPosts: Bool = true,
         requirePostApproval: Bool = false,
         allowEvents: Bool = true,
         allowResourceSharing: Bool = true) {
        
        self.id = id
        self.name = name
        self.description = description
        self.groupType = groupType
        self.privacyType = privacyType
        self.location = location
        self.coverImageURL = coverImageURL
        self.memberIDs = memberIDs
        self.adminIDs = adminIDs
        self.moderatorIDs = moderatorIDs
        self.pendingMemberIDs = pendingMemberIDs
        self.tags = tags
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.lastActive = lastActive
        self.allowMemberPosts = allowMemberPosts
        self.requirePostApproval = requirePostApproval
        self.allowEvents = allowEvents
        self.allowResourceSharing = allowResourceSharing
        
        // Set search-optimized fields
        self.name_lowercase = name.lowercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case groupType
        case privacyType
        case location
        case coverImageURL
        case name_lowercase
        case memberIDs
        case adminIDs
        case moderatorIDs
        case pendingMemberIDs
        case tags
        case createdAt
        case createdBy
        case lastActive
        case allowMemberPosts
        case requirePostApproval
        case allowEvents
        case allowResourceSharing
    }
    
    // Custom decoder implementation to handle type mismatches
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Decode strings with fallbacks
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        
        // Decode enums
        if let groupTypeString = try container.decodeIfPresent(String.self, forKey: .groupType),
           let type = GroupType(rawValue: groupTypeString) {
            groupType = type
        } else {
            groupType = .other
        }
        
        if let privacyTypeString = try container.decodeIfPresent(String.self, forKey: .privacyType),
           let privacy = GroupPrivacyType(rawValue: privacyTypeString) {
            privacyType = privacy
        } else {
            privacyType = .public
        }
        
        // Decode location
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        
        // Decode search-optimized fields or generate them if missing
        name_lowercase = try container.decodeIfPresent(String.self, forKey: .name_lowercase) ?? name.lowercased()
        
        // Decode arrays
        memberIDs = try container.decodeIfPresent([String].self, forKey: .memberIDs) ?? []
        adminIDs = try container.decodeIfPresent([String].self, forKey: .adminIDs) ?? []
        moderatorIDs = try container.decodeIfPresent([String].self, forKey: .moderatorIDs) ?? []
        pendingMemberIDs = try container.decodeIfPresent([String].self, forKey: .pendingMemberIDs) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // Decode dates with fallbacks
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActive) {
            lastActive = timestamp.dateValue()
        } else {
            lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
        }
        
        // Decode creator ID
        createdBy = try container.decode(String.self, forKey: .createdBy)
        
        // Decode boolean settings
        allowMemberPosts = try container.decodeIfPresent(Bool.self, forKey: .allowMemberPosts) ?? true
        requirePostApproval = try container.decodeIfPresent(Bool.self, forKey: .requirePostApproval) ?? false
        allowEvents = try container.decodeIfPresent(Bool.self, forKey: .allowEvents) ?? true
        allowResourceSharing = try container.decodeIfPresent(Bool.self, forKey: .allowResourceSharing) ?? true
    }
    
    // Custom encoder implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(groupType.rawValue, forKey: .groupType)
        try container.encode(privacyType.rawValue, forKey: .privacyType)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(coverImageURL, forKey: .coverImageURL)
        
        // Always ensure name_lowercase is set and encoded
        let nameLowercase = name.lowercased()
        try container.encode(nameLowercase, forKey: .name_lowercase)
        
        try container.encode(memberIDs, forKey: .memberIDs)
        try container.encode(adminIDs, forKey: .adminIDs)
        try container.encode(moderatorIDs, forKey: .moderatorIDs)
        try container.encode(pendingMemberIDs, forKey: .pendingMemberIDs)
        try container.encode(tags, forKey: .tags)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(Timestamp(date: lastActive), forKey: .lastActive)
        
        try container.encode(allowMemberPosts, forKey: .allowMemberPosts)
        try container.encode(requirePostApproval, forKey: .requirePostApproval)
        try container.encode(allowEvents, forKey: .allowEvents)
        try container.encode(allowResourceSharing, forKey: .allowResourceSharing)
    }
}
