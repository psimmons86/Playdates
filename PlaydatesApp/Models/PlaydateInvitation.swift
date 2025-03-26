import Foundation
import FirebaseFirestore

/// Model for playdate invitations between users
struct PlaydateInvitation: Identifiable, Codable {
    let id: String?
    let playdateID: String
    let senderID: String
    let recipientID: String
    let status: InvitationStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case playdateID
        case senderID
        case recipientID
        case status
        case message
        case createdAt
        case updatedAt
    }
    
    init(id: String?, playdateID: String, senderID: String, recipientID: String, status: InvitationStatus, message: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.playdateID = playdateID
        self.senderID = senderID
        self.recipientID = recipientID
        self.status = status
        self.message = message
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        playdateID = try container.decode(String.self, forKey: .playdateID)
        senderID = try container.decode(String.self, forKey: .senderID)
        recipientID = try container.decode(String.self, forKey: .recipientID)
        status = try container.decode(InvitationStatus.self, forKey: .status)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        
        // Handle Firebase Timestamp conversion
        if let createdTimestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = createdTimestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        if let updatedTimestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = updatedTimestamp.dateValue()
        } else {
            updatedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(playdateID, forKey: .playdateID)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(recipientID, forKey: .recipientID)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
}

/// Status of a playdate invitation
enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
}
