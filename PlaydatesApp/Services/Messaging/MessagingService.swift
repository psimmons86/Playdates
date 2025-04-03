import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import FirebaseAuth // Ensure FirebaseAuth is imported when using its services
import Combine
import UIKit // Needed for UIApplication

class MessagingService: NSObject, ObservableObject {
    static let shared = MessagingService()

    @Published var conversations: [String: [ChatMessage]] = [:]
    @Published var unreadCounts: [String: Int] = [:]
    private var db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]

    private override init() {
        super.init()
    }

    // Register device for push notifications
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }

            // Set delegate AFTER requesting authorization and registering
            Messaging.messaging().delegate = self
        }
    }

    // Save FCM token to user's profile
    func saveUserToken(userID: String, fcmToken: String) {
        db.collection("users").document(userID).updateData([
            "fcmToken": fcmToken
        ]) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("✅ Successfully saved FCM token for user \(userID)")
            }
        }
    }

    // Start listening to conversation messages
    func listenToConversation(between currentUserID: String, and otherUserID: String) {
        let chatID = getChatID(userID1: currentUserID, userID2: otherUserID) // Use internal helper

        // Remove any existing listener
        listeners[chatID]?.remove()
        print("👂 Starting listener for chatID: \(chatID)")

        // Create a new listener
        let listener = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                // Ensure updates happen on the main thread
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        print("❌ Error listening to messages for chatID \(chatID): \(error.localizedDescription)")
                        // Optionally clear conversation on error or handle differently
                        self.conversations[chatID] = []
                        self.unreadCounts[otherUserID] = 0 // Reset unread count on error
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("ℹ️ No message documents found for chatID: \(chatID)")
                        self.conversations[chatID] = []
                        self.unreadCounts[otherUserID] = 0 // Reset unread count if no documents
                        return
                    }

                    // Parse messages
                    let messages = documents.compactMap { document -> ChatMessage? in
                         do {
                             // Use Codable decoding, @DocumentID handles the ID
                             return try document.data(as: ChatMessage.self)
                         } catch {
                             print("⚠️ Warning: Skipping message document due to decoding error: \(document.documentID), Error: \(error)")
                             return nil
                         }
                    }
                    print("✅ Successfully fetched \(messages.count) messages for chatID: \(chatID)")

                    // Update the conversation
                    self.conversations[chatID] = messages // Update @Published property

                    // Count unread messages
                    let unreadCount = messages.filter {
                        !$0.isRead && $0.recipientID == currentUserID
                    }.count

                    self.unreadCounts[otherUserID] = unreadCount // Update @Published property
                    print("📊 Unread count for user \(otherUserID): \(unreadCount)")

                    // Mark messages as read (this involves a write, but the read update is done)
                    self.markMessagesAsRead(in: chatID, for: currentUserID)
                } // End of DispatchQueue.main.async
            }

        // Store the listener
        listeners[chatID] = listener
    }

    // Send a message
    func sendMessage(from senderID: String, to recipientID: String, text: String, imageURL: String? = nil) -> AnyPublisher<ChatMessage, Error> {
        // Return type is AnyPublisher<ChatMessage, Error>
        return Future<ChatMessage, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MessagingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }

            let chatID = self.getChatID(userID1: senderID, userID2: recipientID) // Use internal helper

            // Create message object using the correct initializer
            let messageToSend = ChatMessage(
                senderID: senderID,
                recipientID: recipientID,
                text: text,
                timestamp: Date(), // Use current date
                imageURL: imageURL,
                isRead: false
            )

            let chatDocRef = self.db.collection("chats").document(chatID)
            let messageCollRef = chatDocRef.collection("messages")

            // Step 1: Ensure the chat document exists with participants and metadata
            let chatData: [String: Any] = [
                "participants": [senderID, recipientID], // Ensure participants are set/updated
                "lastMessage": text.isEmpty ? "📷 Photo" : text, // Use placeholder if text is empty but image exists
                "lastMessageTime": Timestamp(date: messageToSend.timestamp),
                "lastSenderID": senderID,
                "updatedAt": Timestamp(date: Date())
            ]

            chatDocRef.setData(chatData, merge: true) { [weak self] error in
                guard let self = self else {
                    promise(.failure(NSError(domain: "MessagingService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Self deallocated"])))
                    return
                }

                if let error = error {
                    print("❌ Error ensuring chat document exists: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                 print("✅ Chat document ensured/updated for chatID: \(chatID)")

                // Step 2: Now that chat doc exists, add the message document using Codable support
                do {
                    // Firestore generates the ID, addDocument returns the reference
                    let newDocRef = try messageCollRef.addDocument(from: messageToSend)
                    print("✅ Message sent successfully to chatID: \(chatID), DocID: \(newDocRef.documentID)")

                    // Send push notification
                    self.sendPushNotification(
                        to: recipientID,
                        from: senderID,
                        message: text.isEmpty ? "📷 Photo" : text
                    )

                    // Create a message object *with the generated ID* for the promise
                    var sentMessage = messageToSend
                    sentMessage.id = newDocRef.documentID // Assign the generated ID
                    promise(.success(sentMessage))

                } catch {
                     print("❌ Error setting message data: \(error.localizedDescription)")
                    promise(.failure(error))
                }
            } // End of chatDocRef.setData completion
        } // End of Future closure
        .eraseToAnyPublisher() // Apply eraseToAnyPublisher to the Future itself
    }

    // Mark messages as read - Keep private
    private func markMessagesAsRead(in chatID: String, for userID: String) {
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .whereField("recipientID", isEqualTo: userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return } // Use self after guard

                if let error = error {
                    print("❌ Error getting unread messages: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    // print("ℹ️ No unread messages to mark for user \(userID) in chat \(chatID)")
                    return
                 }
                 print("ℹ️ Found \(documents.count) unread messages to mark for user \(userID) in chat \(chatID)")

                // Create a batch update
                let batch = self.db.batch() // Use self.db

                for document in documents {
                    // Use self.db
                    let docRef = self.db.collection("chats")
                        .document(chatID)
                        .collection("messages")
                        .document(document.documentID)

                    batch.updateData(["isRead": true], forDocument: docRef)
                }

                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Error marking messages as read: \(error.localizedDescription)")
                    } else {
                         print("✅ Marked \(documents.count) messages as read for user \(userID) in chat \(chatID)")
                    }
                }
            }
    }

    // Update chat metadata for conversation list - Keep private
    private func updateChatMetadata(chatID: String, senderID: String, recipientID: String, lastMessage: String, lastMessageTime: Date) {
        let chatData: [String: Any] = [
            "participants": [senderID, recipientID],
            "lastMessage": lastMessage,
            "lastMessageTime": Timestamp(date: lastMessageTime),
            "lastSenderID": senderID,
            "updatedAt": Timestamp(date: Date())
        ]

        db.collection("chats")
            .document(chatID)
            .setData(chatData, merge: true) { error in
                if let error = error {
                    print("❌ Error updating chat metadata for chatID \(chatID): \(error.localizedDescription)")
                } else {
                     print("✅ Updated chat metadata for chatID: \(chatID)")
                }
            }
    }

    // Send push notification for new message - Keep private
    private func sendPushNotification(to recipientID: String, from senderID: String, message: String) {
        // Get recipient's FCM token
        db.collection("users").document(recipientID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error getting recipient user \(recipientID): \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let fcmToken = data["fcmToken"] as? String else {
                print("ℹ️ No FCM token found for user \(recipientID)")
                return
            }
             print("ℹ️ Found FCM token for recipient \(recipientID)")

            // Get sender's name
            self.db.collection("users").document(senderID).getDocument { senderSnapshot, senderError in // Renamed vars
                if let senderError = senderError {
                    print("❌ Error getting sender user \(senderID): \(senderError.localizedDescription)")
                    return
                }

                guard let senderData = senderSnapshot?.data(), // Renamed var
                      let senderName = senderData["name"] as? String else {
                    print("ℹ️ No sender name found for user \(senderID)")
                    return
                }
                 print("ℹ️ Found sender name: \(senderName)")

                // Create notification payload
                let payload: [String: Any] = [
                    "notification": [
                        "title": "Message from \(senderName)",
                        "body": message
                    ],
                    "data": [
                        "type": "message",
                        "senderID": senderID
                    ],
                    "token": fcmToken
                ]

                // Send notification via Firebase Cloud Function
                self.sendNotificationPayload(payload) // Call using self
            }
        }
    }

    // Send notification via Cloud Function - Keep private
    private func sendNotificationPayload(_ payload: [String: Any]) {
        // This would call a Firebase Cloud Function
        // In a real app, you'd use a Firebase Functions HTTP trigger
        // For simplicity, we're just printing the payload here
        print("☁️ Would send notification payload via Cloud Function: \(payload)")
    }

    // Get a unique chat ID for two users - Keep private
    private func getChatID(userID1: String, userID2: String) -> String {
        // Sort IDs to ensure the same chat ID regardless of who initiates
        let sortedIDs = [userID1, userID2].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }

    // Stop listening to a conversation
    func stopListening(to chatID: String) {
         print("🛑 Stopping listener for chatID: \(chatID)")
        listeners[chatID]?.remove()
        listeners.removeValue(forKey: chatID)
    }
}

// MARK: - FCM Delegate

extension MessagingService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
             print("ℹ️ FCM token received was nil.")
             return
        }
        print("🔑 FCM token received: \(token)")

        // Save token if user is logged in
        // Use the FirebaseAuthService singleton
        if let userID = FirebaseAuthService.shared.currentUser?.uid {
             print("ℹ️ User \(userID) is logged in, saving FCM token.")
            saveUserToken(userID: userID, fcmToken: token)
        } else {
             print("ℹ️ No user logged in, cannot save FCM token yet.")
        }
    }
}
