import Foundation
import Firebase
import FirebaseFirestore
import Combine
import FirebaseAuth // Needed for Auth

// Make AppActivityViewModel require dependencies for proper initialization
@MainActor // Mark the entire class as running on the Main Actor
class AppActivityViewModel: ObservableObject {
    @Published var activities: [AppActivity] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let authViewModel: AuthViewModel // Dependency
    private let friendManagementViewModel: FriendManagementViewModel // Dependency
    private var friendsListenerCancellable: AnyCancellable? // To react to friend list changes

    // Remove static shared instance - dependencies need to be injected
    // static let shared = AppActivityViewModel()

    // Initializer requiring dependencies
    init(authViewModel: AuthViewModel, friendManagementViewModel: FriendManagementViewModel) {
        self.authViewModel = authViewModel
        self.friendManagementViewModel = friendManagementViewModel
        print("🚀 AppActivityViewModel initialized.")

        // Observe changes in the user's friends list to refetch activities
        friendsListenerCancellable = friendManagementViewModel.$friends
            .dropFirst() // Ignore the initial value
            .sink { [weak self] _ in
                print("👥 Friend list changed, refetching activities.")
                // Wrap async call in Task
                Task {
                    await self?.fetchActivities()
                }
            }

        // Fetch initial activities when the user logs in
        authViewModel.$user
            .sink { [weak self] user in
                if user != nil {
                    print("👤 User logged in, fetching initial activities.")
                    // Wrap async call in Task
                    Task {
                        await self?.fetchActivities()
                    }
                } else {
                    print("👤 User logged out, clearing activities.")
                    // Clear activities when user logs out
                    self?.activities = []
                    self?.error = nil
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        print("🗑️ AppActivityViewModel deinitialized.")
        cancellables.forEach { $0.cancel() }
        friendsListenerCancellable?.cancel()
    }

    // Updated fetchActivities to fetch for user and friends - MARK AS ASYNC
    func fetchActivities(limit: Int = 30) async { // Increased limit slightly
        guard let currentUserID = authViewModel.user?.id else {
            print("⚠️ AppActivityViewModel: Cannot fetch activities, user not logged in.")
            self.activities = [] // Clear activities if user logs out during fetch
            self.error = "User not logged in."
            self.isLoading = false
            return
        }

        // Get friend IDs (ensure this is accessed on the main thread if needed, though @Published should handle it)
        let friendIDs = friendManagementViewModel.friends.compactMap { $0.id }
        print("🔍 Fetching activities for user \(currentUserID) and \(friendIDs.count) friends.")

        // Combine user ID and friend IDs for querying
        var userAndFriendIDs = friendIDs
        userAndFriendIDs.append(currentUserID)

        // No need for explicit Task { @MainActor in ... } wrapper anymore,
        // as the whole function is now implicitly @MainActor.
        self.isLoading = true
        self.error = nil
        var combinedActivities: [AppActivity] = []
            var fetchError: Error? = nil

            // Firestore 'in' query limit is 30
            let chunks = userAndFriendIDs.chunked(into: 30)
            print("Firestore 'in' query will run in \(chunks.count) chunk(s).")

            // Use a DispatchGroup or async let to run queries concurrently
            await withTaskGroup(of: Result<[AppActivity], Error>.self) { group in
                for chunk in chunks {
                    if chunk.isEmpty { continue } // Skip empty chunks

                    group.addTask {
                        do {
                            let snapshot = try await self.db.collection("activities")
                                .whereField("userID", in: chunk)
                                // Add ordering and limit *within* the chunk query
                                .order(by: "timestamp", descending: true)
                                .limit(to: limit) // Apply limit per chunk query
                                .getDocuments()

                            let activitiesInChunk = snapshot.documents.compactMap { doc -> AppActivity? in
                                try? doc.data(as: AppActivity.self)
                            }
                            print("Fetched \(activitiesInChunk.count) activities for chunk: \(chunk)")
                            return .success(activitiesInChunk)
                        } catch {
                            print("❌ Error fetching activity chunk: \(error.localizedDescription)")
                            return .failure(error)
                        }
                    }
                }

                // Collect results from all tasks
                for await result in group {
                    switch result {
                    case .success(let activitiesInChunk):
                        combinedActivities.append(contentsOf: activitiesInChunk)
                    case .failure(let error):
                        // Capture the first error encountered
                        if fetchError == nil {
                            fetchError = error
                        }
                    }
                }
            } // End of withTaskGroup

            // Process results (already on main actor)
            self.isLoading = false
            if let error = fetchError {
                self.error = error.localizedDescription
                print("❌ Error fetching activities: \(error.localizedDescription)")
                // Keep existing activities on error? Or clear? Clearing for now.
                self.activities = []
            } else {
                // Deduplicate and sort the combined results
                // Using a Set for deduplication based on ID
                var uniqueActivitiesDict: [String: AppActivity] = [:]
                for activity in combinedActivities {
                    if let id = activity.id {
                        // If activity already exists, keep the one already there (arbitrary choice)
                        if uniqueActivitiesDict[id] == nil {
                            uniqueActivitiesDict[id] = activity
                        }
                    }
                }

                // Sort the unique activities by timestamp descending
                let sortedActivities = Array(uniqueActivitiesDict.values)
                    .sorted { $0.timestamp > $1.timestamp }

                // Apply the overall limit *after* combining and sorting
                self.activities = Array(sortedActivities.prefix(limit))

                print("✅ Successfully fetched and combined activities. Final count: \(self.activities.count)")
                self.error = nil // Clear error on success
            }
        // } // Removed Task wrapper
    }
    
    // Create a new activity and save it to Firestore
    func createActivity(type: AppActivityType, 
                        title: String, 
                        description: String, 
                        userID: String, 
                        userName: String, 
                        userProfileImageURL: String? = nil,
                        playdateID: String? = nil,
                        commentID: String? = nil,
                        groupID: String? = nil,
                        postID: String? = nil,
                        eventID: String? = nil,
                        resourceID: String? = nil,
                        childID: String? = nil,
                        contentImageURL: String? = nil, // Added parameter
                        likeCount: Int = 0,             // Added parameter
                        commentCount: Int = 0,          // Added parameter
                        completion: ((Bool) -> Void)? = nil) {
        
        let activity = AppActivity(
            id: nil, // Explicitly set id to nil for Firestore to generate
            type: type,
            title: title,
            description: description,
            timestamp: Date(),
            userID: userID,
            userName: userName,
            userProfileImageURL: userProfileImageURL,
            playdateID: playdateID,
            commentID: commentID,
            groupID: groupID,
            postID: postID,
            eventID: eventID,
            resourceID: resourceID,
            childID: childID,
            contentImageURL: contentImageURL, // Pass new parameter
            likeCount: likeCount,             // Pass new parameter
            commentCount: commentCount        // Pass new parameter
            // isLiked is client-side, not set at creation
        )
        
        do {
            let _ = try db.collection("activities").addDocument(from: activity)
            
            // Add to local activities list
            DispatchQueue.main.async {
                self.activities.insert(activity, at: 0)
            }
            
            completion?(true)
        } catch {
            self.error = error.localizedDescription
            completion?(false)
        }
    }
}
