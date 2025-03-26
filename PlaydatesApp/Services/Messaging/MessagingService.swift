import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import Combine

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
            }
        }
    }
    
    // Start listening to conversation messages
    func listenToConversation(between currentUserID: String, and otherUserID: String) {
        let chatID = getChatID(userID1: currentUserID, userID2: otherUserID)
        
        // Remove any existing listener
        listeners[chatID]?.remove()
        
        // Create a new listener
        let listener = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.conversations[chatID] = []
                    return
                }
                
                // Parse messages
                let messages = documents.compactMap { document -> ChatMessage? in
                    let data = document.data()
                    
                    // Safely extract required fields
                    guard let senderID = data["senderID"] as? String,
                          let text = data["text"] as? String,
                          let recipientID = data["recipientID"] as? String else {
                        return nil
                    }
                    
                    // Handle timestamp
                    let timestamp: Date
                    if let timestampValue = data["timestamp"] as? Timestamp {
                        timestamp = timestampValue.dateValue()
                    } else {
                        timestamp = Date()
                    }
                    
                    // Handle optional fields
                    let imageURL = data["imageURL"] as? String
                    let isRead = data["isRead"] as? Bool ?? false
                    
                    return ChatMessage(
                        id: document.documentID,
                        text: text,
                        senderID: senderID,
                        recipientID: recipientID,
                        isFromCurrentUser: senderID == currentUserID,
                        timestamp: timestamp,
                        imageURL: imageURL,
                        isRead: isRead
                    )
                }
                
                // Update the conversation
                self.conversations[chatID] = messages
                
                // Count unread messages
                let unreadCount = messages.filter {
                    !$0.isRead && $0.recipientID == currentUserID
                }.count
                
                self.unreadCounts[otherUserID] = unreadCount
                
                // Mark messages as read if they're for the current user
                self.markMessagesAsRead(in: chatID, for: currentUserID)
            }
        
        // Store the listener
        listeners[chatID] = listener
    }
    
    // Send a message
    func sendMessage(from senderID: String, to recipientID: String, text: String, imageURL: String? = nil) -> AnyPublisher<ChatMessage, Error> {
        return Future<ChatMessage, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "MessagingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])))
                return
            }
            
            let chatID = self.getChatID(userID1: senderID, userID2: recipientID)
            
            // Create message data
            let messageData: [String: Any] = [
                "senderID": senderID,
                "recipientID": recipientID,
                "text": text,
                "timestamp": Timestamp(date: Date()),
                "isRead": false,
                "imageURL": imageURL as Any
            ]
            
            // Add to Firestore
            let messageRef = self.db.collection("chats")
                .document(chatID)
                .collection("messages")
                .document()
            
            messageRef.setData(messageData) { error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                // Update chat metadata
                self.updateChatMetadata(
                    chatID: chatID,
                    senderID: senderID,
                    recipientID: recipientID,
                    lastMessage: text,
                    lastMessageTime: Date()
                )
                
                // Send push notification
                self.sendPushNotification(
                    to: recipientID,
                    from: senderID,
                    message: text
                )
                
                // Create message object for return
                let message = ChatMessage(
                    id: messageRef.documentID,
                    text: text,
                    senderID: senderID,
                    recipientID: recipientID,
                    isFromCurrentUser: true,
                    timestamp: Date(),
                    imageURL: imageURL,
                    isRead: false
                )
                
                promise(.success(message))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // Mark messages as read
    private func markMessagesAsRead(in chatID: String, for userID: String) {
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .whereField("recipientID", isEqualTo: userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                
                // Create a batch update
                let batch = self.db.batch()
                
                for document in documents {
                    let docRef = self.db.collection("chats")
                        .document(chatID)
                        .collection("messages")
                        .document(document.documentID)
                    
                    batch.updateData(["isRead": true], forDocument: docRef)
                }
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error marking messages as read: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    // Update chat metadata for conversation list
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
                    print("Error updating chat metadata: \(error.localizedDescription)")
                }
            }
    }
    
    // Send push notification for new message
    private func sendPushNotification(to recipientID: String, from senderID: String, message: String) {
        // Get recipient's FCM token
        db.collection("users").document(recipientID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting recipient user: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let fcmToken = data["fcmToken"] as? String else {
                print("No FCM token found for user")
                return
            }
            
            // Get sender's name
            self.db.collection("users").document(senderID).getDocument { snapshot, error in
                if let error = error {
                    print("Error getting sender user: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let senderName = data["name"] as? String else {
                    print("No sender name found")
                    return
                }
                
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
                self.sendNotificationPayload(payload)
            }
        }
    }
    
    // Send notification via Cloud Function
    private func sendNotificationPayload(_ payload: [String: Any]) {
        // This would call a Firebase Cloud Function
        // In a real app, you'd use a Firebase Functions HTTP trigger
        // For simplicity, we're just printing the payload here
        print("Would send notification payload: \(payload)")
    }
    
    // Get a unique chat ID for two users
    private func getChatID(userID1: String, userID2: String) -> String {
        // Sort IDs to ensure the same chat ID regardless of who initiates
        let sortedIDs = [userID1, userID2].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }
    
    // Stop listening to a conversation
    func stopListening(to chatID: String) {
        listeners[chatID]?.remove()
        listeners.removeValue(forKey: chatID)
    }
}

// MARK: - FCM Delegate

extension MessagingService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM token: \(token)")
        
        // Save token if user is logged in
        if let userID = Auth.auth().currentUser?.uid {
            saveUserToken(userID: userID, fcmToken: token)
        }
    }
}
