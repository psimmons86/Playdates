import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var profileImageURL: String?
    var bio: String?
    // Use StoredOnHeap for potentially large arrays and collections
    @StoredOnHeap var children: [Child]?
    @StoredOnHeap var friendIDs: [String]?
    @StoredOnHeap var friendRequestIDs: [String]?
    var createdAt: Date
    var lastActive: Date

    // Custom initializer to ensure all properties are properly initialized
    init(id: String?, name: String, email: String, profileImageURL: String? = nil, bio: String? = nil,
         children: [Child]? = nil, friendIDs: [String]? = nil, friendRequestIDs: [String]? = nil,
         createdAt: Date, lastActive: Date) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.bio = bio
        self._children = StoredOnHeap(wrappedValue: children)
        self._friendIDs = StoredOnHeap(wrappedValue: friendIDs)
        self._friendRequestIDs = StoredOnHeap(wrappedValue: friendRequestIDs)
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
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode strings with fallbacks
        name = try Self.decodeString(from: container, forKey: .name) ?? "User"
        email = try Self.decodeString(from: container, forKey: .email) ?? ""
        profileImageURL = try Self.decodeString(from: container, forKey: .profileImageURL)
        bio = try Self.decodeString(from: container, forKey: .bio)

        // Decode arrays and wrap in StoredOnHeap
        let rawChildren = try container.decodeIfPresent([Child].self, forKey: .children)
        _children = StoredOnHeap(wrappedValue: rawChildren)
        
        let rawFriendIDs = try Self.decodeStringArray(from: container, forKey: .friendIDs)
        _friendIDs = StoredOnHeap(wrappedValue: rawFriendIDs)
        
        let rawRequestIDs = try Self.decodeStringArray(from: container, forKey: .friendRequestIDs)
        _friendRequestIDs = StoredOnHeap(wrappedValue: rawRequestIDs)

        // Decode dates with fallbacks
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
    }
    
    // Custom encoder implementation to handle property wrappers
    func encode(to encoder: Encoder) throws {
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

// Child is also heap-stored using the StoredOnHeap wrapper when used
struct Child: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var age: Int
    @StoredOnHeap var interests: [String]?

    // Custom initializer
    init(id: String = UUID().uuidString, name: String, age: Int, interests: [String]? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self._interests = StoredOnHeap(wrappedValue: interests)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case interests
    }

    // Custom decoder implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode id with fallback
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

        // Decode name
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
        } else if let nameNumber = try? container.decode(Int.self, forKey: .name) {
            name = String(nameNumber)
        } else {
            name = "Unknown"
        }

        // Decode age
        if let ageInt = try? container.decode(Int.self, forKey: .age) {
            age = ageInt
        } else if let ageString = try? container.decode(String.self, forKey: .age), let ageValue = Int(ageString) {
            age = ageValue
        } else if let ageDouble = try? container.decode(Double.self, forKey: .age) {
            age = Int(ageDouble)
        } else {
            age = 0
        }

        // Decode interests
        let rawInterests = try? container.decodeIfPresent([String].self, forKey: .interests)
        _interests = StoredOnHeap(wrappedValue: rawInterests)
    }
    
    // Custom encoder implementation to handle property wrappers
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encodeIfPresent(interests, forKey: .interests)
    }
}
