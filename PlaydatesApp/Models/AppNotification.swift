import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

// Renamed to AppNotification to avoid conflict with Foundation.Notification
struct AppNotification: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userID: String // The ID of the user *receiving* the notification
    let type: NotificationType
    let relatedID: String // ID of the related object (friend request, chat, playdate)
    let senderID: String? // Optional: ID of the user who triggered the notification
    var senderName: String? // Optional: Name of the sender (denormalized for display)
    var message: String? // Optional: Snippet or custom message
    let timestamp: Date
    var isRead: Bool = false

    enum NotificationType: String, Codable {
        case friendRequest = "FRIEND_REQUEST"
        case newChatMessage = "NEW_CHAT_MESSAGE"
        case playdateInvitation = "PLAYDATE_INVITATION"
        // Add other types as needed (e.g., requestAccepted, playdateUpdate)
    }

    // Basic initializer
    init(id: String? = nil, userID: String, type: NotificationType, relatedID: String, senderID: String? = nil, senderName: String? = nil, message: String? = nil, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.userID = userID
        self.type = type
        self.relatedID = relatedID
        self.senderID = senderID
        self.senderName = senderName
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }

    // Equatable conformance
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id && lhs.id != nil
    }
}
