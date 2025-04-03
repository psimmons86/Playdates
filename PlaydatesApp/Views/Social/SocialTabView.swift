import SwiftUI
import Firebase

// Enum to manage the selected social section
enum SocialSection: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case friends = "Friends"
    case messages = "Messages"
    var id: String { self.rawValue }
}

struct SocialTabView: View {
    // Inject necessary ViewModels
    @EnvironmentObject var friendManager: FriendManagementViewModel
    @StateObject private var postViewModel = PostViewModel()
    @StateObject private var chatViewModel = ChatViewModel() // Add ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    // Private struct to make error messages identifiable for the .alert(item:) modifier
    private struct AlertError: Identifiable {
        let id = UUID()
        let message: String
    }

    @State private var selectedSection: SocialSection = .feed // State for picker
    @State private var showingAddFriendSheet = false
    @State private var showingCreatePostSheet = false
    @State private var alertError: AlertError? // Use the identifiable error struct

    var body: some View {
        // REMOVED inner NavigationView wrapper
        VStack(spacing: 0) {
            // Segmented Picker to switch sections
            Picker("Section", selection: $selectedSection) {
                    ForEach(SocialSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 5) // Add some space below picker

                // Conditionally display content based on selection
                switch selectedSection {
                case .feed:
                    feedSection
                case .friends:
                    friendsSection
                case .messages:
                    messagesSection
                }
            }
            .navigationTitle("Social") // More general title
            .navigationBarTitleDisplayMode(.inline) // Keep title inline with picker
            .toolbar {
                // Keep buttons accessible regardless of section for now
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingCreatePostSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFriendSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(ColorTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView(isPresented: $showingAddFriendSheet)
                    .environmentObject(friendManager)
                    .environmentObject(authViewModel) // Add missing authViewModel
            }
            .sheet(isPresented: $showingCreatePostSheet) {
                CreatePostView(postViewModel: postViewModel)
            }
            // Use .alert(item:) with the identifiable AlertError
            .alert(item: $alertError) { currentAlert in
                Alert(
                    title: Text("Error"),
                    message: Text(currentAlert.message),
                    dismissButton: .default(Text("OK")) {
                        // Optionally clear the source errors when dismissed
                        postViewModel.error = nil
                        chatViewModel.error = nil
                    }
                )
            }
        // REMOVED .navigationViewStyle(StackNavigationViewStyle()) as NavigationView was removed
        // Monitor errors from view models and update alertError
        .onChange(of: postViewModel.error) { newError in
            if let error = newError {
                alertError = AlertError(message: error.localizedDescription)
            }
        }
        .onChange(of: chatViewModel.error) { newError in
             if let error = newError {
                 alertError = AlertError(message: error.localizedDescription)
             }
        }
    }

    // MARK: - Section Views

    private var feedSection: some View {
        List {
            // Button to trigger Create Post Sheet (can be placed elsewhere too)
            Button {
                showingCreatePostSheet = true
            } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Write a post...")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                if postViewModel.isLoading {
                    ProgressView()
                } else if postViewModel.posts.isEmpty {
                    Text("No posts yet. Be the first!")
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(postViewModel.posts) { post in
                        PostRow(post: post, postViewModel: postViewModel) // Use a dedicated row view
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)) // Adjust insets
                    }
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: .infinity) // Allow posts list to take available space
    }

    private var friendsSection: some View {
        // Integrate the existing FriendsView
        FriendsView()
            .environmentObject(friendManager) // Pass the necessary ViewModel
            .frame(maxHeight: .infinity)
    }

    private var messagesSection: some View {
        // Integrate the ConversationsListView for messaging
        ConversationsListView()
            .environmentObject(chatViewModel) // Pass the ChatViewModel
            .frame(maxHeight: .infinity)
    }
}

// Simple Row View for displaying a post
// NOTE: The duplicated PostRow struct and subsequent duplicated modifiers
// have been removed by this replace operation.
// The correct PostRow struct definition remains below.
struct PostRow: View {
    let post: UserPost
    @ObservedObject var postViewModel: PostViewModel // To get user details and handle likes
    @State private var author: User? = nil
    @State private var isLiked: Bool = false // Local state for like button
    @EnvironmentObject var authViewModel: AuthViewModel // To get current user ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ProfileImageView(imageURL: author?.profileImageURL, size: 40)
                VStack(alignment: .leading) {
                    Text(author?.name ?? "Loading...")
                        .font(.headline)
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                // TODO: Add options menu (delete, report, etc.)
            }

            Text(post.text)
                .font(.body)
                .lineLimit(nil) // Allow multiple lines

            // TODO: Display image if post.imageURL exists

            HStack {
                Button {
                    Task {
                        await postViewModel.toggleLike(for: post)
                        // Update local state immediately for responsiveness
                        if let currentUserID = authViewModel.user?.id {
                             isLiked = post.likes.contains(currentUserID) // Check updated likes
                        }
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                Text("\(post.likes.count) Likes")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()
                // TODO: Add comment button/count
            }
            .padding(.top, 5)
        }
        .padding() // Add padding around the content
        .background(Color.white) // Give it a background
        .cornerRadius(10) // Round corners
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1) // Add subtle shadow
        .onAppear {
            // Fetch author details when the row appears
            author = postViewModel.getUser(for: post.userID)
            // Set initial like state
            if let currentUserID = authViewModel.user?.id {
                isLiked = post.likes.contains(currentUserID)
            }
        }
         // Update like state if the post object changes (e.g., due to listener update)
         // Adjusted onChange closure signature
         .onChange(of: post.likes) {
             if let currentUserID = authViewModel.user?.id {
                 // Access the new value implicitly or via post.likes directly if needed,
                 // but here we just need to re-evaluate based on the current post state.
                 isLiked = post.likes.contains(currentUserID)
             }
         }
    }
} // Add missing closing brace for PostRow struct
