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
    
    // MARK: - Friend Management Convenience Methods
    
    /// Remove a friendship between the current user and another user
    func removeFriendship(friendId: String, completion: ((Bool) -> Void)? = nil) {
        guard let currentUserId = self.currentUserId else {
            self.error = "User not logged in"
            completion?(false)
            return
        }
        
        isLoading = true
        
        // Query for the friendship document
        db.collection("friendships")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    completion?(false)
                    return
                }
                
                // Find the friendship document that contains both users
                let friendshipDoc = snapshot?.documents.first { document in
                    guard let participants = document.data()["participants"] as? [String] else { 
                        return false
                    }
                    return participants.contains(friendId)
                }
                
                guard let friendshipDoc = friendshipDoc else {
                    self.isLoading = false
                    self.error = "Friendship not found"
                    completion?(false)
                    return
                }
                
                // Delete the friendship document
                self.db.collection("friendships").document(friendshipDoc.documentID).delete { error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error.localizedDescription
                        completion?(false)
                        return
                    }
                    
                    // Remove the friend from the local array
                    self.friends.removeAll { $0.id == friendId }
                    completion?(true)
                }
            }
    }
    
    /// Accept a friend request
    func acceptFriendRequest(requestId: String, completion: ((Bool) -> Void)? = nil) {
        isLoading = true
        
        // Get the request details
        db.collection("friendRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                completion?(false)
                return
            }
            
            guard let data = snapshot?.data(),
                  let senderID = data["senderID"] as? String,
                  let receiverID = data["recipientID"] as? String else {
                self.isLoading = false
                self.error = "Invalid friend request data"
                completion?(false)
                return
            }
            
            // Create a FriendRequestModel to use with existing method
            let request = FriendRequestModel(
                id: requestId,
                senderID: senderID,
                receiverID: receiverID,
                status: .pending
            )
            
            // Use the existing method to accept the request
            self.respondToFriendRequest(request: request, accept: true) { result in
                switch result {
                case .success:
                    // Update the local arrays
                    self.friendRequests.removeAll { $0.id == requestId }
                    self.fetchUserDetails(for: [senderID]) // Refresh the friends list
                    completion?(true)
                case .failure(let error):
                    self.error = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }
    
    /// Decline a friend request
    func declineFriendRequest(requestId: String, completion: ((Bool) -> Void)? = nil) {
        isLoading = true
        
        // Get the request details
        db.collection("friendRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                completion?(false)
                return
            }
            
            guard let data = snapshot?.data(),
                  let senderID = data["senderID"] as? String,
                  let receiverID = data["recipientID"] as? String else {
                self.isLoading = false
                self.error = "Invalid friend request data"
                completion?(false)
                return
            }
            
            // Create a FriendRequestModel to use with existing method
            let request = FriendRequestModel(
                id: requestId,
                senderID: senderID,
                receiverID: receiverID,
                status: .pending
            )
            
            // Use the existing method to decline the request
            self.respondToFriendRequest(request: request, accept: false) { result in
                switch result {
                case .success:
                    // Update the local arrays
                    self.friendRequests.removeAll { $0.id == requestId }
                    completion?(true)
                case .failure(let error):
                    self.error = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }
    
    /// Check if a user is already a friend
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.id == userId }
    }
    
    /// Check if a friend request is pending to a specific user
    func isFriendRequestPending(userId: String) -> Bool {
        // Check if there's a pending request where current user is sender and userId is recipient
        // or vice versa
        guard let currentUserId = self.currentUserId else { return false }
        
        // Check pending sent requests
        var pendingSentRequests: [FriendRequestModel] = []
        
        // We'll need to query Firestore for this, but for now we'll just check our local array
        return pendingSentRequests.contains { 
            ($0.senderID == currentUserId && $0.receiverID == userId) ||
            ($0.senderID == userId && $0.receiverID == currentUserId)
        }
    }
    
    /// Search users by name
    func searchByName(_ query: String, completion: @escaping ([User]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        print("DEBUG: Firebase searchByName executing with query: \(query)")
        
        // Improved search that's more flexible and shows debug info
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Firebase search error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No user documents found in Firebase")
                completion([])
                return
            }
            
            print("DEBUG: Found \(documents.count) total users in database")
            
            // More lenient searching - split query into words and match any
            let queryTerms = query.lowercased().split(separator: " ").map(String.init)
            
            // Show some document samples for debugging
            if !documents.isEmpty {
                print("DEBUG: Sample user document fields:")
                let sampleDoc = documents[0].data()
                for (key, value) in sampleDoc {
                    print("  \(key): \(value)")
                }
            }
            
            // Filter by name, case-insensitive, with partial matching
            var filteredUsers: [User] = []
            
            for document in documents {
                let data = document.data()
                
                // Try to extract user data safely
                let name = data["name"] as? String ?? data["displayName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                // For debugging
                if !name.isEmpty {
                    print("DEBUG: Comparing name: \(name) with query: \(query)")
                }
                
                // Search logic - check if any query term is in the name
                let nameLowercased = name.lowercased()
                let matchesName = queryTerms.contains { term in
                    nameLowercased.contains(term)
                } || nameLowercased.contains(query.lowercased())
                
                if matchesName {
                    print("DEBUG: Found match: \(name)")
                    
                    let user = User(
                        id: document.documentID,
                        name: name,
                        email: email,
                        profileImageURL: data["profileImageURL"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        lastActive: (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    filteredUsers.append(user)
                }
            }
            
            print("DEBUG: Name search returning \(filteredUsers.count) results")
            completion(filteredUsers)
        }
    }
    
    /// Search users by email
    func searchByEmail(_ query: String, completion: @escaping ([User]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        print("DEBUG: Firebase searchByEmail executing with query: \(query)")
        
        // Improved search with more debugging
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Firebase search error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No user documents found in Firebase")
                completion([])
                return
            }
            
            print("DEBUG: Searching through \(documents.count) users for email match")
            
            // Filter by email with more flexible matching
            let queryLowercased = query.lowercased()
            var filteredUsers: [User] = []
            
            for document in documents {
                let data = document.data()
                
                let name = data["name"] as? String ?? data["displayName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                // More tolerant email matching
                if email.lowercased().contains(queryLowercased) {
                    print("DEBUG: Found email match: \(email)")
                    
                    let user = User(
                        id: document.documentID,
                        name: name,
                        email: email,
                        profileImageURL: data["profileImageURL"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        lastActive: (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    filteredUsers.append(user)
                }
            }
            
            print("DEBUG: Email search returning \(filteredUsers.count) results")
            completion(filteredUsers)
        }
    }
    
    /// Combined search for users
    func searchUsers(_ query: String, completion: @escaping ([User]) -> Void) {
        guard !query.isEmpty else {
            completion([])
            return
        }
        
        print("DEBUG: Starting combined search with query: \(query)")
        
        // Create a dispatch group to handle multiple queries
        let dispatchGroup = DispatchGroup()
        var allResults: [User] = []
        
        // Query Firestore directly with a more comprehensive approach
        dispatchGroup.enter()
        db.collection("users").getDocuments { [weak self] snapshot, error in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Firebase search error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("DEBUG: No user documents found in Firebase")
                return
            }
            
            print("DEBUG: Found \(documents.count) total users to search through")
            
            // Split query into terms for more flexible matching
            let queryTerms = query.lowercased().split(separator: " ").map(String.init)
            let queryLowercased = query.lowercased()
            
            for document in documents {
                let data = document.data()
                
                // Try different field names that might exist
                let name = data["name"] as? String ?? 
                           data["displayName"] as? String ?? 
                           data["fullName"] as? String ?? ""
                           
                let email = data["email"] as? String ?? ""
                
                // Early diagnostic for specific search
                if queryLowercased.contains("nora") || queryLowercased.contains("casey") {
                    print("DEBUG: Checking document ID: \(document.documentID)")
                    print("DEBUG: Name found: \(name), Email: \(email)")
                    print("DEBUG: Full document data: \(data)")
                }
                
                // More comprehensive matching
                let nameLowercased = name.lowercased()
                let emailLowercased = email.lowercased()
                
                // Check for matches across different criteria
                let matchesFullName = nameLowercased.contains(queryLowercased)
                let matchesEmail = emailLowercased.contains(queryLowercased)
                
                // Check if any term matches part of the name
                let matchesNameTerms = queryTerms.contains { term in
                    nameLowercased.contains(term)
                }
                
                if matchesFullName || matchesEmail || matchesNameTerms {
                    print("DEBUG: Found match: \(name) / \(email)")
                    
                    // Create user object and add to results
                    let user = User(
                        id: document.documentID,
                        name: name,
                        email: email,
                        profileImageURL: data["profileImageURL"] as? String ?? data["photoURL"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        lastActive: (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    allResults.append(user)
                }
            }
        }
        
        // When all searches are complete
        dispatchGroup.notify(queue: .main) {
            print("DEBUG: Combined search returning \(allResults.count) results")
            completion(allResults)
        }
    }
}
