import Foundation
import FirebaseFirestore

/// Model for chat messages between users
struct ChatMessage: Identifiable, Codable {
    let id: String
    let text: String
    let senderID: String
    let recipientID: String
    let isFromCurrentUser: Bool
    let timestamp: Date
    let imageURL: String?
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case senderID
        case recipientID
        case timestamp
        case imageURL
        case isRead
    }
    
    init(id: String, text: String, senderID: String, recipientID: String, isFromCurrentUser: Bool, timestamp: Date, imageURL: String? = nil, isRead: Bool = false) {
        self.id = id
        self.text = text
        self.senderID = senderID
        self.recipientID = recipientID
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.isRead = isRead
    }
    
    // Simplified initializer for UI display purposes
    init(id: String, text: String, isFromCurrentUser: Bool, timestamp: Date, imageURL: String? = nil) {
        self.id = id
        self.text = text
        self.senderID = ""  // Will be populated from database
        self.recipientID = ""  // Will be populated from database
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.isRead = false
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        senderID = try container.decode(String.self, forKey: .senderID)
        recipientID = try container.decode(String.self, forKey: .recipientID)
        
        // isFromCurrentUser is computed at runtime, not stored
        isFromCurrentUser = false
        
        // Handle Firebase Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = Date()
        }
        
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(recipientID, forKey: .recipientID)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(isRead, forKey: .isRead)
    }
}
