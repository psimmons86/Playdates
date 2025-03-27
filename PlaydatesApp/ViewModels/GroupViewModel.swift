import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class GroupViewModel: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = GroupViewModel()
    
    // Published properties for UI updates
    @Published var userGroups: [Group] = []
    @Published var nearbyGroups: [Group] = []
    @Published var recommendedGroups: [Group] = []
    @Published var searchResults: [Group] = []
    @Published var selectedGroup: Group?
    @Published var groupPosts: [GroupPost] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Firestore references
    private let db = Firestore.firestore()
    private var groupsRef: CollectionReference {
        return db.collection("groups")
    }
    private var postsRef: CollectionReference {
        return db.collection("group_posts")
    }
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Group Operations
    
    /// Fetch groups where the current user is a member
    func fetchUserGroups(userID: String) {
        isLoading = true
        errorMessage = nil
        
        groupsRef.whereField("memberIDs", arrayContains: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch groups: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.userGroups = []
                    return
                }
                
                self.userGroups = documents.compactMap { document -> Group? in
                    try? document.data(as: Group.self)
                }
            }
    }
    
    /// Fetch groups based on location proximity
    func fetchNearbyGroups(location: Location, radiusInKm: Double = 10.0) {
        isLoading = true
        errorMessage = nil
        
        // In a real implementation, this would use geoqueries
        // For now, we'll simulate by fetching public neighborhood groups
        groupsRef.whereField("privacyType", isEqualTo: GroupPrivacyType.public.rawValue)
            .whereField("groupType", isEqualTo: GroupType.neighborhood.rawValue)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch nearby groups: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.nearbyGroups = []
                    return
                }
                
                self.nearbyGroups = documents.compactMap { document -> Group? in
                    try? document.data(as: Group.self)
                }
                
                // In a real implementation, we would filter by distance here
                // For now, we'll just return all results
            }
    }
    
    /// Search for groups by name, description, or tags
    func searchGroups(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let lowercaseQuery = query.lowercased()
        
        // In a real implementation, this would use full-text search
        // For now, we'll use the name_lowercase field
        groupsRef.whereField("name_lowercase", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name_lowercase", isLessThanOrEqualTo: lowercaseQuery + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to search groups: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.searchResults = []
                    return
                }
                
                self.searchResults = documents.compactMap { document -> Group? in
                    try? document.data(as: Group.self)
                }
            }
    }
    
    /// Create a new group
    func createGroup(group: Group, completion: @escaping (Result<Group, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = groupsRef.document()
            var newGroup = group
            newGroup.id = docRef.documentID
            
            try docRef.setData(from: newGroup) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to create group: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Add to user's groups
                self.userGroups.append(newGroup)
                completion(.success(newGroup))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode group: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Update an existing group
    func updateGroup(group: Group, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let id = group.id else {
            completion(.failure(NSError(domain: "GroupViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Group ID is missing"])))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try groupsRef.document(id).setData(from: group) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to update group: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Update in local arrays
                if let index = self.userGroups.firstIndex(where: { $0.id == id }) {
                    self.userGroups[index] = group
                }
                
                if let index = self.nearbyGroups.firstIndex(where: { $0.id == id }) {
                    self.nearbyGroups[index] = group
                }
                
                if self.selectedGroup?.id == id {
                    self.selectedGroup = group
                }
                
                completion(.success(()))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode group: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Join a group
    func joinGroup(groupID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let groupRef = groupsRef.document(groupID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let groupDocument: DocumentSnapshot
            do {
                try groupDocument = transaction.getDocument(groupRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var group = try? groupDocument.data(as: Group.self) else {
                let error = NSError(domain: "GroupViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode group"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Check if user is already a member
            if group.memberIDs.contains(userID) {
                return nil // Already a member, no action needed
            }
            
            // Check privacy type
            if group.privacyType == .inviteOnly || group.privacyType == .private {
                // Add to pending members
                if !group.pendingMemberIDs.contains(userID) {
                    group.pendingMemberIDs.append(userID)
                }
            } else {
                // Public group, add directly to members
                group.memberIDs.append(userID)
            }
            
            // Update the group
            do {
                try transaction.setData(from: group, forDocument: groupRef)
                return group
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to join group: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedGroup = result as? Group {
                // Update local arrays
                if let index = self.nearbyGroups.firstIndex(where: { $0.id == groupID }) {
                    self.nearbyGroups[index] = updatedGroup
                }
                
                if let index = self.recommendedGroups.firstIndex(where: { $0.id == groupID }) {
                    self.recommendedGroups[index] = updatedGroup
                }
                
                // If it's a public group, add to user's groups
                if updatedGroup.privacyType == .public {
                    self.userGroups.append(updatedGroup)
                }
                
                completion(.success(()))
            } else {
                completion(.success(()))  // No changes needed
            }
        }
    }
    
    /// Leave a group
    func leaveGroup(groupID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let groupRef = groupsRef.document(groupID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let groupDocument: DocumentSnapshot
            do {
                try groupDocument = transaction.getDocument(groupRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var group = try? groupDocument.data(as: Group.self) else {
                let error = NSError(domain: "GroupViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode group"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Remove user from members
            group.memberIDs.removeAll { $0 == userID }
            
            // Remove user from admins if they are an admin
            group.adminIDs.removeAll { $0 == userID }
            
            // Remove user from moderators if they are a moderator
            group.moderatorIDs.removeAll { $0 == userID }
            
            // Update the group
            do {
                try transaction.setData(from: group, forDocument: groupRef)
                return group
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to leave group: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            // Remove from user's groups
            self.userGroups.removeAll { $0.id == groupID }
            
            completion(.success(()))
        }
    }
    
    // MARK: - Group Post Operations
    
    /// Fetch posts for a specific group
    func fetchGroupPosts(groupID: String) {
        isLoading = true
        errorMessage = nil
        
        postsRef.whereField("groupID", isEqualTo: groupID)
            .whereField("status", isEqualTo: PostStatus.published.rawValue)
            .order(by: "isPinned", descending: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.groupPosts = []
                    return
                }
                
                self.groupPosts = documents.compactMap { document -> GroupPost? in
                    try? document.data(as: GroupPost.self)
                }
            }
    }
    
    /// Create a new post in a group
    func createPost(post: GroupPost, completion: @escaping (Result<GroupPost, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = postsRef.document()
            var newPost = post
            newPost.id = docRef.documentID
            
            try docRef.setData(from: newPost) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to create post: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Add to local posts array
                self.groupPosts.insert(newPost, at: 0)
                completion(.success(newPost))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode post: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Like or unlike a post
    func toggleLikePost(postID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let postRef = postsRef.document(postID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var post = try? postDocument.data(as: GroupPost.self) else {
                let error = NSError(domain: "GroupViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode post"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Toggle like status
            if post.likedByIDs.contains(userID) {
                post.likedByIDs.removeAll { $0 == userID }
            } else {
                post.likedByIDs.append(userID)
            }
            
            // Update the post
            do {
                try transaction.setData(from: post, forDocument: postRef)
                return post
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to update like status: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedPost = result as? GroupPost, let index = self.groupPosts.firstIndex(where: { $0.id == postID }) {
                self.groupPosts[index] = updatedPost
            }
            
            completion(.success(()))
        }
    }
    
    /// Add a comment to a post
    func addCommentToPost(postID: String, comment: Comment, completion: @escaping (Result<Comment, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        // First, save the comment to the comments collection
        let commentsRef = db.collection("comments")
        let commentRef = commentsRef.document(comment.id)
        
        do {
            try commentRef.setData(from: comment) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Failed to save comment: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Now update the post to reference this comment
                let postRef = self.postsRef.document(postID)
                
                postRef.updateData([
                    "commentIDs": FieldValue.arrayUnion([comment.id])
                ]) { error in
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Failed to update post with comment: \(error.localizedDescription)"
                        completion(.failure(error))
                        return
                    }
                    
                    // Update local post if it exists
                    if let index = self.groupPosts.firstIndex(where: { $0.id == postID }) {
                        var updatedPost = self.groupPosts[index]
                        updatedPost.commentIDs.append(comment.id)
                        self.groupPosts[index] = updatedPost
                    }
                    
                    completion(.success(comment))
                }
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode comment: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Vote on a poll option
    func voteOnPoll(postID: String, optionID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let postRef = postsRef.document(postID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var post = try? postDocument.data(as: GroupPost.self),
                  post.isPoll,
                  var pollOptions = post.pollOptions else {
                let error = NSError(domain: "GroupViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid poll post"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Remove user from any existing votes
            for i in 0..<pollOptions.count {
                pollOptions[i].votedByIDs.removeAll { $0 == userID }
            }
            
            // Add user's vote to the selected option
            if let index = pollOptions.firstIndex(where: { $0.id == optionID }) {
                pollOptions[index].votedByIDs.append(userID)
            }
            
            post.pollOptions = pollOptions
            
            // Update the post
            do {
                try transaction.setData(from: post, forDocument: postRef)
                return post
            } catch {
                errorPointer?.pointee = error as NSError as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to vote on poll: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedPost = result as? GroupPost, let index = self.groupPosts.firstIndex(where: { $0.id == postID }) {
                self.groupPosts[index] = updatedPost
            }
            
            completion(.success(()))
        }
    }
}
