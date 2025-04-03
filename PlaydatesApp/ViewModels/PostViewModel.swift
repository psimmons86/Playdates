import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift // For Codable support
import Combine
import SwiftUI // For @MainActor, @Published

// Custom Error enum for PostViewModel
// Add Equatable conformance
enum PostError: Error, LocalizedError, Equatable {
    case firestoreError(Error)
    case userNotLoggedIn
    case failedToFetchPosts
    case failedToCreatePost
    case failedToLikePost
    case postNotFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .firestoreError(let error):
            return "Database error: \(error.localizedDescription)"
        case .userNotLoggedIn:
            return "You must be logged in to interact with posts."
        case .failedToFetchPosts:
            return "Failed to load posts."
        case .failedToCreatePost:
            return "Failed to create post."
        case .failedToLikePost:
            return "Failed to update like status."
        case .postNotFound:
            return "Post not found."
        case .unknown:
            return "An unknown post error occurred."
        }
    }

    // Manual implementation of Equatable due to associated value Error not being Equatable
    static func == (lhs: PostError, rhs: PostError) -> Bool {
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
        case (.failedToFetchPosts, .failedToFetchPosts):
            return true
        case (.failedToCreatePost, .failedToCreatePost):
            return true
        case (.failedToLikePost, .failedToLikePost):
            return true
        case (.postNotFound, .postNotFound):
            return true
        case (.unknown, .unknown):
            return true
        default:
            // Cases are different or associated values differ
            return false
        }
    }
}

@MainActor
class PostViewModel: ObservableObject {
    @Published var posts: [UserPost] = []
    @Published var isLoading: Bool = false
    @Published var error: PostError?

    // Use service singletons
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private let authService = FirebaseAuthService.shared

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    private var postsListener: ListenerRegistration?
    private var userViewModelCache: [String: User] = [:] // Cache for user details

    init() {
        // Fetch posts on initialization
        // In a real app, you might fetch posts based on friends, etc.
        // For now, fetch all posts ordered by date.
        setupPostsListener()
    }

    deinit {
        postsListener?.remove()
        print("🗑️ PostViewModel deinitialized and listener removed.")
    }

    // MARK: - Listener Setup

