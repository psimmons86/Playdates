import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI // Import SwiftUI if needed for @Published properties or UI interaction

// MARK: - Support Models (Consider moving ChatMessage if not already in Models)

// Assuming ChatMessage exists in Models/ChatMessage.swift
// typealias FriendshipChatMessage = ChatMessage // Use ChatMessage directly

// Custom Error enum for ChatViewModel specific errors
// Add Equatable conformance
enum ChatError: Error, LocalizedError, Equatable {
    case firestoreError(Error)
    case userNotLoggedIn
    case failedToSendMessage
    case failedToFetchHistory
    case failedToMarkAsRead
    case unknown

    var errorDescription: String? {
        switch self {
        case .firestoreError(let error):
            return String(format: NSLocalizedString("chat.error.firestore", comment: "Generic Firestore error in chat"), error.localizedDescription)
        case .userNotLoggedIn:
            return NSLocalizedString("chat.error.userNotLoggedIn", comment: "Error when user is not authenticated for chat")
        case .failedToSendMessage:
            return NSLocalizedString("chat.error.failedToSendMessage", comment: "Error when sending a chat message fails")
        case .failedToFetchHistory:
            return NSLocalizedString("chat.error.failedToFetchHistory", comment: "Error fetching chat history")
        case .failedToMarkAsRead:
            return NSLocalizedString("chat.error.failedToMarkAsRead", comment: "Error marking messages as read")
        case .unknown:
            return NSLocalizedString("chat.error.unknown", comment: "Generic unknown chat error")
        }
    }

    // Manual implementation of Equatable due to associated value Error not being Equatable
    static func == (lhs: ChatError, rhs: ChatError) -> Bool {
        switch (lhs, rhs) {
        case (.firestoreError(let lhsError), .firestoreError(let rhsError)):
            // Compare NSError code and domain if possible, otherwise fallback to description
            let lhsNSError = lhsError as NSError
            let rhsNSError = rhsError as NSError
            if lhsNSError.domain == rhsNSError.domain && lhsNSError.code == rhsNSError.code {
                return true
            }
            // Fallback comparison if not NSErrors or domains/codes differ
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.userNotLoggedIn, .userNotLoggedIn):
            return true
        case (.failedToSendMessage, .failedToSendMessage):
            return true
        case (.failedToFetchHistory, .failedToFetchHistory):
            return true
        case (.failedToMarkAsRead, .failedToMarkAsRead):
            return true
        case (.unknown, .unknown):
            return true
        default:
            // Cases are different or associated values differ
            return false
        }
    }
}


// MARK: - ChatViewModel Class Definition

