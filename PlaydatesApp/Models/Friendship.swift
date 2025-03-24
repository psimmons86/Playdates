import Foundation
import FirebaseFirestoreSwift

struct Friendship: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var friendID: String
    var status: FriendshipStatus
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case friendID
        case status
        case createdAt
        case updatedAt
    }

    // Custom initializer
    init(id: String? = nil, userID: String, friendID: String, status: FriendshipStatus, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userID = userID
        self.friendID = friendID
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder implementation to handle type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode userID and friendID with type safety
        userID = try Self.decodeString(from: container, forKey: .userID) ?? ""
        friendID = try Self.decodeString(from: container, forKey: .friendID) ?? ""

        // Decode status
        if let statusString = try? container.decode(String.self, forKey: .status),
           let decodedStatus = FriendshipStatus(rawValue: statusString) {
            status = decodedStatus
        } else if let statusInt = try? container.decode(Int.self, forKey: .status) {
            // Handle if stored as an integer index
            switch statusInt {
            case 0: status = .pending
            case 1: status = .accepted
            case 2: status = .declined
            case 3: status = .blocked
            default: status = .pending
            }
        } else {
            // Default if can't decode
            status = .pending
        }

        // Decode dates with fallbacks
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // Helper method for safe string decoding
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

        // If key doesn't exist or has null value
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

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case blocked
}

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var senderID: String
    var recipientID: String
    var message: String?
    var status: FriendRequestStatus
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case senderID
        case recipientID
        case message
        case status
        case createdAt
        case updatedAt
    }

    // Custom initializer
    init(id: String? = nil, senderID: String, recipientID: String, message: String? = nil,
         status: FriendRequestStatus, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.senderID = senderID
        self.recipientID = recipientID
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder implementation to handle type mismatches
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode senderID and recipientID with type safety
        senderID = try Self.decodeString(from: container, forKey: .senderID) ?? ""
        recipientID = try Self.decodeString(from: container, forKey: .recipientID) ?? ""

        // Decode message with type safety
        message = try Self.decodeString(from: container, forKey: .message)

        // Decode status
        if let statusString = try? container.decode(String.self, forKey: .status),
           let decodedStatus = FriendRequestStatus(rawValue: statusString) {
            status = decodedStatus
        } else if let statusInt = try? container.decode(Int.self, forKey: .status) {
            // Handle if stored as an integer index
            switch statusInt {
            case 0: status = .pending
            case 1: status = .accepted
            case 2: status = .declined
            default: status = .pending
            }
        } else {
            // Default if can't decode
            status = .pending
        }

        // Decode dates with fallbacks
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // Helper method for safe string decoding
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

        // If key doesn't exist or has null value
        return nil
    }
}

enum FriendRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}
