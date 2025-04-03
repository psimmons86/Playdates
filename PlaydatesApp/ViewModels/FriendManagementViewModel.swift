import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI
import FirebaseAuth // Ensure FirebaseAuth is imported

// MARK: - Support Models (Consider moving to separate files if used elsewhere)

// FriendRequest used by FriendManagementViewModel
// Add Equatable conformance
struct FriendRequestModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // Use @DocumentID for automatic mapping
    let senderID: String
    let receiverID: String
    var status: RequestStatus // Make status mutable if needed for updates
    let createdAt: Date
    var updatedAt: Date? // Add updatedAt for tracking changes

    enum RequestStatus: String, Codable {
        case pending
        case accepted
        case declined
    }

    // Explicit CodingKeys might not be needed with @DocumentID and matching property names
    // enum CodingKeys: String, CodingKey { ... }

    // Default initializer
    init(id: String? = nil, senderID: String, receiverID: String, status: RequestStatus = .pending, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.status = status
        self.createdAt = createdAt
         self.updatedAt = updatedAt ?? createdAt // Default updatedAt to createdAt
    }

    // Equatable conformance: Compare based on ID
    static func == (lhs: FriendRequestModel, rhs: FriendRequestModel) -> Bool {
        lhs.id == rhs.id && lhs.id != nil
    }
}

// Custom Error enum for FriendManagementViewModel specific errors
enum FriendManagementError: Error, LocalizedError {
    case requestAlreadySent
    case alreadyFriends
    case firestoreError(Error) // Wraps underlying Firestore errors
    case invalidRequestID
    case userNotLoggedIn
    case friendshipNotFound
    case invalidFriendRequestData
    case friendRequestNotPending
    case userNotFound // Added for user detail fetching
    case unknown // Fallback

    var errorDescription: String? {
        switch self {
        case .requestAlreadySent:
            return NSLocalizedString("friendManagement.error.requestAlreadySent", comment: "Error when friend request already exists")
        case .alreadyFriends:
            return NSLocalizedString("friendManagement.error.alreadyFriends", comment: "Error when users are already friends")
        case .firestoreError(let error):
            // Provide more context if possible
            return String(format: NSLocalizedString("friendManagement.error.firestore", comment: "Generic Firestore error"), error.localizedDescription)
        case .invalidRequestID:
            return NSLocalizedString("friendManagement.error.invalidRequestID", comment: "Error for invalid friend request ID")
        case .userNotLoggedIn:
            return NSLocalizedString("friendManagement.error.userNotLoggedIn", comment: "Error when user is not authenticated")
        case .friendshipNotFound:
            return NSLocalizedString("friendManagement.error.friendshipNotFound", comment: "Error when friendship record doesn't exist")
        case .invalidFriendRequestData:
            return NSLocalizedString("friendManagement.error.invalidFriendRequestData", comment: "Error decoding friend request")
        case .friendRequestNotPending:
            return NSLocalizedString("friendManagement.error.friendRequestNotPending", comment: "Error when trying to action a non-pending request")
        case .userNotFound:
             return NSLocalizedString("friendManagement.error.userNotFound", comment: "Error when user details cannot be fetched")
        case .unknown:
            return NSLocalizedString("friendManagement.error.unknown", comment: "Generic unknown error")
        }
    }
}


// MARK: - FriendManagementViewModel Class Definition