@MainActor // Ensure UI updates happen on the main thread
class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var error: ChatError?

    // Use service singletons
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private let authService = FirebaseAuthService.shared

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    // Make listener accessible within nonisolated context using nonisolated(unsafe)
    // This is generally safe IF we only call remove() which is thread-safe.
    private nonisolated(unsafe) var chatListener: ListenerRegistration?
    private var currentUserID: String?
    private var friendID: String?
    private var chatID: String?

    // Inject friendID during initialization or via a setup method
    // This ViewModel is typically scoped to a specific chat conversation
    init() {
         // Get current user ID, handle if nil
         guard let uid = authService.currentUser?.uid else { // Use authService
             print("❌ ChatViewModel initialized without a logged-in user.")
             self.error = .userNotLoggedIn
             // Handle this state appropriately in the UI
             return
         }
         self.currentUserID = uid
         print("💬 ChatViewModel initialized for user: \(uid)")
    }


    deinit {
        // Call removeListener directly. ListenerRegistration.remove() is thread-safe.
        removeListener()
        print("🗑️ ChatViewModel deinitialized and listeners removed.")
    }

    // MARK: - Listener Management

    /// Sets up the listener for a specific chat conversation.
    /// Call this when the view displaying the chat appears.
    func setupListener(for friendID: String) {
        guard let userID = self.currentUserID else {
            print("❌ Cannot setup chat listener: currentUserID is nil.")
            self.error = .userNotLoggedIn
            return
        }

        // If listener is already set up for the same friend, do nothing.
        if self.friendID == friendID, chatListener != nil {
             print("👂 Chat listener already active for friend: \(friendID)")
             return
        }

        // Remove previous listener if switching conversations
        removeListener() // Call the nonisolated version

        // Reset friendID and chatID before setting up new listener
        self.friendID = friendID
        self.chatID = getChatID(userID1: userID, userID2: friendID)
        print("👂 Setting up chat listener for chatID: \(self.chatID ?? "N/A") between \(userID) and \(friendID)")

        guard let chatID = self.chatID else {
             print("❌ Could not generate chatID.")
             // Handle error appropriately
             return
        }


        isLoading = true
        error = nil

        let messagesQuery = db.collection("chats")
                               .document(chatID)
                               .collection("messages")
                               .order(by: "timestamp", descending: false) // Fetch oldest first

        // Assign listener within the MainActor context
        chatListener = messagesQuery.addSnapshotListener { [weak self] snapshot, error in
            // Ensure UI updates are on the main thread
            Task { @MainActor in // Ensure processing happens on MainActor
                guard let self = self else { return }
                // Check if the listener is still for the current chatID, otherwise ignore
                guard chatID == self.chatID else {
                    print("👂 Ignoring stale listener update for chatID: \(chatID)")
                    return
                }
                print("👂 Chat listener update received for chatID: \(self.chatID ?? "N/A")")

                self.isLoading = false

                if let error = error {
                    print("❌ Error in chat listener: \(error.localizedDescription)")
                    self.error = .firestoreError(error)
                    self.messages = []
                    return
                }

                guard let snapshot = snapshot else {
                    print("⚠️ Chat listener snapshot is nil.")
                    self.messages = []
                    return
                }

                print("🔍 Chat listener received \(snapshot.documents.count) message documents.")

                snapshot.documentChanges.forEach { diff in
                     var message: ChatMessage?
                     do {
                         // @DocumentID should handle ID assignment during decoding
                         message = try diff.document.data(as: ChatMessage.self)
                     } catch {
                         print("❌ Failed to decode ChatMessage document \(diff.document.documentID): \(error)")
                         return // Skip this problematic document change
                     }

                     // Use optional binding and check for ID
                     guard let validMessage = message, let messageId = validMessage.id else {
                         print("❌ Message missing ID after decoding or message is nil: \(diff.document.documentID)")
                         return // Skip if ID is missing or message is nil
                     }

                     switch diff.type {
                     case .added:
                         if !self.messages.contains(where: { $0.id == messageId }) {
                             self.messages.append(validMessage)
                             print("➕ Added message: \(messageId)")
                         } else {
                              print("⚠️ Duplicate message add detected, skipping: \(messageId)")
                         }
                     case .modified:
                         if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                             self.messages[index] = validMessage
                             print("✏️ Modified message: \(messageId)")
                         } else {
                              print("⚠️ Modified message not found in local array: \(messageId)")
                         }
                     case .removed:
                         if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                             self.messages.remove(at: index)
                             print("➖ Removed message: \(messageId)")
                         } else {
                              print("⚠️ Removed message not found in local array: \(messageId)")
                         }
                     }
                }
                // Ensure messages are sorted after processing changes
                self.messages.sort { $0.timestamp < $1.timestamp }

                self.error = nil
                self.markMessagesAsRead() // Call MainActor isolated function
            }
        }
    }

    /// Generates a consistent chat ID based on two user IDs.
    private func getChatID(userID1: String, userID2: String) -> String {
        return [userID1, userID2].sorted().joined(separator: "_")
    }

    /// Removes the active Firestore listener. Call when the view disappears or in deinit.
    // Make nonisolated so it can be called directly from deinit
    nonisolated func removeListener() {
        // Accessing the listener requires MainActor context or nonisolated(unsafe)
        // Since remove() is thread-safe, we can call it directly.
        // We capture the listener to avoid race conditions with setupListener.
        let listener = self.chatListener
        listener?.remove()
        // Cannot safely nil out self.chatListener here from nonisolated context.
        // It should be nilled out before setting a new one in setupListener or on MainActor.
        print("👂 Chat listener removed (called from nonisolated context).")
        // Resetting friendID/chatID needs to happen on MainActor if accessed from UI
        // Let's handle this reset within setupListener or explicitly when view disappears if needed.
    }


    // MARK: - Chat Actions

    /// Sends a message from the current user to the friend associated with this ViewModel instance.
    func sendMessage(text: String, imageURL: String? = nil) async throws {
        guard let senderID = self.currentUserID else {
            self.error = .userNotLoggedIn
            throw ChatError.userNotLoggedIn
        }
        guard let recipientID = self.friendID else {
            print("❌ Cannot send message: friendID is not set.")
            self.error = .unknown
            throw ChatError.unknown
        }
        guard let chatID = self.chatID else {
             print("❌ Cannot send message: chatID is not set.")
             self.error = .unknown
             throw ChatError.unknown
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || imageURL != nil else {
            print("⚠️ Attempted to send empty message.")
            return
        }

        self.isLoading = true

        // Create ChatMessage instance using the correct initializer (ID is nil)
        let newMessage = ChatMessage(
            senderID: senderID,
            recipientID: recipientID,
            text: trimmedText,
            timestamp: Date(), // Use current date
            imageURL: imageURL,
            isRead: false // New messages are unread
        )

        do {
            // Add message using Codable support, Firestore generates the ID
            let _ = try db.collection("chats").document(chatID).collection("messages").addDocument(from: newMessage)
            print("✅ Message sent successfully to chat \(chatID)")

            // Update chat metadata concurrently
            Task.detached { [weak self] in
                 await self?.updateChatMetadata(
                    chatID: chatID,
                    senderID: senderID,
                    recipientID: recipientID,
                    lastMessage: trimmedText.isEmpty ? "📷 Photo" : trimmedText,
                    lastMessageTime: newMessage.timestamp // Use message timestamp
                )
            }

            // Create notification for the recipient
            await NotificationService.shared.notifyNewChatMessage(
                senderID: senderID,
                recipientID: recipientID,
                chatID: chatID,
                messageSnippet: trimmedText.isEmpty ? "📷 Photo" : trimmedText
            )

            self.isLoading = false
            self.error = nil // Clear error on success

        } catch {
            self.isLoading = false
            print("❌ Error sending message to chat \(chatID): \(error.localizedDescription)")
            let specificError = ChatError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }

    /// Marks messages sent by the friend as read.
    private func markMessagesAsRead() {
        guard let userID = self.currentUserID, let friendID = self.friendID, let chatID = self.chatID else {
            print("⚠️ Cannot mark messages as read: missing user/friend/chat ID.")
            return
        }

        print("🔍 Marking messages as read in chat \(chatID) for user \(userID) from friend \(friendID)")

        let unreadMessagesQuery = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .whereField("recipientID", isEqualTo: userID) // Messages sent TO the current user
            .whereField("senderID", isEqualTo: friendID)   // Messages sent BY the friend
            .whereField("read", isEqualTo: false)         // That are unread

        unreadMessagesQuery.getDocuments { [weak self] (snapshot, error) in
            // Switch back to main actor for UI updates / ViewModel state changes
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Error fetching unread messages for chat \(chatID): \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("ℹ️ No unread messages to mark in chat \(chatID).")
                    return
                }

                print("⏳ Found \(documents.count) unread messages to mark in chat \(chatID).")
                let batch = self.db.batch()
                for document in documents {
                    batch.updateData(["read": true], forDocument: document.reference)
                }

                // Batch commit can be awaited
                do {
                    try await batch.commit()
                    print("✅ Successfully marked \(documents.count) messages as read in chat \(chatID).")
                } catch {
                    print("❌ Error batch updating messages to read for chat \(chatID): \(error.localizedDescription)")
                }
            }
        }
    }


    // MARK: - Helper Functions

    /// Updates the metadata for a chat conversation (e.g., last message, timestamp).
    private func updateChatMetadata(chatID: String, senderID: String, recipientID: String, lastMessage: String, lastMessageTime: Date) async {
        let chatDocRef = db.collection("chats").document(chatID)

        let metadata: [String: Any] = [
            "lastMessage": lastMessage,
            "lastMessageTimestamp": Timestamp(date: lastMessageTime),
            "participants": [senderID, recipientID]
        ]

        do {
            try await chatDocRef.setData(metadata, merge: true)
            print("📝 Chat metadata updated for \(chatID)")
        } catch {
            print("❌ Error updating chat metadata for \(chatID): \(error.localizedDescription)")
        }
    }
}
