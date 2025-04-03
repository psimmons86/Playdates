import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI // Import SwiftUI for @available

// Assuming InvitationStatus is defined in PlaydateInvitation.swift
// Assuming Comment model is defined elsewhere
// Assuming User model is defined elsewhere
// Assuming CommentWithUser model is defined elsewhere
// Assuming Playdate model is defined elsewhere


@available(iOS 17.0, *) // Keep the availability check
class PlaydateDetailViewModel: ObservableObject {
    @Published var playdate: Playdate? // Added: Holds the fetched playdate
    @Published var host: User?
    @Published var attendees: [User] = []
    @Published var comments: [CommentWithUser] = []
    @Published var photoURLs: [String] = [] // Added for photos
    @Published var taggedFriends: [User] = [] // Added for tagged friends

    @Published var isLoadingPlaydate = false // Added: Loading state for the main playdate object
    @Published var isLoadingHost = false
    @Published var isLoadingAttendees = false
    @Published var isLoadingComments = false
    @Published var isLoadingPhotos = false // Added
    @Published var isLoadingTaggedFriends = false // Added

    private let db = Firestore.firestore()
    private var commentsListener: ListenerRegistration? // Listener for real-time comment updates

    deinit {
        commentsListener?.remove() // Clean up listener
        print("PlaydateDetailViewModel deinitialized")
    }

    // MARK: - Loading Methods

    // Modified to accept playdateId and fetch the playdate first
    func loadPlaydateData(playdateId: String, currentUserId: String) {
        // Reset state
        DispatchQueue.main.async {
            self.playdate = nil // Reset playdate
            self.host = nil
            self.attendees = []
            self.comments = []
            self.isLoadingPlaydate = true // Start loading playdate
            self.isLoadingHost = false
            self.isLoadingAttendees = false
            self.isLoadingComments = false
            self.isLoadingPhotos = false
            self.isLoadingTaggedFriends = false
            self.photoURLs = []
            self.taggedFriends = []
            self.commentsListener?.remove() // Remove previous comments listener
        }

        // Fetch the Playdate document
        db.collection("playdates").document(playdateId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching playdate \(playdateId): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoadingPlaydate = false
                    // Optionally set an error state
                }
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("❌ Playdate document \(playdateId) not found.")
                DispatchQueue.main.async {
                    self.isLoadingPlaydate = false
                    // Optionally set an error state
                }
                return
            }

