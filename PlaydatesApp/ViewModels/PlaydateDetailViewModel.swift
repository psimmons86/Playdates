import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@available(iOS 17.0, *)
class PlaydateDetailViewModel: ObservableObject {
    @Published var host: User?
    @Published var attendees: [User] = []
    @Published var comments: [CommentWithUser] = []
    @Published var friends: [User] = []
    
    @Published var isLoadingHost = false
    @Published var isLoadingAttendees = false
    @Published var isLoadingComments = false
    @Published var isLoadingFriends = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Loading Methods
    
    func loadPlaydateData(playdate: Playdate, currentUserId: String) {
        // Load host
        loadHost(hostId: playdate.hostID)
        
        // Load attendees
        loadAttendees(attendeeIds: playdate.attendeeIDs)
        
        // Load comments
        if let playdateId = playdate.id {
            loadComments(playdateId: playdateId)
        }
        
        // Load user's friends for inviting
        loadFriends(userId: currentUserId)
    }
    
    private func loadHost(hostId: String) {
        isLoadingHost = true
        
        db.collection("users").document(hostId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoadingHost = false
            
            if let error = error {
                print("Error loading host: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    self.host = try snapshot.data(as: User.self)
                } catch {
                    print("Error decoding host: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadAttendees(attendeeIds: [String]) {
        guard !attendeeIds.isEmpty else {
            attendees = []
            return
        }
        
        isLoadingAttendees = true
        
        // Limit to a reasonable batch size
        let batchSize = min(attendeeIds.count, 10)
        let batchedIds = Array(attendeeIds.prefix(batchSize))
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: batchedIds)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingAttendees = false
                
                if let error = error {
                    print("Error loading attendees: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    do {
                        self.attendees = try documents.compactMap { try $0.data(as: User.self) }
                    } catch {
                        print("Error decoding attendees: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    private func loadComments(playdateId: String) {
        isLoadingComments = true
        
        db.collection("playdates")
            .document(playdateId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoadingComments = false
                
                if let error = error {
                    print("Error loading comments: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    // Parse comments
                    let parsedComments = documents.compactMap { document -> Comment? in
                        do {
                            return try document.data(as: Comment.self)
                        } catch {
                            print("Error decoding comment: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    
                    // Load the users for each comment
                    self.loadUsersForComments(comments: parsedComments)
                }
            }
    }
    
    // MARK: - Friend Management
    
    private func loadUsersForComments(comments: [Comment]) {
        // Extract unique user IDs from comments
        let userIds = Array(Set(comments.map { $0.userID }))
        
        if userIds.isEmpty {
            self.comments = []
            return
        }
        
        // Limit to a reasonable batch size
        let batchSize = min(userIds.count, 10)
        let batchedIds = Array(userIds.prefix(batchSize))
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: batchedIds)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading comment users: \(error.localizedDescription)")
                    return
                }
                
                var userMap: [String: User] = [:]
                
                if let documents = snapshot?.documents {
                    // Create a map of user IDs to User objects
                    for document in documents {
                        if let user = try? document.data(as: User.self), let userId = user.id {
                            userMap[userId] = user
                        }
                    }
                    
                    // Create CommentWithUser objects by matching comments with users
                    self.comments = comments.compactMap { comment in
                        if let user = userMap[comment.userID] {
                            return CommentWithUser(comment: comment, user: user)
                        }
                        return nil
                    }
                }
            }
    }
    
    private func loadFriends(userId: String) {
        isLoadingFriends = true
        
        // Query friendships where the user is either user1 or user2
        let query1 = db.collection("friendships")
            .whereField("userID", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
        
        let query2 = db.collection("friendships")
            .whereField("friendID", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
        
        // Execute first query
        query1.getDocuments { [weak self] snapshot1, error1 in
            guard let self = self else { return }
            
            if let error = error1 {
                print("Error loading friendships 1: \(error.localizedDescription)")
                self.isLoadingFriends = false
                return
            }
            
            var friendIds = [String]()
            
            // Get friend IDs from first query
            if let documents = snapshot1?.documents {
                for doc in documents {
                    // Using guard statements for safer data extraction
                    guard let data = doc.data() as? [String: Any] else { continue }
                    guard let friendId = data["friendID"] as? String else { continue }
                    friendIds.append(friendId)
                }
            }
            
            // Execute second query
            query2.getDocuments { [weak self] snapshot2, error2 in
                guard let self = self else { return }
                
                if let error = error2 {
                    print("Error loading friendships 2: \(error.localizedDescription)")
                    self.isLoadingFriends = false
                    return
                }
                
                // Get friend IDs from second query
                if let documents = snapshot2?.documents {
                    for doc in documents {
                        // Using guard statements for safer data extraction
                        guard let data = doc.data() as? [String: Any] else { continue }
                        guard let friendId = data["userID"] as? String else { continue }
                        friendIds.append(friendId)
                    }
                }
                
                // If no friends found, finish loading
                if friendIds.isEmpty {
                    self.friends = []
                    self.isLoadingFriends = false
                    return
                }
                
                // Fetch friend user profiles
                let uniqueFriendIds = Array(Set(friendIds))
                self.fetchUserProfiles(userIds: uniqueFriendIds) { users in
                    self.friends = users
                    self.isLoadingFriends = false
                }
            }
        }
    }
    
    private func fetchUserProfiles(userIds: [String], completion: @escaping ([User]) -> Void) {
        // Limit batch size
        let batchSize = min(userIds.count, 10)
        let batchedIds = Array(userIds.prefix(batchSize))
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: batchedIds)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var users: [User] = []
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let user = try? document.data(as: User.self) {
                            users.append(user)
                        }
                    }
                }
                
                completion(users)
            }
    }
    
    // MARK: - Playdate Actions
    
    func joinPlaydate(playdateId: String, userId: String) {
        let playdateRef = db.collection("playdates").document(playdateId)
        
        // Use a transaction to update attendees atomically
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let playdateDocument: DocumentSnapshot
            do {
                try playdateDocument = transaction.getDocument(playdateRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = playdateDocument.data() else {
                let error = NSError(domain: "PlaydateDetailViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Playdate not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var attendeeIDs = data["attendeeIDs"] as? [String] ?? []
            
            if !attendeeIDs.contains(userId) {
                attendeeIDs.append(userId)
                transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: playdateRef)
            }
            
            return nil
        }) { [weak self] (_, error) in
            if let error = error {
                print("Error joining playdate: \(error.localizedDescription)")
                return
            }
            
            // Refresh attendees
            self?.loadAttendees(attendeeIds: self?.attendees.map { $0.id ?? "" } ?? [] + [userId])
            
            // Optionally, post a join notification or system comment
            // FIXED: Using guard instead of if let for non-optional playdateId
            guard let strongSelf = self else { return }
            strongSelf.addSystemComment(
                playdateId: playdateId,
                userId: userId,
                action: "joined"
            )
        }
    }
    
    func leavePlaydate(playdateId: String, userId: String) {
        let playdateRef = db.collection("playdates").document(playdateId)
        
        // Use a transaction to update attendees atomically
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let playdateDocument: DocumentSnapshot
            do {
                try playdateDocument = transaction.getDocument(playdateRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let data = playdateDocument.data() else {
                let error = NSError(domain: "PlaydateDetailViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Playdate not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var attendeeIDs = data["attendeeIDs"] as? [String] ?? []
            
            if attendeeIDs.contains(userId) {
                attendeeIDs.removeAll { $0 == userId }
                transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: playdateRef)
            }
            
            return nil
        }) { [weak self] (_, error) in
            if let error = error {
                print("Error leaving playdate: \(error.localizedDescription)")
                return
            }
            
            // Refresh attendees
            self?.attendees.removeAll { $0.id == userId }
            
            // Optionally, post a leave notification or system comment
            // FIXED: Using guard instead of if let for non-optional playdateId
            guard let strongSelf = self else { return }
            strongSelf.addSystemComment(
                playdateId: playdateId,
                userId: userId,
                action: "left"
            )
        }
    }
    
    // MARK: - Comment Management
    
    func addComment(playdateId: String, userId: String, text: String, completion: @escaping (Bool) -> Void) {
        let comment = Comment(
            id: UUID().uuidString,
            userID: userId,
            text: text,
            createdAt: Date()
        )
        
        do {
            try db.collection("playdates")
                .document(playdateId)
                .collection("comments")
                .document(comment.id)
                .setData(from: comment)
            
            // If the user has a profile already loaded, attach it to the comment
            if let user = attendees.first(where: { $0.id == userId }) {
                let commentWithUser = CommentWithUser(comment: comment, user: user)
                DispatchQueue.main.async {
                    self.comments.append(commentWithUser)
                    completion(true)
                }
            } else {
                // Fetch the user and add the comment
                db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
                    guard let self = self else {
                        completion(false)
                        return
                    }
                    
                    if let error = error {
                        print("Error fetching user for comment: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    if let snapshot = snapshot, snapshot.exists {
                        if let user = try? snapshot.data(as: User.self) {
                            let commentWithUser = CommentWithUser(comment: comment, user: user)
                            DispatchQueue.main.async {
                                self.comments.append(commentWithUser)
                                completion(true)
                            }
                        } else {
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        } catch {
            print("Error adding comment: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    private func addSystemComment(playdateId: String, userId: String, action: String) {
        // This is a convenience method for system notifications like "X joined the playdate"
        // In a real app, you might handle this differently
        
        // Get user name if available
        let userName = attendees.first(where: { $0.id == userId })?.name ?? "Someone"
        
        let systemMessage: String
        switch action {
        case "joined":
            systemMessage = "\(userName) joined the playdate"
        case "left":
            systemMessage = "\(userName) left the playdate"
        default:
            systemMessage = "\(userName) \(action) the playdate"
        }
        
        let comment = Comment(
            id: UUID().uuidString,
            userID: "system", // Use a special user ID for system messages
            text: systemMessage,
            createdAt: Date(),
            isSystem: true
        )
        
        do {
            try db.collection("playdates")
                .document(playdateId)
                .collection("comments")
                .document(comment.id)
                .setData(from: comment)
            
            // Create a fake system user if needed
            let systemUser = User(
                id: "system",
                name: "System",
                email: "",
                profileImageURL: nil,
                createdAt: Date(),
                lastActive: Date()
            )
            
            let commentWithUser = CommentWithUser(comment: comment, user: systemUser)
            
            DispatchQueue.main.async {
                self.comments.append(commentWithUser)
            }
        } catch {
            print("Error adding system comment: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Invitation Management
    
    func inviteFriendToPlaydate(playdateId: String, senderUserId: String, recipientUserId: String) {
        let invitation: [String: Any] = [
            "playdateID": playdateId,
            "senderID": senderUserId,
            "recipientID": recipientUserId,
            "status": "pending",
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("playdateInvitations")
            .addDocument(data: invitation) { error in
                if let error = error {
                    print("Error sending invitation: \(error.localizedDescription)")
                } else {
                    print("Invitation sent successfully")
                }
            }
    }
}
