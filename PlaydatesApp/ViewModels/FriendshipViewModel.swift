import Foundation
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Extend FriendshipViewModel with Chat and Invitation Functionality

extension FriendshipViewModel {
    
    // MARK: - Chat Methods
    
    /// Fetches the chat history between the current user and a friend
    func fetchChatHistory(userID: String, friendID: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        isLoading = true
        
        // Create a unique chat ID for the conversation
        let chatID = getChatID(userID: userID, friendID: friendID)
        
        // Query messages from Firestore
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Map documents to ChatMessage objects
                let messages = documents.compactMap { document -> ChatMessage? in
                    do {
                        let data = document.data()
                        
                        // Safely extract data
                        guard let id = document.documentID as String?,
                              let senderID = data["senderID"] as? String,
                              let text = data["text"] as? String else {
                            return nil
                        }
                        
                        // Handle timestamp
                        let timestamp: Date
                        if let timestampValue = data["timestamp"] as? Timestamp {
                            timestamp = timestampValue.dateValue()
                        } else {
                            timestamp = Date()
                        }
                        
                        // Handle optional image URL
                        let imageURL = data["imageURL"] as? String
                        
                        // Determine if message is from current user
                        let isFromCurrentUser = senderID == userID
                        
                        return ChatMessage(
                            id: id,
                            text: text,
                            isFromCurrentUser: isFromCurrentUser,
                            timestamp: timestamp,
                            imageURL: imageURL
                        )
                    } catch {
                        print("Error parsing chat message: \(error.localizedDescription)")
                        return nil
                    }
                }
                
                completion(.success(messages))
            }
    }
    
    /// Sends a message from the current user to a friend
    func sendMessage(
        from senderID: String,
        to recipientID: String,
        text: String,
        imageURL: String? = nil,
        completion: @escaping (Result<ChatMessage, Error>) -> Void
    ) {
        // Create a unique chat ID for the conversation
        let chatID = getChatID(userID: senderID, friendID: recipientID)
        
        // Create the message data
        let messageData: [String: Any] = [
            "senderID": senderID,
            "recipientID": recipientID,
            "text": text,
            "timestamp": Timestamp(date: Date()),
            "read": false,
            "imageURL": imageURL as Any
        ]
        
        // Add message to Firestore
        let messageRef = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .document()
        
        messageRef.setData(messageData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            // Also update chat metadata
            self.updateChatMetadata(
                chatID: chatID,
                senderID: senderID,
                recipientID: recipientID,
                lastMessage: text,
                lastMessageTime: Date()
            )
            
            // Create ChatMessage object for return
            let message = ChatMessage(
                id: messageRef.documentID,
                text: text,
                isFromCurrentUser: true,
                timestamp: Date(),
                imageURL: imageURL
            )
            
            completion(.success(message))
        }
    }
    
    /// Updates metadata for the chat (last message, timestamp, etc.)
    private func updateChatMetadata(
        chatID: String,
        senderID: String,
        recipientID: String,
        lastMessage: String,
        lastMessageTime: Date
    ) {
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
    
    /// Marks all unread messages in a chat as read
    func markMessagesAsRead(userID: String, friendID: String) {
        let chatID = getChatID(userID: userID, friendID: friendID)
        
        // Query all unread messages sent by the friend
        db.collection("chats")
            .document(chatID)
            .collection("messages")
            .whereField("senderID", isEqualTo: friendID)
            .whereField("read", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Update each message
                for document in documents {
                    document.reference.updateData(["read": true])
                }
            }
    }
    
    // Helper to create a consistent chat ID for two users
    private func getChatID(userID: String, friendID: String) -> String {
        // Sort IDs to ensure the same chat ID regardless of who initiates
        let sortedIDs = [userID, friendID].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }
    
    // MARK: - Playdate Invitation Methods
    
    /// Send a playdate invitation to a user
    func sendPlaydateInvitation(
        playdateID: String,
        senderID: String,
        recipientID: String,
        message: String? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let invitationData: [String: Any] = [
            "playdateID": playdateID,
            "senderID": senderID,
            "recipientID": recipientID,
            "status": "pending",
            "message": message as Any,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("playdateInvitations")
            .document()
            .setData(invitationData) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
    }
    
    /// Fetch pending playdate invitations for a user
    func fetchPendingInvitations(
        for userID: String,
        completion: @escaping (Result<[PlaydateInvitation], Error>) -> Void
    ) {
        isLoading = true
        
        db.collection("playdateInvitations")
            .whereField("recipientID", isEqualTo: userID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Map to PlaydateInvitation objects
                let invitations = documents.compactMap { document -> PlaydateInvitation? in
                    let data = document.data()
                    
                    // Safely extract data
                    guard let playdateID = data["playdateID"] as? String,
                          let senderID = data["senderID"] as? String,
                          let recipientID = data["recipientID"] as? String,
                          let statusString = data["status"] as? String,
                          let status = InvitationStatus(rawValue: statusString) else {
                        return nil
                    }
                    
                    // Handle timestamps
                    let createdAt: Date
                    if let createdTimestamp = data["createdAt"] as? Timestamp {
                        createdAt = createdTimestamp.dateValue()
                    } else {
                        createdAt = Date()
                    }
                    
                    let updatedAt: Date
                    if let updatedTimestamp = data["updatedAt"] as? Timestamp {
                        updatedAt = updatedTimestamp.dateValue()
                    } else {
                        updatedAt = Date()
                    }
                    
                    // Handle optional message
                    let message = data["message"] as? String
                    
                    return PlaydateInvitation(
                        id: document.documentID,
                        playdateID: playdateID,
                        senderID: senderID,
                        recipientID: recipientID,
                        status: status,
                        message: message,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
                
                completion(.success(invitations))
            }
    }
    
    /// Respond to a playdate invitation
    func respondToInvitation(
        invitation: PlaydateInvitation,
        accept: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let invitationID = invitation.id else {
            let error = NSError(domain: "FriendshipViewModel", code: 8, userInfo: [NSLocalizedDescriptionKey: "Invitation has no ID"])
            self.error = error.localizedDescription
            completion(.failure(error))
            return
        }
        
        // Update the invitation status
        let status = accept ? InvitationStatus.accepted : InvitationStatus.declined
        
        db.collection("playdateInvitations")
            .document(invitationID)
            .updateData([
                "status": status.rawValue,
                "updatedAt": Timestamp(date: Date())
            ]) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if accept {
                    // If accepted, add user to playdate attendees
                    self.addUserToPlaydate(
                        userID: invitation.recipientID,
                        playdateID: invitation.playdateID,
                        completion: completion
                    )
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Add a user to playdate attendees
    private func addUserToPlaydate(
        userID: String,
        playdateID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Reference to the playdate document
        let playdateRef = db.collection("playdates").document(playdateID)
        
        // Use a transaction to ensure atomic update of attendees
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Get the current playdate data
            let playdateDocument: DocumentSnapshot
            do {
                try playdateDocument = transaction.getDocument(playdateRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Ensure the document exists
            guard let data = playdateDocument.data() else {
                let error = NSError(domain: "FriendshipViewModel", code: 9, userInfo: [NSLocalizedDescriptionKey: "Playdate not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Get current attendees
            var attendeeIDs = data["attendeeIDs"] as? [String] ?? []
            
            // Add the user if not already in the list
            if !attendeeIDs.contains(userID) {
                attendeeIDs.append(userID)
                
                // Update the playdate
                transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: playdateRef)
            }
            
            return nil
        }) { (_, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    // Cancel a friend request that the current user sent
    func cancelFriendRequest(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        db.collection("friendRequests").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
}

// MARK: - Additional Models for Social Features

struct PlaydateInvitation: Identifiable {
    let id: String?
    let playdateID: String
    let senderID: String
    let recipientID: String
    let status: InvitationStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date
}

enum InvitationStatus: String {
    case pending
    case accepted
    case declined
}
