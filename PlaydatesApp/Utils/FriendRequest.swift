import Foundation
import FirebaseFirestore

struct FriendRequest: Identifiable, Codable {
    var id: String?
    let senderID: String
    let receiverID: String
    let status: RequestStatus
    let createdAt: Date
    
    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderID
        case receiverID
        case status
        case createdAt
    }
    
    init(id: String? = nil, senderID: String, receiverID: String, status: RequestStatus = .pending, createdAt: Date = Date()) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.status = status
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        senderID = try container.decode(String.self, forKey: .senderID)
        receiverID = try container.decode(String.self, forKey: .receiverID)
        
        if let statusString = try container.decodeIfPresent(String.self, forKey: .status),
           let status = RequestStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .pending
        }
        
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(receiverID, forKey: .receiverID)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
