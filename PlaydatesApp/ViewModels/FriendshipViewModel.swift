import Foundation
import Firebase
import FirebaseFirestore
import Combine

class FriendshipViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var friendsListener: ListenerRegistration?
    private var requestsListener: ListenerRegistration?
    
    deinit {
        friendsListener?.remove()
        requestsListener?.remove()
    }
    
    // MARK: - Fetch Friends and Requests
    
    func fetchFriends(for userID: String) {
        isLoading = true
        error = nil
        
        // Remove any existing listener
        friendsListener?.remove()
        
        // Set up a real-time listener for friendships
        friendsListener = db.collection("friendships")
            .whereField("status", isEqualTo: FriendshipStatus.accepted.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
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
                
                do {
                    let friendships = try documents.compactMap { document -> Friendship? in
                        try document.data(as: Friendship.self)
                    }
                    
                    // Filter friendships for the current user
                    let userFriendships = friendships.filter { 
                        $0.userID == userID || $0.friendID == userID 
                    }
                    
                    // Get the IDs of all friends
                    let friendIDs = userFriendships.compactMap { friendship -> String? in
                        if friendship.userID == userID {
                            return friendship.friendID
                        } else if friendship.friendID == userID {
                            return friendship.userID
                        }
                        return nil
                    }
                    
                    if friendIDs.isEmpty {
                        DispatchQueue.main.async {
                            self.friends = []
                        }
                        return
                    }
                    
                    // Fetch user profiles for all friends
                    self.fetchUserProfiles(for: friendIDs) { result in
                        switch result {
                        case .success(let users):
                            DispatchQueue.main.async {
                                self.friends = users
                            }
                        case .failure(let error):
                            self.error = error.localizedDescription
                        }
                    }
                } catch {
                    self.error = "Failed to decode friendships: \(error.localizedDescription)"
                }
            }
    }
    
    func fetchFriendRequests(for userID: String) {
        isLoading = true
        error = nil
        
        // Remove any existing listener
        requestsListener?.remove()
        
        // Set up a real-time listener for friend requests
        requestsListener = db.collection("friendRequests")
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.friendRequests = []
                    self.sentRequests = []
                    return
                }
                
                do {
                    let requests = try documents.compactMap { document -> FriendRequest? in
                        try document.data(as: FriendRequest.self)
                    }
                    
                    DispatchQueue.main.async {
                        // Separate received and sent requests
                        self.friendRequests = requests.filter { $0.recipientID == userID }
                        self.sentRequests = requests.filter { $0.senderID == userID }
                    }
                    
                    // Fetch user profiles for request senders
                    let senderIDs = self.friendRequests.map { $0.senderID }
                    if !senderIDs.isEmpty {
                        self.fetchUserProfiles(for: senderIDs) { _ in }
                    }
                } catch {
                    self.error = "Failed to decode friend requests: \(error.localizedDescription)"
                }
            }
    }
    
    private func fetchUserProfiles(for userIDs: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        let group = DispatchGroup()
        var users: [User] = []
        var fetchError: Error?
        
        for userID in userIDs {
            group.enter()
            
            db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
                defer { group.leave() }
                
                guard let self = self else { return }
                
                if let error = error {
                    fetchError = error
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    return
                }
                
                // Parse document using FirebaseSafetyKit static methods
                if let rawData = snapshot.data() {
                    // IMMEDIATELY sanitize all data to prevent NSNumber->String crashes
                    let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                    
                    // Extract values using safe methods
                    let name = FirebaseSafetyKit.getString(from: data, forKey: "name") ?? "User"
                    let email = FirebaseSafetyKit.getString(from: data, forKey: "email") ?? ""
                    let profileImageURL = FirebaseSafetyKit.getString(from: data, forKey: "profileImageURL")
                    let bio = FirebaseSafetyKit.getString(from: data, forKey: "bio")
                    
                    // Handle dates
                    var createdAt = Date()
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    }
                    
                    var lastActive = Date()
                    if let timestamp = data["lastActive"] as? Timestamp {
                        lastActive = timestamp.dateValue()
                    }
                    
                    // Handle arrays
                    var children: [Child]? = nil
                    if let childrenData = data["children"] as? [[String: Any]] {
                        children = childrenData.compactMap { childData -> Child? in
                            // Sanitize each child data dictionary
                            let sanitizedData = FirebaseSafetyKit.sanitizeData(childData) ?? [:]
                            
                            guard let name = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "name") else { return nil }
                            let age = FirebaseSafetyKit.getInt(from: sanitizedData, forKey: "age") ?? 0
                            let id = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "id") ?? UUID().uuidString
                            let interests = FirebaseSafetyKit.getStringArray(from: sanitizedData, forKey: "interests")
                            
                            return Child(id: id, name: name, age: age, interests: interests)
                        }
                    }
                    
                    // Handle string arrays
                    let friendIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendIDs")
                    let friendRequestIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendRequestIDs")
                    
                    // Create user
                    let user = User(
                        id: userID,
                        name: name,
                        email: email,
                        profileImageURL: profileImageURL,
                        bio: bio,
                        children: children,
                        friendIDs: friendIDs,
                        friendRequestIDs: friendRequestIDs,
                        createdAt: createdAt,
                        lastActive: lastActive
                    )
                    users.append(user)
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(users))
            }
        }
    }
    
    // MARK: - Friend Request Operations
    
    func sendFriendRequest(from senderID: String, to recipientID: String, message: String? = nil, completion: @escaping (Result<FriendRequest, Error>) -> Void) {
        isLoading = true
        error = nil
        
        // Check if a request already exists
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
                    let error = NSError(domain: "FriendshipViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "A friend request already exists between these users"])
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Check if they are already friends
                self.db.collection("friendships")
                    .whereField("userID", isEqualTo: senderID)
                    .whereField("friendID", isEqualTo: recipientID)
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
                            let error = NSError(domain: "FriendshipViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "These users are already friends"])
                            self.error = error.localizedDescription
                            completion(.failure(error))
                            return
                        }
                        
                        // Create a new friend request
                        let newRequest = FriendRequest(
                            senderID: senderID,
                            recipientID: recipientID,
                            message: message,
                            status: .pending,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        
                        do {
                            let docRef = try self.db.collection("friendRequests").addDocument(from: newRequest)
                            
                            docRef.getDocument { [weak self] document, error in
                                guard let self = self else { return }
                                
                                self.isLoading = false
                                
                                if let error = error {
                                    self.error = error.localizedDescription
                                    completion(.failure(error))
                                    return
                                }
                                
                                do {
                                    if let request = try document?.data(as: FriendRequest.self) {
                                        completion(.success(request))
                                    } else {
                                        let error = NSError(domain: "FriendshipViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode created request"])
                                        self.error = error.localizedDescription
                                        completion(.failure(error))
                                    }
                                } catch {
                                    self.error = error.localizedDescription
                                    completion(.failure(error))
                                }
                            }
                        } catch {
                            self.isLoading = false
                            self.error = error.localizedDescription
                            completion(.failure(error))
                        }
                    }
            }
    }
    
    func acceptFriendRequest(_ request: FriendRequest, completion: @escaping (Result<Friendship, Error>) -> Void) {
        guard let id = request.id else {
            let error = NSError(domain: "FriendshipViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Friend request has no ID"])
            self.error = error.localizedDescription
            completion(.failure(error))
            return
        }
        
        isLoading = true
        error = nil
        
        // Update the request status
        var updatedRequest = request
        updatedRequest.status = .accepted
        updatedRequest.updatedAt = Date()
        
        // Create a new friendship
        let newFriendship = Friendship(
            userID: request.senderID,
            friendID: request.recipientID,
            status: .accepted,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Use a batch write to update both documents
        let batch = db.batch()
        
        do {
            // Update the request
            let requestRef = db.collection("friendRequests").document(id)
            try batch.setData(from: updatedRequest, forDocument: requestRef)
            
            // Create the friendship
            let friendshipRef = db.collection("friendships").document()
            try batch.setData(from: newFriendship, forDocument: friendshipRef)
            
            // Commit the batch
            batch.commit { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Get the created friendship
                friendshipRef.getDocument { document, error in
                    if let error = error {
                        self.error = error.localizedDescription
                        completion(.failure(error))
                        return
                    }
                    
                    do {
                        if let friendship = try document?.data(as: Friendship.self) {
                            completion(.success(friendship))
                        } else {
                            let error = NSError(domain: "FriendshipViewModel", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to decode created friendship"])
                            self.error = error.localizedDescription
                            completion(.failure(error))
                        }
                    } catch {
                        self.error = error.localizedDescription
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest, completion: @escaping (Result<FriendRequest, Error>) -> Void) {
        guard let id = request.id else {
            let error = NSError(domain: "FriendshipViewModel", code: 6, userInfo: [NSLocalizedDescriptionKey: "Friend request has no ID"])
            self.error = error.localizedDescription
            completion(.failure(error))
            return
        }
        
        isLoading = true
        error = nil
        
        var updatedRequest = request
        updatedRequest.status = .declined
        updatedRequest.updatedAt = Date()
        
        do {
            try db.collection("friendRequests").document(id).setData(from: updatedRequest)
            
            isLoading = false
            completion(.success(updatedRequest))
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    // MARK: - Friendship Operations
    
    func removeFriend(userID: String, friendID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        // Find the friendship document
        db.collection("friendships")
            .whereField("userID", isEqualTo: userID)
            .whereField("friendID", isEqualTo: friendID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    // Try the reverse relationship
                    self.db.collection("friendships")
                        .whereField("userID", isEqualTo: friendID)
                        .whereField("friendID", isEqualTo: userID)
                        .getDocuments { [weak self] snapshot, error in
                            guard let self = self else { return }
                            
                            if let error = error {
                                self.isLoading = false
                                self.error = error.localizedDescription
                                completion(.failure(error))
                                return
                            }
                            
                            guard let documents = snapshot?.documents, let document = documents.first else {
                                self.isLoading = false
                                let error = NSError(domain: "FriendshipViewModel", code: 7, userInfo: [NSLocalizedDescriptionKey: "Friendship not found"])
                                self.error = error.localizedDescription
                                completion(.failure(error))
                                return
                            }
                            
                            // Delete the friendship
                            document.reference.delete { [weak self] error in
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
                    return
                }
                
                // Delete the friendship
                document.reference.delete { [weak self] error in
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
    
    // MARK: - User Search
    
    func searchUsers(query: String, currentUserID: String, completion: @escaping (Result<[User], Error>) -> Void) {
        guard !query.isEmpty else {
            completion(.success([]))
            return
        }
        
        isLoading = true
        error = nil
        
        // Search for users by name or email
        let lowercasedQuery = query.lowercased()
        
        // We'll use a simpler approach to search by getting all users and filtering in memory
        // This is not ideal for large datasets but works for a small app
        db.collection("users")
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
                
                // Create an array to hold our users
                var users: [User] = []
                
                // Process each document with our safe dictionary extension
                for document in documents {
                    let rawData = document.data()
                    // IMMEDIATELY sanitize the data to prevent NSNumber/String crashes
                    let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                    
                    let documentID = document.documentID
                    
                    // Get name and email safely
                    let name = FirebaseSafetyKit.getString(from: data, forKey: "name") ?? "User"
                    let email = FirebaseSafetyKit.getString(from: data, forKey: "email") ?? ""
                    
                    // Only add users that match our search criteria
                    if documentID != currentUserID,
                       name.lowercased().contains(lowercasedQuery) || 
                       email.lowercased().contains(lowercasedQuery) {
                        
                        let profileImageURL = FirebaseSafetyKit.getString(from: data, forKey: "profileImageURL")
                        let bio = FirebaseSafetyKit.getString(from: data, forKey: "bio")
                        
                        // Handle dates
                        var createdAt = Date()
                        if let timestamp = data["createdAt"] as? Timestamp {
                            createdAt = timestamp.dateValue()
                        }
                        
                        var lastActive = Date()
                        if let timestamp = data["lastActive"] as? Timestamp {
                            lastActive = timestamp.dateValue()
                        }
                        
                        // Handle arrays
                        var children: [Child]? = nil
                        if let childrenData = data["children"] as? [[String: Any]] {
                            children = childrenData.compactMap { childData -> Child? in
                                let sanitizedData = FirebaseSafetyKit.sanitizeData(childData) ?? [:]
                                
                                guard let name = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "name") else { return nil }
                                let age = FirebaseSafetyKit.getInt(from: sanitizedData, forKey: "age") ?? 0
                                let id = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "id") ?? UUID().uuidString
                                let interests = FirebaseSafetyKit.getStringArray(from: sanitizedData, forKey: "interests")
                                
                                return Child(id: id, name: name, age: age, interests: interests)
                            }
                        }
                        
                        // Handle string arrays
                        let friendIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendIDs")
                        let friendRequestIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendRequestIDs")
                        
                        // Create user
                        let user = User(
                            id: documentID,
                            name: name,
                            email: email,
                            profileImageURL: profileImageURL,
                            bio: bio,
                            children: children,
                            friendIDs: friendIDs,
                            friendRequestIDs: friendRequestIDs,
                            createdAt: createdAt,
                            lastActive: lastActive
                        )
                        
                        users.append(user)
                    }
                }
                
                // Return the filtered users
                completion(.success(users))
            }
    }
}