    func setupPostsListener() {
        isLoading = true
        error = nil
        postsListener?.remove() // Remove previous listener

        print("👂 Setting up posts listener.")

        let postsQuery = db.collection("posts")
                           .order(by: "createdAt", descending: true)
                            .limit(to: 50) // Limit the number of posts fetched initially

        postsListener = postsQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            // Ensure UI updates are on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("👂 Posts listener update received.")

                // Stop loading indicator once data (or error) is received
                self.isLoading = false

                if let error = error {
                    print("❌ Error fetching posts: \(error.localizedDescription)")
                    self.error = .firestoreError(error)
                    // self.posts = [] // Optionally clear posts on error
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Posts snapshot documents nil.")
                    // self.posts = [] // Optionally clear posts if snapshot is nil
                    return
                }

                print("🔍 Posts listener received \(documents.count) documents.")
                // Use documentChanges for efficient updates if needed, or simply map
                self.posts = documents.compactMap { doc -> UserPost? in
                    try? doc.data(as: UserPost.self)
                }

                // Fetch user details for the posts after posts are loaded (fetchUserDetails handles its own main thread updates)
                self.fetchUserDetailsForPosts()

                // Clear error on success
                self.error = nil
            } // End DispatchQueue.main.async
        }
    }

    // MARK: - Post Actions

    func createPost(text: String, imageURL: String? = nil) async {
        guard let userID = authService.currentUser?.uid else { // Use authService
            // Ensure error update is on main thread
            self.error = .userNotLoggedIn
            return
        }

        // Ensure isLoading update is on main thread
        self.isLoading = true
        self.error = nil

        let newPost = UserPost(
            userID: userID,
            text: text,
            imageURL: imageURL,
            createdAt: Date() // Client-side date, consider server timestamp
        )

        do {
            // Add post to Firestore. Using `addDocument(from:)` automatically handles Codable.
            _ = try await db.collection("posts").addDocument(from: newPost)
            // Update state on main thread after await
            self.isLoading = false
            print("✅ Post created successfully.")
            // No need to manually add to `posts` array, listener will pick it up.
        } catch {
            // Update state on main thread after await
            self.isLoading = false
            print("❌ Failed to create post: \(error.localizedDescription)")
            self.error = .failedToCreatePost
        }
        // isLoading = false // Already set in do/catch blocks
    }

    func toggleLike(for post: UserPost) async {
        guard let userID = authService.currentUser?.uid else { // Use authService
            // Ensure error update is on main thread
            self.error = .userNotLoggedIn
            return
        }
        guard let postID = post.id else {
            // Ensure error update is on main thread
            self.error = .postNotFound
            return
        }

        // No need to set isLoading here unless it's a longer operation,
        // but ensure error is cleared on main thread if needed.
        // self.error = nil // Clear previous like errors if desired

        let postRef = db.collection("posts").document(postID)
        let alreadyLiked = post.likes.contains(userID)

        print("👍 Toggling like for post \(postID) by user \(userID). Currently liked: \(alreadyLiked)")

        do {
            if alreadyLiked {
                // Atomically remove user ID from likes array
                try await postRef.updateData([
                    "likes": FieldValue.arrayRemove([userID])
                ])
                print("💔 Unliked post \(postID)")
            } else {
                // Atomically add user ID to likes array
                try await postRef.updateData([
                    "likes": FieldValue.arrayUnion([userID])
                ])
                print("❤️ Liked post \(postID)")
            }
            // Listener should update the local post data.
            // Clear error on success (on main thread)
            self.error = nil
        } catch {
            // Update error on main thread after await
            print("❌ Failed to toggle like for post \(postID): \(error.localizedDescription)")
            self.error = .failedToLikePost
        }
    }

    // MARK: - User Details Fetching

    /// Fetches user details for the authors of the current posts, using a simple cache.
    private func fetchUserDetailsForPosts() {
        let userIDs = Set(posts.map { $0.userID })
        let idsToFetch = userIDs.filter { userViewModelCache[$0] == nil }

        guard !idsToFetch.isEmpty else {
            print("ℹ️ No new user details to fetch for posts.")
            return
        }

        print("👤 Fetching user details for post authors: \(idsToFetch)")
        let usersRef = db.collection("users")

        // Use 'in' query, chunking if necessary (limit 30)
        let chunks = Array(idsToFetch).chunked(into: 30)
        for chunk in chunks {
            guard !chunk.isEmpty else { continue }
            usersRef.whereField(FieldPath.documentID(), in: chunk).getDocuments { [weak self] (snapshot, error) in
                // Ensure cache updates happen on the main thread
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error {
                        print("❌ Error fetching user details chunk for posts: \(error.localizedDescription)")
                        // Handle error appropriately, maybe set a general user fetch error
                        // self.error = .firestoreError(error) // Avoid overwriting other errors potentially
                        return
                    }
                    guard let documents = snapshot?.documents else { return }

                    for document in documents {
                        if let user = try? document.data(as: User.self) {
                            // Update cache on the main thread
                            self.userViewModelCache[document.documentID] = user
                            print("👤 Cached user: \(user.name)")
                            // Trigger UI update if necessary by modifying a @Published property
                            // or ensure views observe the cache reactively if possible.
                            // Forcing an update like this is often a sign the data flow could be improved,
                            // but can work as a temporary measure.
                            self.objectWillChange.send()
                        }
                    }
                } // End DispatchQueue.main.async
            }
        }
    }

    /// Retrieves a cached user or returns nil. Views should call this.
    func getUser(for userID: String) -> User? {
        return userViewModelCache[userID]
    }
} // Closes PostViewModel class
