import Foundation
import FirebaseFirestore

public struct Comment: Codable, Identifiable {
    public let id: String
    public let userID: String
    public let text: String
    public let createdAt: Date
    public let isSystem: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "userId"
        case text
        case createdAt
        case isSystem
    }
    
    public init(id: String = UUID().uuidString, userID: String, text: String, createdAt: Date = Date(), isSystem: Bool = false) {
        self.id = id
        self.userID = userID
        self.text = text
        self.createdAt = createdAt
        self.isSystem = isSystem
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        text = try container.decode(String.self, forKey: .text)
        
        // Handle Firebase Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        isSystem = try container.decodeIfPresent(Bool.self, forKey: .isSystem) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(text, forKey: .text)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encodeIfPresent(isSystem, forKey: .isSystem)
    }
}
