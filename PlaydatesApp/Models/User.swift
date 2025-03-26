import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

public struct User: Identifiable, Codable {
    @DocumentID public var id: String?
    public var name: String
    public var email: String
    public var profileImageURL: String?
    public var bio: String?
    // Use StoredOnHeap for potentially large arrays and collections
    @StoredOnHeap public var children: [PlaydateChild]?
    @StoredOnHeap public var friendIDs: [String]?
    @StoredOnHeap public var friendRequestIDs: [String]?
    public var createdAt: Date
    public var lastActive: Date

    // Custom initializer to ensure all properties are properly initialized
    public init(id: String?, name: String, email: String, profileImageURL: String? = nil, bio: String? = nil,
         children: [PlaydateChild]? = nil, friendIDs: [String]? = nil, friendRequestIDs: [String]? = nil,
         createdAt: Date, lastActive: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.children = children
        self.friendIDs = friendIDs
        self.friendRequestIDs = friendRequestIDs
        self.createdAt = createdAt
        self.lastActive = lastActive
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case profileImageURL
        case bio
        case children
        case friendIDs
        case friendRequestIDs
        case createdAt
        case lastActive
    }

    // Custom decoder implementation to handle type mismatches
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode strings with fallbacks
        name = try Self.decodeString(from: container, forKey: .name) ?? "User"
        email = try Self.decodeString(from: container, forKey: .email) ?? ""
        profileImageURL = try Self.decodeString(from: container, forKey: .profileImageURL)
        bio = try Self.decodeString(from: container, forKey: .bio)

        // Decode arrays and wrap in StoredOnHeap
        children = try container.decodeIfPresent([PlaydateChild].self, forKey: .children)
        
        let rawFriendIDs = try Self.decodeStringArray(from: container, forKey: .friendIDs)
        friendIDs = rawFriendIDs
        
        let rawRequestIDs = try Self.decodeStringArray(from: container, forKey: .friendRequestIDs)
        friendRequestIDs = rawRequestIDs

        // Decode dates with fallbacks
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
    }
    
    // Custom encoder implementation to handle property wrappers
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(children, forKey: .children)
        try container.encodeIfPresent(friendIDs, forKey: .friendIDs)
        try container.encodeIfPresent(friendRequestIDs, forKey: .friendRequestIDs)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActive, forKey: .lastActive)
    }

    // Helper method to safely decode strings from various source types
    private static func decodeString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> String? {
        // Try decoding as String first
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }

        // If it's a number convert to string
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }

        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }

        if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
            return String(value)
        }

        // If key doesn't exist or has null value
        return nil
    }

    // Helper method to safely decode string arrays
    private static func decodeStringArray(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> [String]? {
        // Try decoding as [String] first
        if let values = try? container.decodeIfPresent([String].self, forKey: key) {
            return values
        }

        // Try decoding as [Int] and converting each value
        if let values = try? container.decodeIfPresent([Int].self, forKey: key) {
            return values.map { String($0) }
        }

        // If the key doesn't exist or has null value
        return nil
    }
}
