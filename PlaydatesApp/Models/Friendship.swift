import Foundation
import FirebaseFirestoreSwift

struct Friendship: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var friendID: String
    var status: Status // Changed
    var createdAt: Date
    var updatedAt: Date

    // Nested Enum for Status
    enum Status: String, Codable { // Nested and Renamed
        case pending
        case accepted
        case declined
        case blocked
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case friendID
        case status
        case createdAt
        case updatedAt
    }

    // Custom initializer
    init(id: String? = nil, userID: String, friendID: String, status: Status, createdAt: Date, updatedAt: Date) { // Changed
        self.id = id
        self.userID = userID
        self.friendID = friendID
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userID = try Self.decodeString(from: container, forKey: .userID) ?? ""
        friendID = try Self.decodeString(from: container, forKey: .friendID) ?? ""

        // Decode status using nested enum
        if let statusString = try? container.decode(String.self, forKey: .status),
           let decodedStatus = Status(rawValue: statusString) { // Changed
            status = decodedStatus
        } else if let statusInt = try? container.decode(Int.self, forKey: .status) {
            switch statusInt {
            case 0: status = .pending
            case 1: status = .accepted
            case 2: status = .declined
            case 3: status = .blocked
            default: status = .pending // Uses Friendship.Status implicitly
            }
        } else {
            status = .pending // Uses Friendship.Status implicitly
        }

        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // Custom encoder implementation (Added for Encodable conformance)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(friendID, forKey: .friendID)
        try container.encode(status.rawValue, forKey: .status) // Encode rawValue
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    // Helper method for safe string decoding
    private static func decodeString(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    // Helper function to determine if this friendship involves a specific user
    func involves(userID: String) -> Bool {
        return self.userID == userID || self.friendID == userID
    }

    // Helper function to get the other user's ID in a friendship
    func otherUserID(for userID: String) -> String? {
        if self.userID == userID {
            return self.friendID
        } else if self.friendID == userID {
            return self.userID
        }
        return nil
    }
}

// Removed the standalone enum FriendshipStatus as it's now nested