            // Use do-catch for detailed decoding error
            do {
                let fetchedPlaydate = try snapshot.data(as: Playdate.self)

                // Playdate fetched successfully, update state and load related data
                DispatchQueue.main.async {
                    self.playdate = fetchedPlaydate
                    self.isLoadingPlaydate = false

                    // Now load related data using the fetched playdate
                    self.loadHost(hostId: fetchedPlaydate.hostID)
                    self.loadAttendees(attendeeIds: fetchedPlaydate.attendeeIDs)
                    self.photoURLs = fetchedPlaydate.photoURLs ?? [] // Load photos directly
                    self.loadTaggedFriends(friendIds: fetchedPlaydate.taggedFriendIDs ?? [])
                    self.setupCommentsListener(playdateId: playdateId) // Setup comments listener
                }

            } catch {
                print("❌ Failed to decode Playdate document \(playdateId): \(error)")
                // Log detailed decoding error information
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch for key: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), expected type: \(type), debugDescription: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found for key: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), expected type: \(type), debugDescription: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("   Key not found: \(key.stringValue), codingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), debugDescription: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), debugDescription: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error: \(error.localizedDescription)")
                    }
                }
                DispatchQueue.main.async {
                    self.isLoadingPlaydate = false
                    // Optionally set an error state
                }
                return
            } // End catch block
        } // End of getDocument completion handler
    } // End of loadPlaydateData function

    private func loadHost(hostId: String) {
        // Ensure playdate is loaded before trying to load host details
        guard playdate != nil else { return }
        DispatchQueue.main.async { self.isLoadingHost = true }

        db.collection("users").document(hostId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async { // Ensure UI update is on main thread
                guard let self = self else { return }
                self.isLoadingHost = false

                if let error = error {
                    print("Error loading host \(hostId): \(error.localizedDescription)")
                    return
                }

                if let snapshot = snapshot, snapshot.exists {
                    // Use try? for safer decoding
                    var user = try? snapshot.data(as: User.self)
                    // Manually assign ID if @DocumentID fails
                    if user != nil && user?.id == nil {
                        user?.id = snapshot.documentID
                    }
                    self.host = user
                } else {
                    print("Host document \(hostId) not found.")
                }
            } // End main async
        }
    }


    private func loadAttendees(attendeeIds: [String]) {
        // Ensure playdate is loaded
        guard playdate != nil else { return }
        guard !attendeeIds.isEmpty else {
            DispatchQueue.main.async {
                self.attendees = []
                self.isLoadingAttendees = false
            }
            return
        }
        DispatchQueue.main.async { self.isLoadingAttendees = true }

        let batchSize = 30 // Firestore 'in' query limit is 30
        let chunks = attendeeIds.chunked(into: batchSize) // Uses the Array extension
        var fetchedAttendees: [User] = []
        let group = DispatchGroup()
        var fetchError: Error?

        for chunk in chunks {
            guard !chunk.isEmpty else { continue } // Avoid empty chunks if any
            group.enter()
            db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    defer { group.leave() } // Ensure leave is always called

                    if let error = error {
                        print("Error loading attendees chunk: \(error.localizedDescription)")
                        if fetchError == nil { fetchError = error } // Store first error
                        return // Stop processing this chunk on error
                    }

                    guard let documents = snapshot?.documents else {
                        print("Warning: Snapshot documents nil for attendees chunk.")
                        return
                    }

                    // Collect users safely using manual decoding for robustness
                    let usersInChunk = documents.compactMap { doc -> User? in
                        let data = doc.data()
                        let userId = doc.documentID // Get ID directly

                        // Manually extract and decode fields, providing defaults
                        let name = data["name"] as? String ?? "Unknown User"
                        let email = data["email"] as? String ?? ""
                        let profileImageURL = data["profileImageURL"] as? String
                        let bio = data["bio"] as? String
                        let friendIDs = data["friendIDs"] as? [String]
                        let friendRequestIDs = data["friendRequestIDs"] as? [String]
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                        let lastActive = (data["lastActive"] as? Timestamp)?.dateValue()

                        // Manually decode children array, skipping problematic children
                        var decodedChildren: [PlaydateChild]? = nil
                        if let childrenData = data["children"] as? [[String: Any]] {
                            var childrenArray: [PlaydateChild] = []
                            for childData in childrenData {
                                // Attempt to decode each child, skipping if createdAt is missing or other errors occur
                                do {
                                    // Manually decode child from dictionary, handling Timestamp
                                    guard let childName = childData["name"] as? String,
                                          let childAge = childData["age"] as? Int,
                                          let childTimestamp = childData["createdAt"] as? Timestamp else {
                                        print("⚠️ Skipping child due to missing required fields or invalid timestamp during manual User decoding for user \(userId). Child data: \(childData)")
                                        continue // Skip this child if essential data is missing or timestamp is wrong type
                                    }
                                    let childCreatedAt = childTimestamp.dateValue()
                                    // Add the missing parentID argument using the current userId
                                    let child = PlaydateChild(name: childName, age: childAge, parentID: userId, createdAt: childCreatedAt)
                                    childrenArray.append(child)
                                } catch { // Catch any other unexpected errors during manual extraction (less likely now)
                                     print("❌ Unexpected error during manual child decoding for user \(userId): \(error). Skipping child. Child data: \(childData)")
                                }
                            }
                            decodedChildren = childrenArray
                        }

                        // Initialize User with manually decoded data
                        return User(
                            id: userId,
                            name: name,
                            email: email,
                            profileImageURL: profileImageURL,
                            bio: bio,
                            children: decodedChildren,
                            friendIDs: friendIDs,
                            friendRequestIDs: friendRequestIDs,
                            createdAt: createdAt,
                            lastActive: lastActive
                            // name_lowercase will be set by the initializer
                        )
                    }
                    // Append safely within the loop (assuming Firestore callbacks might be serial, but use lock if issues arise)
                    // Using a temporary array per chunk and combining later is safer.
                    // For simplicity here, assuming serial callbacks or low contention.
                    fetchedAttendees.append(contentsOf: usersInChunk)
                }
        }

        group.notify(queue: .main) { [weak self] in
             guard let self = self else { return }
             self.isLoadingAttendees = false
             if fetchError != nil {
                 self.attendees = [] // Clear on error
                 print("Final error loading attendees: \(fetchError!.localizedDescription)")
             } else {
                 // Ensure uniqueness after all chunks are processed
                 var uniqueAttendees: [User] = []
                 var seenIds = Set<String>()
                 for user in fetchedAttendees {
                     // Ensure user.id is not nil before inserting
                     if let id = user.id, !seenIds.contains(id) {
                         uniqueAttendees.append(user)
                         seenIds.insert(id)
                     }
                 }
                 self.attendees = uniqueAttendees.sorted { $0.name < $1.name } // Sort attendees
             }
        }
    }

    private func loadTaggedFriends(friendIds: [String]) {
        // Ensure playdate is loaded
        guard playdate != nil else { return }
        guard !friendIds.isEmpty else {
            DispatchQueue.main.async {
                self.taggedFriends = []
                self.isLoadingTaggedFriends = false
            }
            return
        }
        DispatchQueue.main.async { self.isLoadingTaggedFriends = true }

        // Similar logic to loadAttendees, fetching users based on friendIds
        let batchSize = 30 // Firestore 'in' query limit is 30
        let chunks = friendIds.chunked(into: batchSize)
        var fetchedFriends: [User] = []
        let group = DispatchGroup()
        var fetchError: Error?

        for chunk in chunks {
            guard !chunk.isEmpty else { continue }
            group.enter()
            db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    defer { group.leave() }

                    if let error = error {
                        print("Error loading tagged friends chunk: \(error.localizedDescription)")
                        if fetchError == nil { fetchError = error }
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("Warning: Snapshot documents nil for tagged friends chunk.")
                        return
                    }

                    let usersInChunk = documents.compactMap { doc -> User? in
                        var user = try? doc.data(as: User.self)
                        if user != nil && user?.id == nil {
                            user?.id = doc.documentID
                        }
                        return user
                    }
                    // Append safely (assuming serial callbacks or low contention)
                    fetchedFriends.append(contentsOf: usersInChunk)
                }
        }

        group.notify(queue: .main) { [weak self] in
             guard let self = self else { return }
             self.isLoadingTaggedFriends = false
             if fetchError != nil {
                 self.taggedFriends = []
                 print("Final error loading tagged friends: \(fetchError!.localizedDescription)")
             } else {
                 // Ensure uniqueness and sort
                 var uniqueFriends: [User] = []
                 var seenIds = Set<String>()
                 for user in fetchedFriends {
                     if let id = user.id, !seenIds.contains(id) {
                         uniqueFriends.append(user)
                         seenIds.insert(id)
                     }
                 }
                 self.taggedFriends = uniqueFriends.sorted { $0.name < $1.name }
             }
        }
    }


    // Use a listener for real-time comment updates
    private func setupCommentsListener(playdateId: String) {
        // Ensure playdate is loaded
        guard playdate != nil else { return }
        DispatchQueue.main.async { self.isLoadingComments = true }
        commentsListener?.remove() // Remove previous listener if any

        commentsListener = db.collection("playdates")
            .document(playdateId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                // Ensure UI updates happen on the main thread
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoadingComments = false // Stop loading indicator

                    if let error = error {
                        print("Error listening for comments: \(error.localizedDescription)")
                        self.comments = [] // Clear on error
                        return
                    }

                    guard let documents = snapshot?.documents else {
                         print("No comment documents found in snapshot.")
                         self.comments = [] // Clear if no documents
                         return
                    }

                    // Parse comments
                    let parsedComments = documents.compactMap { document -> Comment? in
                        do {
                            // Use try? for safer decoding, @DocumentID handles ID
                            return try document.data(as: Comment.self)
                        } catch {
                            print("Error decoding comment \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }

                    // Load users for these comments
                    self.loadUsersForComments(comments: parsedComments)
                }
            }
    }


    private func loadUsersForComments(comments: [Comment]) {
        // Extract unique user IDs from comments, excluding "system"
        let userIds = Array(Set(comments.filter { $0.userID != "system" }.map { $0.userID }))

        guard !userIds.isEmpty else {
             // Handle case where there are only system comments or no non-system comments
             DispatchQueue.main.async {
                 self.comments = comments.filter { $0.userID == "system" }.map {
                     let systemUser = User(id: "system", name: "System", email: "", createdAt: Date(), lastActive: Date())
                     return CommentWithUser(comment: $0, user: systemUser)
                 }.sorted { $0.comment.createdAt < $1.comment.createdAt }
             }
             return
        }

        // Limit batch size for 'in' queries
        let batchSize = 10
        let chunks = userIds.chunked(into: batchSize) // Uses Array extension
        var userMap: [String: User] = [:]
        let group = DispatchGroup()
        var fetchError: Error?

        for chunk in chunks {
             guard !chunk.isEmpty else { continue }
            group.enter()
            db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    defer { group.leave() } // Ensure leave is always called

                    if let error = error {
                        print("Error loading comment users chunk: \(error.localizedDescription)")
                        if fetchError == nil { fetchError = error }
                        return // Stop processing this chunk on error
                    }

                    guard let documents = snapshot?.documents else {
                         print("Warning: Snapshot documents nil for comment users chunk.")
                         return
                    }

                    for document in documents {
                        // Use try? for safer decoding
                        if var user = try? document.data(as: User.self) {
                             // Manually assign ID if @DocumentID fails
                             if user.id == nil {
                                 user.id = document.documentID
                             }
                             if let userId = user.id {
                                 userMap[userId] = user // Collect users safely into the map
                             }
                        } else {
                             print("Failed to decode comment user: \(document.documentID)")
                        }
                    }
                }
        }

        group.notify(queue: .main) { [weak self] in // Notify ensures this block is on main
            guard let self = self else { return }

            if let error = fetchError {
                 print("Final error loading comment users: \(error.localizedDescription)")
                 // Don't clear comments entirely on user fetch error, show what we have
                 // self.comments = []
                 return
            }

            // Create CommentWithUser objects by matching comments with users
            var finalComments = comments.compactMap { comment -> CommentWithUser? in
                if comment.userID == "system" {
                    let systemUser = User(id: "system", name: "System", email: "", createdAt: Date(), lastActive: Date())
                    return CommentWithUser(comment: comment, user: systemUser)
                }
                if let user = userMap[comment.userID] {
                    return CommentWithUser(comment: comment, user: user)
                }
                // If user not found, maybe create a placeholder or skip
                print("Warning: User not found for comment ID \(comment.id ?? "N/A"), userID: \(comment.userID)")
                 let placeholderUser = User(id: comment.userID, name: "Unknown User", email: "", createdAt: Date(), lastActive: Date())
                 return CommentWithUser(comment: comment, user: placeholderUser) // Or return nil to skip
                // return nil
            }

            // Sort comments by creation date
            finalComments.sort { $0.comment.createdAt < $1.comment.createdAt }

            // Update the @Published property once on the main thread
            self.comments = finalComments
        }
    }

    // Removed loadFriends and fetchUserProfiles methods


    // MARK: - Playdate Actions (Join/Leave/Photos/Tags)

    // Function to upload images and add URLs to the playdate
    func uploadAndAddPhotos(playdateId: String, images: [UIImage]) async {
        guard !images.isEmpty else { return }

        DispatchQueue.main.async { self.isLoadingPhotos = true }

        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var firstError: Error? = nil

        for image in images {
            dispatchGroup.enter()
            let photoID = UUID().uuidString
            let path = "playdate_photos/\(playdateId)/\(photoID).jpg" // Specific path for playdate photos

            FirebaseStorageService.shared.uploadImage(image, path: path) { result in
                // Using barrier flag for thread safety on shared resources
                DispatchQueue.global().async(flags: .barrier) {
                    switch result {
                    case .success(let urlString):
                        if firstError == nil {
                            uploadedURLs.append(urlString)
                        }
                    case .failure(let error):
                        if firstError == nil {
                            firstError = error
                            print("❌ Error uploading playdate photo: \(error.localizedDescription)")
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            if let error = firstError {
                print("❌ Failed to upload one or more photos: \(error.localizedDescription)")
                // Optionally set an error state on the ViewModel
                self.isLoadingPhotos = false
                return
            }

            guard !uploadedURLs.isEmpty else {
                print("⚠️ No photos were successfully uploaded.")
                self.isLoadingPhotos = false
                return
            }

            // Update Firestore with the new URLs
            let playdateRef = self.db.collection("playdates").document(playdateId)
            playdateRef.updateData([
                "photoURLs": FieldValue.arrayUnion(uploadedURLs)
            ]) { error in
                // This completion is already on main queue due to notify
                self.isLoadingPhotos = false
                if let error = error {
                    print("❌ Error updating playdate with photo URLs: \(error.localizedDescription)")
                    // Optionally set an error state
                } else {
                    print("✅ Successfully added \(uploadedURLs.count) photo URLs to playdate \(playdateId)")
                    // Optimistically update local state
                    self.photoURLs.append(contentsOf: uploadedURLs)
                }
            }
        }
    }


    func joinPlaydate(playdateId: String, userId: String, completion: @escaping (Bool, String?) -> Void) {
        let playdateRef = db.collection("playdates").document(playdateId)

        // First, get the current playdate data
        playdateRef.getDocument { [weak self] (document, error) in
            // This completion might not be on main thread
            DispatchQueue.main.async { // Dispatch the entire logic block
                guard let self = self else {
                    completion(false, "Internal error")
                    return
                }

                if let error = error {
                    print("Error getting playdate document: \(error.localizedDescription)")
                    completion(false, "Failed to retrieve playdate information")
                    return
                }

                guard let document = document, document.exists else {
                    print("Playdate document does not exist")
                    completion(false, "Playdate not found")
                    return
                }

                // Extract current attendee IDs
                var attendeeIDs = document.data()?["attendeeIDs"] as? [String] ?? []

                // Check if user is already attending
                if attendeeIDs.contains(userId) {
                    // User is already attending, consider this a success
                    completion(true, nil)
                    return
                }

                // Add user to attendees
                attendeeIDs.append(userId)

                // Update the playdate document
                playdateRef.updateData(["attendeeIDs": attendeeIDs]) { error in
                     // Ensure completion and UI updates happen on main thread
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error updating attendees: \(error.localizedDescription)")
                            completion(false, "Failed to join playdate")
                            return
                        }

                        print("Successfully joined playdate")

                        // Update local attendees list optimistically or fetch user data
                        if !self.attendees.contains(where: { $0.id == userId }) {
                            // Fetch the user if not already in attendees
                            self.db.collection("users").document(userId).getDocument { (userDoc, error) in
                                // This completion might not be on main thread
                                DispatchQueue.main.async { // Dispatch the logic inside
                                    if let userDoc = userDoc, userDoc.exists, var user = try? userDoc.data(as: User.self) {
                                        // Manually assign ID if needed
                                        if user.id == nil { user.id = userDoc.documentID }
                                        // Ensure this inner update is also main thread
                                        self.attendees.append(user)
                                        self.attendees.sort { $0.name < $1.name } // Keep sorted
                                    } else if let error = error {
                                         print("Error fetching joining user details: \(error.localizedDescription)")
                                    } else {
                                         print("Joining user document not found.")
                                    }
                                }
                            }
                        }

                        // Add system comment (this function already dispatches internally)
                        self.addSystemComment(
                            playdateId: playdateId,
                            userId: userId,
                            action: "joined"
                        )

                        completion(true, nil)
                    }
                }
            }
        }
    }

    func leavePlaydate(playdateId: String, userId: String, completion: @escaping (Bool, String?) -> Void) {
        let playdateRef = db.collection("playdates").document(playdateId)

        // First, get the current playdate data
        playdateRef.getDocument { [weak self] (document, error) in
            // This completion might not be on main thread
            DispatchQueue.main.async { // Dispatch the entire logic block
                guard let self = self else {
                    completion(false, "Internal error")
                    return
                }

                if let error = error {
                    print("Error getting playdate document: \(error.localizedDescription)")
                    completion(false, "Failed to retrieve playdate information")
                    return
                }

                guard let document = document, document.exists else {
                    print("Playdate document does not exist")
                    completion(false, "Playdate not found")
                    return
                }

                // Check if user is the host
                if document.data()?["hostID"] as? String == userId {
                    completion(false, "Host cannot leave the playdate")
                    return
                }

                // Extract current attendee IDs
                var attendeeIDs = document.data()?["attendeeIDs"] as? [String] ?? []

                // Check if user is attending
                if !attendeeIDs.contains(userId) {
                    // User is not attending, consider this a success
                    completion(true, nil)
                    return
                }

                // Remove user from attendees
                attendeeIDs.removeAll { $0 == userId }

                // Update the playdate document
                playdateRef.updateData(["attendeeIDs": attendeeIDs]) { error in
                     // Ensure completion and UI updates happen on main thread
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error updating attendees: \(error.localizedDescription)")
                            completion(false, "Failed to leave playdate")
                            return
                        }

                        print("Successfully left playdate")

                        // Update local attendees list
                        self.attendees.removeAll { $0.id == userId }

                        // Add system comment (this function already dispatches internally)
                        self.addSystemComment(
                            playdateId: playdateId,
                            userId: userId,
                            action: "left"
                        )

                        completion(true, nil)
                    }
                }
            }
        }
    }

    // MARK: - Photo Management (uploadAndAddPhotos handles this now)

    // Removed placeholder addPhoto function

    // MARK: - Tagged Friends Management

    // Updates the tagged friends for a playdate in Firestore
    func updateTaggedFriends(playdateId: String, friendIds: [String], completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.main.async { self.isLoadingTaggedFriends = true }
        let playdateRef = db.collection("playdates").document(playdateId)

        playdateRef.updateData([
            // Overwrite the existing array with the new list of selected friend IDs
            "taggedFriendIDs": friendIds
        ]) { error in
            // Ensure completion happens on the main thread
            DispatchQueue.main.async {
                // Stop loading indicator regardless of success or failure
                self.isLoadingTaggedFriends = false
                if let error = error {
                    print("Error updating tagged friends: \(error.localizedDescription)")
                    completion(false, "Failed to update tagged friends.")
                } else {
                    print("✅ Tagged friends updated successfully for playdate \(playdateId).")
                    // Reload tagged friends locally to reflect the changes immediately
                    // This assumes loadTaggedFriends fetches User objects based on IDs
                    self.loadTaggedFriends(friendIds: friendIds)
                    completion(true, nil) // Indicate success
                }
            }
        }
    }


    // MARK: - Comment Management

    func addComment(playdateId: String, userId: String, text: String, completion: @escaping (Bool) -> Void) {
        // Create a new comment object (ID will be generated by Firestore)
        let comment = Comment(
            userID: userId,
            text: text,
            createdAt: Date()
            // isSystem defaults to false
        )

        // Reference to the comments collection
        let commentsRef = db.collection("playdates")
            .document(playdateId)
            .collection("comments")

        // Add the comment to Firestore using Codable support
        do {
            // Use `try` because addDocument(from:) can throw
            let newDocRef = try commentsRef.addDocument(from: comment)
            print("Comment added successfully with ID: \(newDocRef.documentID)")
            // Listener will handle UI update, just call completion
            DispatchQueue.main.async { completion(true) }

        } catch {
            // Handle encoding error immediately
            print("Error encoding comment: \(error.localizedDescription)")
             // Dispatch completion to main thread
            DispatchQueue.main.async { completion(false) }
        }
    }


    private func addSystemComment(playdateId: String, userId: String, action: String) {
        // This function updates self.comments, ensure it happens on main thread
        // It's already marked @MainActor, but good practice to be explicit if needed elsewhere
        // DispatchQueue.main.async { [weak self] in // Not needed due to @MainActor
            // Removed: guard let self = self else { return } - self is not optional here

            // Get user name if available - Accessing @Published var, should be on main thread
            let userName = self.attendees.first(where: { $0.id == userId })?.name ?? self.host?.name ?? "Someone"

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
                userID: "system", // Use a special user ID for system messages
                text: systemMessage,
                createdAt: Date(),
                isSystem: true
            )

            do {
                // Use `try` because addDocument(from:) can throw
                let _ = try self.db.collection("playdates")
                    .document(playdateId)
                    .collection("comments")
                    .addDocument(from: comment) // Firestore generates ID
                // Comment successfully written, listener should pick it up.
            } catch {
                print("Error encoding/adding system comment: \(error.localizedDescription)")
            }
        // } // End DispatchQueue.main.async if used
    }

    // Removed unused inviteFriendToPlaydate function which was causing compiler error

} // End of class PlaydateDetailViewModel

// Note: The Array.chunked extension is now expected to be in PlaydatesApp/Utils/Extensions/ArrayExtensions.swift
