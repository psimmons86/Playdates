import Foundation
import Firebase
import FirebaseFirestore

class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    private let usersRef = Firestore.firestore().collection("users")

    private init() {}

    // MARK: - Notification Creation Methods

    /// Creates a notification document in the recipient's notification subcollection.
    func createNotification(for userID: String, type: AppNotification.NotificationType, relatedID: String, senderID: String?, message: String? = nil) async {
        guard !userID.isEmpty else {
            print("❌ NotificationService: Cannot create notification, recipient userID is empty.")
            return
        }

        // Fetch sender's name for display (optional but good UX)
        var senderName: String? = nil
        if let validSenderID = senderID, !validSenderID.isEmpty {
            do {
                let senderDoc = try await usersRef.document(validSenderID).getDocument()
                senderName = senderDoc.data()?["name"] as? String
            } catch {
                print("⚠️ NotificationService: Could not fetch sender's name (\(validSenderID)): \(error.localizedDescription)")
            }
        }

        let notification = AppNotification(
            userID: userID,
            type: type,
            relatedID: relatedID,
            senderID: senderID,
            senderName: senderName, // Include fetched sender name
            message: message,
            timestamp: Date(),
            isRead: false
        )

        let notificationRef = usersRef.document(userID).collection("notifications")

        do {
            // Add the notification document. Firestore generates the ID.
            try notificationRef.addDocument(from: notification)
            print("✅ NotificationService: Successfully created \(type.rawValue) notification for user \(userID).")
        } catch {
            print("❌ NotificationService: Failed to create notification for user \(userID): \(error.localizedDescription)")
        }
    }

    // MARK: - Specific Event Triggers (Convenience Methods)

    /// Call this when a friend request is sent.
    func notifyFriendRequestSent(senderID: String, recipientID: String, requestID: String) async {
        await createNotification(
            for: recipientID, // Notify the recipient
            type: .friendRequest,
            relatedID: requestID, // ID of the FriendRequest document
            senderID: senderID
            // Message could be generated here or passed in if needed
        )
    }

    /// Call this when a new chat message is sent.
    func notifyNewChatMessage(senderID: String, recipientID: String, chatID: String, messageSnippet: String?) async {
         await createNotification(
             for: recipientID, // Notify the recipient
             type: .newChatMessage,
             relatedID: chatID, // ID of the chat document/conversation
             senderID: senderID,
             message: messageSnippet // Show a preview of the message
         )
     }

    /// Call this when a playdate invitation is sent.
    func notifyPlaydateInvitationSent(senderID: String, recipientID: String, invitationID: String, playdateTitle: String?) async {
         await createNotification(
             for: recipientID, // Notify the recipient
             type: .playdateInvitation,
             relatedID: invitationID, // ID of the PlaydateInvitation document
             senderID: senderID,
             message: "Invited you to: \(playdateTitle ?? "a playdate")" // Example message
         )
     }

    // Add more specific trigger methods as needed (e.g., friend request accepted)
}
