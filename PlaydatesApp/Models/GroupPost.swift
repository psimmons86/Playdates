import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import CoreLocation

public enum PostStatus: String, Codable {
    case published = "published"
    case pending = "pending"
    case rejected = "rejected"
    case archived = "archived"
}

public struct GroupPost: Identifiable, Codable {
    @DocumentID public var id: String?
    public var groupID: String
    public var authorID: String
    public var title: String?
    public var content: String
    public var mediaURLs: [String]?
    public var status: PostStatus
    public var isPinned: Bool
    public var createdAt: Date
    public var updatedAt: Date?
    
    // Engagement metrics
    @StoredOnHeap public var likedByIDs: [String]
    @StoredOnHeap public var commentIDs: [String]
    @StoredOnHeap public var tags: [String]
    
    // For polls
    public var isPoll: Bool
    @StoredOnHeap public var pollOptions: [PollOption]?
    public var pollEndsAt: Date?
    
    // For events
    public var isEvent: Bool
    public var eventDetails: CommunityEvent?
    
    // For resource sharing
    public var isResource: Bool
    public var resourceDetails: SharedResource?
    
    // Custom initializer
    public init(id: String? = nil,
                groupID: String,
                authorID: String,
                title: String? = nil,
                content: String,
                mediaURLs: [String]? = nil,
                status: PostStatus = .published,
                isPinned: Bool = false,
                createdAt: Date = Date(),
                updatedAt: Date? = nil,
                likedByIDs: [String] = [],
                commentIDs: [String] = [],
                tags: [String] = [],
                isPoll: Bool = false,
                pollOptions: [PollOption]? = nil,
                pollEndsAt: Date? = nil,
                isEvent: Bool = false,
                eventDetails: CommunityEvent? = nil,
                isResource: Bool = false,
                resourceDetails: SharedResource? = nil) {
        
        self.id = id
        self.groupID = groupID
        self.authorID = authorID
        self.title = title
        self.content = content
        self.mediaURLs = mediaURLs
        self.status = status
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.likedByIDs = likedByIDs
        self.commentIDs = commentIDs
        self.tags = tags
        self.isPoll = isPoll
        self.pollOptions = pollOptions
        self.pollEndsAt = pollEndsAt
        self.isEvent = isEvent
        self.eventDetails = eventDetails
        self.isResource = isResource
        self.resourceDetails = resourceDetails
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupID
        case authorID
        case title
        case content
        case mediaURLs
        case status
        case isPinned
        case createdAt
        case updatedAt
        case likedByIDs
        case commentIDs
        case tags
        case isPoll
        case pollOptions
        case pollEndsAt
        case isEvent
        case eventDetails
        case isResource
        case resourceDetails
    }
    
    // Custom decoder implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Decode required fields
        groupID = try container.decode(String.self, forKey: .groupID)
        authorID = try container.decode(String.self, forKey: .authorID)
        content = try container.decode(String.self, forKey: .content)
        
        // Decode optional fields
        title = try container.decodeIfPresent(String.self, forKey: .title)
        mediaURLs = try container.decodeIfPresent([String].self, forKey: .mediaURLs)
        
        // Decode status enum
        if let statusString = try container.decodeIfPresent(String.self, forKey: .status),
           let decodedStatus = PostStatus(rawValue: statusString) {
            status = decodedStatus
        } else {
            status = .published
        }
        
        // Decode boolean fields
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isPoll = try container.decodeIfPresent(Bool.self, forKey: .isPoll) ?? false
        isEvent = try container.decodeIfPresent(Bool.self, forKey: .isEvent) ?? false
        isResource = try container.decodeIfPresent(Bool.self, forKey: .isResource) ?? false
        
        // Decode dates
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
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .pollEndsAt) {
            pollEndsAt = timestamp.dateValue()
        } else {
            pollEndsAt = try container.decodeIfPresent(Date.self, forKey: .pollEndsAt)
        }
        
        // Decode arrays
        likedByIDs = try container.decodeIfPresent([String].self, forKey: .likedByIDs) ?? []
        commentIDs = try container.decodeIfPresent([String].self, forKey: .commentIDs) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // Decode complex objects
        pollOptions = try container.decodeIfPresent([PollOption].self, forKey: .pollOptions)
        eventDetails = try container.decodeIfPresent(CommunityEvent.self, forKey: .eventDetails)
        resourceDetails = try container.decodeIfPresent(SharedResource.self, forKey: .resourceDetails)
    }
    
    // Custom encoder implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(groupID, forKey: .groupID)
        try container.encode(authorID, forKey: .authorID)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(mediaURLs, forKey: .mediaURLs)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        
        if let updatedAtValue = updatedAt {
            try container.encode(Timestamp(date: updatedAtValue), forKey: .updatedAt)
        }
        
        try container.encode(likedByIDs, forKey: .likedByIDs)
        try container.encode(commentIDs, forKey: .commentIDs)
        try container.encode(tags, forKey: .tags)
        
        try container.encode(isPoll, forKey: .isPoll)
        try container.encodeIfPresent(pollOptions, forKey: .pollOptions)
        
        if let pollEndsAtValue = pollEndsAt {
            try container.encode(Timestamp(date: pollEndsAtValue), forKey: .pollEndsAt)
        }
        
        try container.encode(isEvent, forKey: .isEvent)
        try container.encodeIfPresent(eventDetails, forKey: .eventDetails)
        
        try container.encode(isResource, forKey: .isResource)
        try container.encodeIfPresent(resourceDetails, forKey: .resourceDetails)
    }
}

// Poll option model
public struct PollOption: Codable, Identifiable {
    public var id: String
    public var text: String
    @StoredOnHeap public var votedByIDs: [String]
    
    public init(id: String = UUID().uuidString, text: String, votedByIDs: [String] = []) {
        self.id = id
        self.text = text
        self.votedByIDs = votedByIDs
    }
}
