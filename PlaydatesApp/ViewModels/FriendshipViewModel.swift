import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

// Type alias to resolve ambiguity
typealias FriendshipChatMessage = ChatMessage

// MARK: - Support Models

// FriendRequest used by FriendshipViewModel
struct FriendRequestModel: Identifiable, Codable {
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
}

// MARK: - FriendshipViewModel Class Definition

class FriendshipViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequestModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    let db = Firestore.firestore()
    
    // MARK: - Friend Management Methods
    
    /// Fetch all friends for a user
    func fetchFriends(for userID: String) {
        isLoading = true
        
        db.collection("friendships")
            .whereField("participants", arrayContains: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.friends = []
                    return
                }
                
                // Get friend IDs from friendships
                let friendIDs = documents.compactMap { document -> String? in
                    let data = document.data()
                    guard let participants = data["participants"] as? [String] else { return nil }
                    // Return the ID that is not the current user's ID
                    return participants.first { $0 != userID }
                }
                
                // Fetch user details for each friend ID
                self.fetchUserDetails(for: friendIDs)
            }
    }
    
    /// Fetch user details for a list of user IDs
    private func fetchUserDetails(for userIDs: [String]) {
        guard !userIDs.isEmpty else {
            self.friends = []
            return
        }
        
        // Create a dispatch group to wait for all fetches to complete
        let group = DispatchGroup()
        var fetchedUsers: [User] = []
        
        for userID in userIDs {
            group.enter()
            
            db.collection("users").document(userID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching user details: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let name = data["name"] as? String,
                      let email = data["email"] as? String else {
                    return
                }
                
                // Create a User object
                let user = User(
                    id: userID,
                    name: name,
                    email: email,
                    profileImageURL: data["profileImageURL"] as? String,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    lastActive: (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
                )
                
                fetchedUsers.append(user)
            }
        }
        
        // When all fetches are complete, update the friends array
        group.notify(queue: .main) { [weak self] in
            self?.friends = fetchedUsers
        }
    }
    
    /// Fetch friend requests for a user
    func fetchFriendRequests(for userID: String) {
        isLoading = true
        
        db.collection("friendRequests")
            .whereField("recipientID", isEqualTo: userID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.friendRequests = []
                    return
                }
                
                // Map documents to FriendRequest objects
                self.friendRequests = documents.compactMap { document -> FriendRequestModel? in
                    let data = document.data()
                    
                    guard let senderID = data["senderID"] as? String,
                          let recipientID = data["recipientID"] as? String,
                          let statusString = data["status"] as? String else {
                        return nil
                    }
                    
                    let status: FriendRequestModel.RequestStatus
                    switch statusString {
                    case "accepted":
                        status = .accepted
                    case "declined":
                        status = .declined
                    default:
                        status = .pending
                    }
                    
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return FriendRequestModel(
                        id: document.documentID,
                        senderID: senderID,
                        receiverID: recipientID,
                        status: status,
                        createdAt: createdAt
                    )
                }
            }
    }
    
    /// Send a friend request to another user
    func sendFriendRequest(from senderID: String, to recipientID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        // Check if a friendship or request already exists
        db.collection("friendRequests")
            .whereField("senderID", isEqualTo: senderID)
            .whereField("recipientID", isEqualTo: recipientID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    self.isLoading = false
                    let error = NSError(domain: "FriendshipViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "You have already sent a friend request to this user"])
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Also check if they are already friends
                self.db.collection("friendships")
                    .whereField("participants", arrayContains: senderID)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self else { return }
                        
                        if let error = error {
                            self.isLoading = false
                            self.error = error.localizedDescription
                            completion(.failure(error))
                            return
                        }
                        
                        // Check if they are already friends
                        let alreadyFriends = (snapshot?.documents ?? []).contains { document in
                            guard let participants = document.data()["participants"] as? [String] else { return false }
                            return participants.contains(recipientID)
                        }
                        
                        if alreadyFriends {
                            self.isLoading = false
                            let error = NSError(domain: "FriendshipViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "You are already friends with this user"])
                            self.error = error.localizedDescription
                            completion(.failure(error))
                            return
                        }
                        
                        // Create the friend request
                        let requestData: [String: Any] = [
                            "senderID": senderID,
                            "recipientID": recipientID,
                            "status": "pending",
                            "createdAt": Timestamp(date: Date())
                        ]
                        
                        self.db.collection("friendRequests").document().setData(requestData) { [weak self] error in
                            guard let self = self else { return }
                            
                            self.isLoading = false
                            
                            if let error = error {
                                self.error = error.localizedDescription
                                completion(.failure(error))
                                return
                            }
                            
                            // Success
                            completion(.success(()))
                        }
                    }
            }
    }
    
    /// Create a friend request in Firestore
    private func createFriendRequest(from senderID: String, to recipientID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let requestData: [String: Any] = [
            "senderID": senderID,
            "recipientID": recipientID,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("friendRequests").document().setData(requestData) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error as Error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Respond to a friend request (accept or decline)
    func respondToFriendRequest(request: FriendRequestModel, accept: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        guard let requestID = request.id else {
            self.isLoading = false
            let error = NSError(domain: "FriendshipViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid request ID"])
            self.error = error.localizedDescription
            completion(.failure(error))
            return
        }
        
        // Update the request status
        db.collection("friendRequests").document(requestID).updateData([
            "status": accept ? "accepted" : "declined",
            "updatedAt": Timestamp(date: Date())
        ]) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            if accept {
                // Create a friendship document
                self.createFriendship(between: request.senderID, and: request.receiverID, completion: completion)
            } else {
                self.isLoading = false
                completion(.success(()))
            }
        }
    }
    
    /// Create a friendship between two users
    private func createFriendship(between userID1: String, and userID2: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let friendshipData: [String: Any] = [
            "participants": [userID1, userID2],
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("friendships").document().setData(friendshipData) { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error as Error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Returns the current user's ID from Firebase Auth
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Chat Methods
    
    /// Fetches the chat history between the current user and a friend
    func fetchChatHistory(userID: String, friendID: String, completion: @escaping (Result<[FriendshipChatMessage], Error>) -> Void) {
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
                let messages = documents.compactMap { document -> FriendshipChatMessage? in
                    let data = document.data()
                    
                    // Safely extract data
                    guard let senderID = data["senderID"] as? String,
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
                        id: document.documentID,
                        text: text,
                        isFromCurrentUser: isFromCurrentUser,
                        timestamp: timestamp,
                        imageURL: imageURL
                    )
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
        completion: @escaping (Result<FriendshipChatMessage, Error>) -> Void
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
                completion(.failure(error as Error))
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
            let message = FriendshipChatMessage(
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