@MainActor // Ensure UI updates happen on the main thread
class FriendManagementViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequestModel] = [] // Received pending requests
    @Published var sentFriendRequests: [FriendRequestModel] = [] // Sent pending requests (optional, but useful)
    @Published var isLoading: Bool = false
    @Published var error: FriendManagementError? // Use the specific error type

    // Use the simplified service singletons directly
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private let authService = FirebaseAuthService.shared

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    // Non-isolated backing storage for listeners
    private var _friendsListener: ListenerRegistration?
    private var _receivedRequestsListener: ListenerRegistration?
    private var _sentRequestsListener: ListenerRegistration?

    // Computed properties removed. Access _friendsListener, etc. directly
    // within @MainActor contexts (like setup... methods) or via MainActor.run.

    // Debouncer for search queries
    private var searchDebouncer = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?
    @Published var searchResults: [User] = []
    @Published var isSearching: Bool = false

    // Combine cancellables
    private var cancellables = Set<AnyCancellable>()


    // Modified init to accept AuthViewModel
    init(authViewModel: AuthViewModel) {
        // Setup debouncer for search
        searchCancellable = searchDebouncer
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // 500ms debounce
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performUserSearch(query)
            }

        // Subscribe to AuthViewModel's user changes
        authViewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                if let user = user, let userId = user.id {
                    print("🔑 FriendManagementViewModel: AuthViewModel user updated (\(userId)), setting up listeners.")
                    self.setupListeners(for: userId)
                } else {
                    print("🔑 FriendManagementViewModel: AuthViewModel user is nil, removing listeners.")
                    // Call async removeListeners in a Task
                    Task {
                        await self.removeListeners()
                    }
                }
            }
            .store(in: &cancellables) // Store the subscription
    }

    deinit {
        // Clean up listeners and Combine subscriptions
        // Call the async removeListeners within a Task
        Task {
            await removeListeners()
        }
        cancellables.forEach { $0.cancel() }
        print("🗑️ FriendManagementViewModel deinitialized, listeners removed, and subscriptions cancelled.")
    }

    /// Removes all Firestore listeners and clears local data arrays.
    /// Marked nonisolated and async.
    nonisolated func removeListeners() async {
        // First capture the listeners in local variables from the non-isolated storage
        let localFriendsListener = await _friendsListener
        let localReceivedRequestsListener = await _receivedRequestsListener
        let localSentRequestsListener = await _sentRequestsListener

        // Remove the listeners (can be done from any actor context)
        localFriendsListener?.remove()
        localReceivedRequestsListener?.remove()
        localSentRequestsListener?.remove()

        // Now update the state on the main actor
        await MainActor.run { [weak self] in
             // Check if self still exists when the async block executes
             guard let self = self else { return }

            // Clear all listeners' backing storage
            self._friendsListener = nil
            self._receivedRequestsListener = nil
            self._sentRequestsListener = nil

            // Clear all data
            self.friends = []
            self.friendRequests = []
            self.sentFriendRequests = []
            self.searchResults = []
            self.isLoading = false
            self.error = nil

            print("👂 FriendManagementViewModel: Listeners removed and data cleared on MainActor.")
        }
    }

    // MARK: - Listener Setup

    func setupListeners(for userID: String) { // Implicitly @MainActor
        print("👂 Setting up listeners for user: \(userID)")
        // Ensure existing listeners are removed before creating new ones
        // Access backing storage directly, safe within @MainActor func
        _friendsListener?.remove()
        _receivedRequestsListener?.remove()
        _sentRequestsListener?.remove()

        setupFriendsListener(for: userID)
        setupReceivedRequestsListener(for: userID)
        setupSentRequestsListener(for: userID) // Setup listener for sent requests
    }

    private func setupFriendsListener(for userID: String) { // Implicitly @MainActor
        isLoading = true
        error = nil

        // Query the user's "friends" subcollection
        // Assign directly to backing storage, safe within @MainActor func
        _friendsListener = db.collection("users").document(userID).collection("friends")
            .addSnapshotListener { [weak self] snapshot, error in
                // Use Task with @MainActor for UI updates
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    print("👂 Friends subcollection listener update received.")

                    if let error = error {
                        print("❌ Error in friends subcollection listener: \(error.localizedDescription)")
                        self.error = .firestoreError(error)
                        self.isLoading = false // Stop loading on error
                        self.friends = [] // Clear on error
                        return
                    }

                    // Correctly handle the snapshot and extract friend IDs
                    guard let documents = snapshot?.documents else {
                        print("⚠️ Friends subcollection listener snapshot documents nil.")
                        self.isLoading = false // Stop loading if no documents
                        self.friends = [] // Clear friends if snapshot is nil
                        return
                    }

                    print("✅ Friends subcollection listener received \(documents.count) friend documents.")
                    // The document ID in the subcollection *is* the friend's ID
                    let friendIDs = documents.map { $0.documentID }

                    print("🙋 Friend IDs extracted from subcollection listener: \(friendIDs)")

                    // Check if friendIDs list is empty before fetching
                    if friendIDs.isEmpty {
                        print("ℹ️ No friend IDs found in subcollection, setting friends list to empty.")
                        self.friends = []
                        self.isLoading = false // Stop loading if no friends
                    } else {
                        // Fetch user details for these friend IDs (fetchUserDetails handles its own main thread updates)
                        // We still set isLoading = true here before calling fetchUserDetails
                        print("▶️ Calling fetchUserDetails for \(friendIDs.count) friend IDs...")
                        self.isLoading = true
                        self.fetchUserDetails(for: friendIDs)
                    }
                }
            }
    } // Correctly closes setupFriendsListener method

    private func setupReceivedRequestsListener(for userID: String) { // Implicitly @MainActor
         // Assign directly to backing storage, safe within @MainActor func
         _receivedRequestsListener = db.collection("friendRequests")
            .whereField("receiverID", isEqualTo: userID)
            .whereField("status", isEqualTo: FriendRequestModel.RequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true) // Order by creation time
            .addSnapshotListener { [weak self] snapshot, error in // Listener closure starts
                // Use Task with @MainActor for UI updates
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    print("👂 Received friend requests listener update received.")

                    if let error = error {
                        print("❌ Error in received friend requests listener: \(error.localizedDescription)")
                        self.error = .firestoreError(error)
                        // Don't set isLoading false here, let friends listener handle it
                        self.friendRequests = []
                        return
                    }

                    // Correctly placed guard let documents
                    guard let documents = snapshot?.documents else {
                        print("⚠️ Received friend requests listener snapshot documents nil.")
                        self.friendRequests = []
                        return
                    }

                    print("🔍 Received friend requests listener received \(documents.count) documents.")
                    self.friendRequests = documents.compactMap { doc in
                        try? doc.data(as: FriendRequestModel.self)
                    }
                } // End Task
            } // Listener closure ends
    } // Correctly closes setupReceivedRequestsListener

     private func setupSentRequestsListener(for userID: String) { // Implicitly @MainActor
         // Assign directly to backing storage, safe within @MainActor func
         _sentRequestsListener = db.collection("friendRequests")
            .whereField("senderID", isEqualTo: userID)
            .whereField("status", isEqualTo: FriendRequestModel.RequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                // Use Task with @MainActor for UI updates
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    print("👂 Sent friend requests listener update received.")

                    if let error = error {
                        print("❌ Error in sent friend requests listener: \(error.localizedDescription)")
                        // Consider if this error should be surfaced differently
                        self.error = .firestoreError(error)
                        self.sentFriendRequests = []
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        print("⚠️ Sent friend requests listener snapshot documents nil.")
                        self.sentFriendRequests = []
                        return
                    }

                    print("🔍 Sent friend requests listener received \(documents.count) documents.")
                    self.sentFriendRequests = documents.compactMap { doc in
                        try? doc.data(as: FriendRequestModel.self)
                    }
                } // End Task
            }
    }


    // MARK: - Friend Management Methods (Actions)

    /// Fetch user details for a list of user IDs
    private func fetchUserDetails(for userIDs: [String]) {
        print("➡️ Entering fetchUserDetails for IDs: \(userIDs)")
        // This function already uses DispatchGroup.notify(queue: .main) for final updates,
        // so it should be safe regarding main thread updates for self.friends and self.isLoading.

        // Guard moved down slightly to log entry even if userIDs is empty initially
        guard !userIDs.isEmpty else {
            // Ensure updates here are also on main thread if called from background
             print("ℹ️ fetchUserDetails called with empty IDs array. Setting friends list to empty and stopping loading.")
             // No need for DispatchQueue.main.async as this whole function should ideally run on @MainActor context
             // or the notify block handles main thread update. Let's ensure isLoading is handled.
             self.friends = [] // Clear friends immediately
             self.isLoading = false // Ensure loading stops
            return
        }

        // Use Firestore 'in' query, respecting the 30-element limit per query
        let chunks = userIDs.chunked(into: 30) // Firestore 'in' query limit is 30
        print("🔍 Fetching user details in \(chunks.count) chunks.")

        var fetchedUsers: [User] = []
        let group = DispatchGroup()
        var fetchError: FriendManagementError?

        for (index, chunk) in chunks.enumerated() {
            guard !chunk.isEmpty else { continue }
            print("🔍 Fetching chunk \(index + 1)/\(chunks.count): \(chunk)")
            group.enter()
            db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments { snapshot, error in
                defer { group.leave() }
                if let error = error {
                    print("❌ Error fetching user details chunk \(index + 1) (\(chunk)): \(error.localizedDescription)")
                    if fetchError == nil { fetchError = .firestoreError(error) }
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Snapshot documents nil for user details chunk \(index + 1) (\(chunk))")
                    return
                }
                print("✅ fetchUserDetails: Received \(documents.count) documents for chunk \(index + 1).")

                let usersInChunk = documents.compactMap { doc -> User? in
                    do {
                        // Manually assign ID here too, as this fetches the full User object
                        var user = try doc.data(as: User.self)
                        user.id = doc.documentID
                        print("  📄 fetchUserDetails: Parsed user: ID=\(user.id ?? "nil"), Name=\(user.name)")
                        // Ensure the ID is actually assigned before returning
                         guard user.id != nil else {
                             print("  ⚠️ fetchUserDetails: Parsed user but ID is still nil after assignment for doc \(doc.documentID). Skipping.")
                             return nil
                         }
                        return user
                    } catch {
                        print("❌ fetchUserDetails: Failed to decode User document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                // Append results safely (DispatchGroup ensures sequential execution of notify block)
                fetchedUsers.append(contentsOf: usersInChunk)
                print("📊 fetchUserDetails: Fetched users count after chunk \(index + 1): \(fetchedUsers.count)")
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                 print("🏁 fetchUserDetails group notify: self is nil, cannot update state.")
                 return
            }
            print("🏁 fetchUserDetails group notify block entered on main thread.")

            if let error = fetchError {
                print("❌ fetchUserDetails completed with error: \(error.localizedDescription)")
                self.error = error // Set the specific error
                // Decide on partial success: maybe show fetched users?
                // For now, clear friends on any error during fetch.
                self.friends = []
                print("📉 fetchUserDetails: Cleared friends list due to error.")
            } else {
                print("✅ fetchUserDetails: Fetched details successfully for \(fetchedUsers.count) potential users. Updating friends list.")
                // Deduplication might not be strictly needed if userIDs are unique, but good practice.
                // Let's ensure the dictionary uses the non-nil ID.
                 var uniqueUsersDict: [String: User] = [:]
                 for user in fetchedUsers {
                     if let id = user.id { // Ensure ID is not nil here
                         uniqueUsersDict[id] = user
                     } else {
                          print("⚠️ fetchUserDetails: Skipping user in final list assembly due to nil ID.")
                     }
                 }
                let finalFriends = Array(uniqueUsersDict.values).sorted { $0.name < $1.name }
                self.friends = finalFriends // Update the published property
                print("✅ fetchUserDetails: Final friends list count: \(self.friends.count). Assigned to @Published var.")
                // Print names for verification
                 if !self.friends.isEmpty {
                     print("   Friends: \(self.friends.map { $0.name })")
                 }
                self.error = nil // Clear previous errors on success
            }
            self.isLoading = false // Ensure isLoading is set false
            print("🏁 fetchUserDetails: isLoading set to false.")
        }
    }


    /// Send a friend request to another user
    func sendFriendRequest(to recipientID: String) async throws {
        guard let senderID = authService.currentUser?.uid else { // Use authService
            throw FriendManagementError.userNotLoggedIn
        }

        // Prevent sending request to self
        guard senderID != recipientID else {
             print("⚠️ Attempted to send friend request to self.")
             // Optionally throw a specific error or handle silently
             return // Or throw an error like .cannotAddSelf
        }


        isLoading = true
        defer { isLoading = false } // Ensure isLoading is reset

        do {
            // 1. Check if already friends
            let areFriends = try await checkIfFriends(userID1: senderID, userID2: recipientID)
            if areFriends {
                throw FriendManagementError.alreadyFriends
            }

            // 2. Check if a request already exists (either direction, pending status)
            let requestExists = try await checkExistingFriendRequest(senderID: senderID, receiverID: recipientID)
            if requestExists {
                throw FriendManagementError.requestAlreadySent
            }

            // 3. Create the new friend request document
            let newRequest = FriendRequestModel(senderID: senderID, receiverID: recipientID)
            // Get the document reference when adding
            let docRef = try db.collection("friendRequests").addDocument(from: newRequest)

            print("✅ Friend request sent successfully from \(senderID) to \(recipientID)")
            error = nil // Clear error on success

            // 4. Create notification for the recipient
            await NotificationService.shared.notifyFriendRequestSent(
                senderID: senderID,
                recipientID: recipientID,
                requestID: docRef.documentID // Pass the actual request ID
            )

        } catch let error as FriendManagementError {
            print("❌ Error sending friend request: \(error.localizedDescription)")
            self.error = error
            throw error // Re-throw the specific error
        } catch {
            print("❌ Unexpected error sending friend request: \(error.localizedDescription)")
            let specificError = FriendManagementError.firestoreError(error)
            self.error = specificError
            throw specificError // Throw the wrapped error
        }
    }

    /// Respond to a received friend request (accept or decline)
    func respondToFriendRequest(request: FriendRequestModel, accept: Bool) async throws {
        guard let requestID = request.id else {
            throw FriendManagementError.invalidRequestID
        }
        guard request.status == .pending else {
            throw FriendManagementError.friendRequestNotPending
        }
        guard let currentUserID = authService.currentUser?.uid, currentUserID == request.receiverID else { // Use authService
             print("❌ Attempted to respond to a request not addressed to the current user or user not logged in.")
             throw FriendManagementError.userNotLoggedIn // Or a more specific permission error
        }


        isLoading = true
        defer { isLoading = false }

        let newStatus: FriendRequestModel.RequestStatus = accept ? .accepted : .declined
        let requestRef = db.collection("friendRequests").document(requestID)

        do {
            // Use a batch write for atomicity
            let batch = db.batch()

            // Update the request status
            batch.updateData([
                "status": newStatus.rawValue,
                "updatedAt": Timestamp(date: Date())
            ], forDocument: requestRef)

            // If accepting, add entries to both users' friends subcollections
            if accept {
                let friendSince = Timestamp(date: Date())
                // Add receiver (current user) to sender's friends list
                let senderFriendRef = db.collection("users").document(request.senderID).collection("friends").document(currentUserID)
                batch.setData(["friendSince": friendSince], forDocument: senderFriendRef)

                // Add sender to receiver's (current user's) friends list
                let receiverFriendRef = db.collection("users").document(currentUserID).collection("friends").document(request.senderID)
                batch.setData(["friendSince": friendSince], forDocument: receiverFriendRef)
            }

            // Commit the batch
            try await batch.commit()

            print("✅ Successfully responded to friend request \(requestID) with status: \(newStatus.rawValue)")
            error = nil // Clear error on success

            // Note: Listeners should automatically update the local `friendRequests` and `friends` arrays.
            // Manual removal is not strictly necessary if listeners are working correctly.
            // self.friendRequests.removeAll { $0.id == requestID }
            // if accept { self.fetchFriends(for: currentUserID) } // Listener handles this

        } catch {
            print("❌ Error responding to friend request \(requestID): \(error.localizedDescription)")
            let specificError = FriendManagementError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }

    /// Cancel a friend request that the current user sent
    func cancelFriendRequest(request: FriendRequestModel) async throws {
         guard let requestID = request.id else {
            throw FriendManagementError.invalidRequestID
        }
         guard request.status == .pending else {
             // Or handle silently if desired
             print("⚠️ Attempted to cancel a non-pending request: \(requestID)")
             return
         }
         guard let currentUserID = authService.currentUser?.uid, currentUserID == request.senderID else { // Use authService
             print("❌ Attempted to cancel a request not sent by the current user or user not logged in.")
             throw FriendManagementError.userNotLoggedIn // Or a more specific permission error
         }

        isLoading = true
        defer { isLoading = false }

        let requestRef = db.collection("friendRequests").document(requestID)

        do {
            try await requestRef.delete()
            print("✅ Successfully cancelled sent friend request \(requestID)")
            error = nil // Clear error on success
            // Listener should update sentFriendRequests automatically
            // self.sentFriendRequests.removeAll { $0.id == requestID }
        } catch {
            print("❌ Error cancelling friend request \(requestID): \(error.localizedDescription)")
            let specificError = FriendManagementError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }


    /// Remove a friendship between the current user and another user
    func removeFriend(friendId: String) async throws {
        guard let currentUserId = authService.currentUser?.uid else { // Use authService
            throw FriendManagementError.userNotLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        // References to the friend entries in both users' subcollections
        let currentUserFriendRef = db.collection("users").document(currentUserId).collection("friends").document(friendId)
        let friendUserRef = db.collection("users").document(friendId).collection("friends").document(currentUserId)

        // Use a batch write to delete both entries atomically
        let batch = db.batch()
        batch.deleteDocument(currentUserFriendRef)
        batch.deleteDocument(friendUserRef)

        do {
            try await batch.commit()
            print("✅ Successfully removed friend \(friendId) from both users' lists.")
            error = nil // Clear error on success
            // Listener should update friends list automatically
            // self.friends.removeAll { $0.id == friendId }
        } catch {
            print("❌ Error removing friendship with \(friendId): \(error.localizedDescription)")
            let specificError = FriendManagementError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }


    // MARK: - User Search

    /// Initiates a user search via the debouncer
    func searchUsersDebounced(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            self.searchResults = []
            self.isSearching = false
        } else {
            self.isSearching = true
            searchDebouncer.send(trimmedQuery)
        }
    }

    /// Performs the actual user search against Firestore
    @MainActor // Ensure state updates are on the main thread
    private func performUserSearch(_ query: String) {
        print("🔍 [FriendManagementViewModel] Performing user search for query: '\(query)'")
        // Clear previous search error
        self.error = nil
        // Ensure isSearching is true at the start
        self.isSearching = true

        guard let currentUserID = authService.currentUser?.uid else { // Use authService
            print("⚠️ [FriendManagementViewModel] Cannot search users, user not logged in.")
            self.isSearching = false
            self.searchResults = []
            self.error = .userNotLoggedIn // Set error state
            return
        }
        print("🔍 [FriendManagementViewModel] Current User ID: \(currentUserID)")

        let lowercasedQuery = query.lowercased()
        let group = DispatchGroup()
        var nameResults: [User] = []
        var emailResults: [User] = []
        var nameSearchError: Error?
        var emailSearchError: Error?

        // --- Name Search ---
        print("🔍 [FriendManagementViewModel] Starting NAME search query...")
        group.enter()
        let nameQueryRef = db.collection("users")
            .whereField("name_lowercase", isGreaterThanOrEqualTo: lowercasedQuery)
            .whereField("name_lowercase", isLessThanOrEqualTo: lowercasedQuery + "\u{f8ff}")
            .limit(to: 10)

        nameQueryRef.getDocuments { snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ [FriendManagementViewModel] NAME search Firestore error: \(error.localizedDescription)")
                // Check specifically for index error hint
                if error.localizedDescription.contains("index") {
                     print("👉 Firestore Index Hint: Check the console/Firebase UI for index creation links/prompts related to 'users' collection and 'name_lowercase' field.")
                }
                nameSearchError = error
            } else if let documents = snapshot?.documents {
                print("✅ [FriendManagementViewModel] NAME search completed. Found \(documents.count) potential documents.")
                nameResults = documents.compactMap { doc -> User? in
                    do {
                        // Decode first, then manually assign ID
                        var user = try doc.data(as: User.self)
                        user.id = doc.documentID // Explicitly assign the document ID
                        print("  📄 Parsed user (name search): ID=\(user.id ?? "nil"), Name=\(user.name)")
                        return user
                    } catch {
                        print("  ⚠️ Failed to parse user document \(doc.documentID) during name search: \(error)")
                        return nil
                    }
                }
            } else {
                 print("⚠️ [FriendManagementViewModel] NAME search returned nil snapshot/documents.")
            }
        }

        // --- Email Search ---
        print("🔍 [FriendManagementViewModel] Starting EMAIL search query...")
        group.enter()
        let emailQueryRef = db.collection("users")
            .whereField("email", isEqualTo: lowercasedQuery)
            .limit(to: 1)

        emailQueryRef.getDocuments { snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ [FriendManagementViewModel] EMAIL search Firestore error: \(error.localizedDescription)")
                 // Check specifically for index error hint
                 if error.localizedDescription.contains("index") {
                      print("👉 Firestore Index Hint: Check the console/Firebase UI for index creation links/prompts related to 'users' collection and 'email' field.")
                 }
                emailSearchError = error
            } else if let documents = snapshot?.documents {
                print("✅ [FriendManagementViewModel] EMAIL search completed. Found \(documents.count) potential documents.")
                emailResults = documents.compactMap { doc -> User? in
                     do {
                         // Decode first, then manually assign ID
                         var user = try doc.data(as: User.self)
                         user.id = doc.documentID // Explicitly assign the document ID
                         print("  📄 Parsed user (email search): ID=\(user.id ?? "nil"), Email=\(user.email)")
                         return user
                     } catch {
                         print("  ⚠️ Failed to parse user document \(doc.documentID) during email search: \(error)")
                         return nil
                     }
                 }
            } else {
                 print("⚠️ [FriendManagementViewModel] EMAIL search returned nil snapshot/documents.")
            }
        }

        // --- Process Results ---
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            print("🔍 [FriendManagementViewModel] Processing search results on main thread...")
            // Ensure isSearching is set to false on completion
            self.isSearching = false

            // Combine errors if necessary
            if let nameErr = nameSearchError, let emailErr = emailSearchError {
                 print("❌ [FriendManagementViewModel] Both NAME and EMAIL searches failed.")
                 // Decide which error to prioritize or combine them
                 self.error = .firestoreError(nameErr) // Prioritize name error for now
                 self.searchResults = []
                 return
             } else if let error = nameSearchError ?? emailSearchError {
                 print("❌ [FriendManagementViewModel] One of the searches failed: \(error.localizedDescription)")
                 self.error = .firestoreError(error)
                 self.searchResults = []
                 return
             }

            // Combine and deduplicate results
            var combinedResults = nameResults + emailResults
            var uniqueResults: [User] = []
            var seenIds = Set<String>()
            print("🔍 [FriendManagementViewModel] Deduplicating \(combinedResults.count) raw results...")
            for user in combinedResults {
                if let id = user.id, id != currentUserID, !seenIds.contains(id) {
                    uniqueResults.append(user)
                    seenIds.insert(id)
                    print("  👍 Keeping unique user: ID=\(id), Name=\(user.name)")
                } else if let id = user.id, id == currentUserID {
                     print("  🙅‍♀️ Filtering out current user: ID=\(id)")
                } else if let id = user.id, seenIds.contains(id) {
                     print("  🙅‍♀️ Filtering out duplicate user: ID=\(id)")
                } else {
                     print("  ⚠️ Filtering out user with nil ID.")
                }
            }

            // Assign final results
            self.searchResults = uniqueResults.sorted { $0.name < $1.name }
            print("✅ [FriendManagementViewModel] User search completed. Final results count: \(self.searchResults.count) for query '\(query)'")
            // Clear error if search was successful overall
            self.error = nil
        }
    }


    // MARK: - Status Checks (Computed Properties/Functions)

    /// Check friendship status with a specific user ID.
    func friendshipStatus(with userId: String) -> FriendshipStatus {
        guard let currentUserId = authService.currentUser?.uid else { return .notLoggedIn } // Use authService
        if userId == currentUserId { return .isSelf }

        if friends.contains(where: { $0.id == userId }) {
            return .friends
        }
        if sentFriendRequests.contains(where: { $0.receiverID == userId }) {
            return .requestSent
        }
        if friendRequests.contains(where: { $0.senderID == userId }) {
            // Find the specific request to pass to the view if needed
            if let request = friendRequests.first(where: { $0.senderID == userId }) {
                 return .requestReceived(request)
            } else {
                 // Should not happen if the contains check passed, but handle defensively
                 return .notFriends
            }
        }
        return .notFriends
    }

    // Enum to represent friendship status clearly in the UI
    // Ensure it's defined INSIDE the FriendManagementViewModel class scope
    enum FriendshipStatus: Equatable {
        case friends
        case requestSent
        case requestReceived(FriendRequestModel) // Include the request object
        case notFriends
        case isSelf
        case notLoggedIn

        // Equatable implementation for enum with associated value
        static func == (lhs: FriendManagementViewModel.FriendshipStatus, rhs: FriendManagementViewModel.FriendshipStatus) -> Bool {
            switch (lhs, rhs) {
            case (.friends, .friends):
                return true
            case (.requestSent, .requestSent):
                return true
            case (.requestReceived(let lhsRequest), .requestReceived(let rhsRequest)):
                // Compare the associated FriendRequestModel objects (requires FriendRequestModel to be Equatable)
                return lhsRequest == rhsRequest
            case (.notFriends, .notFriends):
                return true
            case (.isSelf, .isSelf):
                return true
            case (.notLoggedIn, .notLoggedIn):
                return true
            default:
                // All other combinations are not equal
                return false
            }
        }
    }
    // MARK: - Private Helper Methods

    /// Checks if a friend request already exists between two users (in either direction).
    private func checkExistingFriendRequest(senderID: String, receiverID: String) async throws -> Bool {
        let query1 = db.collection("friendRequests")
            .whereField("senderID", isEqualTo: senderID)
            .whereField("receiverID", isEqualTo: receiverID)
            .whereField("status", isEqualTo: FriendRequestModel.RequestStatus.pending.rawValue)
            .limit(to: 1) // We only need to know if at least one exists

        let query2 = db.collection("friendRequests")
            .whereField("senderID", isEqualTo: receiverID)
            .whereField("receiverID", isEqualTo: senderID)
            .whereField("status", isEqualTo: FriendRequestModel.RequestStatus.pending.rawValue)
            .limit(to: 1)

        do {
            let snapshot1 = try await query1.getDocuments()
            if !snapshot1.isEmpty { return true }

            let snapshot2 = try await query2.getDocuments()
            if !snapshot2.isEmpty { return true }

            return false
        } catch {
            print("❌ Error checking existing friend request: \(error.localizedDescription)")
            throw FriendManagementError.firestoreError(error)
        }
    }

    /// Checks if two users are already friends by checking the friends subcollection.
    private func checkIfFriends(userID1: String, userID2: String) async throws -> Bool {
        // Check if userID2 exists in userID1's friends subcollection
        let friendDocRef = db.collection("users").document(userID1).collection("friends").document(userID2)

        do {
            let snapshot = try await friendDocRef.getDocument()
            return snapshot.exists // If the document exists, they are friends
        } catch {
            // Handle specific errors like permission denied if necessary
            print("❌ Error checking friendship status: \(error.localizedDescription)")
            throw FriendManagementError.firestoreError(error)
        }
    }


    /// Helper to create a consistent chat/friendship ID for two users.
    private func getChatID(userID1: String, userID2: String) -> String {
        // Ensure consistent ordering for the ID
        let sortedIDs = [userID1, userID2].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }

} // Closes FriendManagementViewModel class
