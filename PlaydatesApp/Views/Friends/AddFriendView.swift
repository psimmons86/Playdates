import SwiftUI

struct AddFriendView: View {
    // Use FriendManagementViewModel now
    @EnvironmentObject var viewModel: FriendManagementViewModel
    @Binding var isPresented: Bool
    @State private var searchText = ""
    // Search results are now @Published in the ViewModel
    // isLoading and errorMessage are also handled by the ViewModel's @Published properties

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search by name or email", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { newValue in
                            // Use the debounced search from the ViewModel
                            viewModel.searchUsersDebounced(newValue)
                        }

                    if viewModel.isSearching { // Use isSearching from ViewModel
                        ProgressView()
                            .padding(.leading, 5)
                    }
                }
                .padding()

                // Search Results List
                List {
                    // Use searchResults from the ViewModel
                    ForEach(viewModel.searchResults) { user in
                        // Correct argument order: isPresented must precede user
                        SearchResultRow(isPresented: $isPresented, user: user)
                            .environmentObject(viewModel) // Pass the VM down
                    }
                }
                .listStyle(PlainListStyle()) // Use plain style for better appearance

                // Display error messages from the ViewModel
                if let error = viewModel.error {
                    // Check if the error is relevant to search (optional)
                    // if case .firestoreError = error { // Example check
                         Text(error.localizedDescription)
                             .foregroundColor(.red)
                             .padding()
                    // }
                }

                Spacer() // Pushes list to the top
            }
            .navigationTitle("Add Friends")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
            // Clear search results when the view disappears
            .onDisappear {
                 viewModel.searchResults = [] // Clear results in VM
                 viewModel.error = nil // Clear error on disappear
            }
        }
    }
}

// Row for displaying a search result
struct SearchResultRow: View {
    @EnvironmentObject var viewModel: FriendManagementViewModel // Use correct VM
    @Binding var isPresented: Bool // To dismiss the sheet after adding
    let user: User
    @State private var isSending = false // Local state for button loading
    @State private var requestStatus: FriendManagementViewModel.FriendshipStatus = .notFriends // Track status locally

    var body: some View {
        HStack {
            // Correct argument label and property name
            ProfileImageView(imageURL: user.profileImageURL, size: 40)
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email) // Display email or other relevant info
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            // Button to Add Friend or show status
            statusButton
        }
        .padding(.vertical, 4)
        .onAppear {
             // Get initial status when the row appears
             updateStatus() // Use helper function
        }
        // Update status if ViewModel's friends/requests change while view is visible
         .onChange(of: viewModel.friends) { _ in updateStatus() }
         .onChange(of: viewModel.sentFriendRequests) { _ in updateStatus() }
         .onChange(of: viewModel.friendRequests) { _ in updateStatus() }
    }

    // Computed property for the button based on status
    @ViewBuilder
    private var statusButton: some View {
        if isSending {
            ProgressView()
        } else {
            switch requestStatus {
            case .friends:
                Text("Friends")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            case .requestSent:
                 HStack { // Show Requested and Cancel button
                     Text("Requested")
                         .font(.caption)
                         .foregroundColor(.orange)
                         .padding(.horizontal, 8)
                         .padding(.vertical, 4)
                         .background(Color.orange.opacity(0.1))
                         .cornerRadius(6)
                     Button("Cancel") { cancelRequest() }
                         .font(.caption)
                         .buttonStyle(.borderless)
                         .tint(.orange)
                 }
            case .requestReceived(let request):
                 // Show Accept/Decline buttons
                 HStack(spacing: 8) {
                     Button("Accept") { respond(accept: true, request: request) }
                         .font(.caption.bold())
                         .padding(.horizontal, 10)
                         .padding(.vertical, 5)
                         .background(Color.green)
                         .foregroundColor(.white)
                         .cornerRadius(6)
                         .buttonStyle(PlainButtonStyle())

                     Button("Decline") { respond(accept: false, request: request) }
                         .font(.caption.bold())
                         .padding(.horizontal, 10)
                         .padding(.vertical, 5)
                         .background(Color.red)
                         .foregroundColor(.white)
                         .cornerRadius(6)
                         .buttonStyle(PlainButtonStyle())
                 }
            case .notFriends, .isSelf, .notLoggedIn: // Treat isSelf/notLoggedIn as not addable for simplicity here
                 if requestStatus == .isSelf || requestStatus == .notLoggedIn {
                      EmptyView() // Don't show button for self or if not logged in
                 } else {
                     Button("Add") {
                         sendRequest()
                     }
                     .font(.caption.bold())
                     .padding(.horizontal, 12)
                     .padding(.vertical, 6)
                     .background(Color.blue)
                     .foregroundColor(.white)
                     .cornerRadius(8)
                     .buttonStyle(PlainButtonStyle())
                 }
            }
        }
    }

    // Function to send friend request
    private func sendRequest() {
        guard let recipientID = user.id else { return }
        isSending = true
        Task {
            do {
                try await viewModel.sendFriendRequest(to: recipientID)
                // Status will update via listener + .onChange
            } catch {
                // Error is handled by the main view's alert via viewModel.error
                print("❌ Failed to send friend request to \(recipientID): \(error)")
            }
            isSending = false
        }
    }

     // Function to cancel a sent request
     private func cancelRequest() {
         // Find the sent request corresponding to this user
         if let request = viewModel.sentFriendRequests.first(where: { $0.receiverID == user.id }) {
             isSending = true
             Task {
                 do {
                     try await viewModel.cancelFriendRequest(request: request)
                     // Status will update via listener + .onChange
                 } catch {
                      print("❌ Error cancelling request: \(error)")
                      // Handle error display if needed
                 }
                 isSending = false
             }
         } else {
              print("⚠️ Could not find sent request to cancel for user \(user.id ?? "N/A")")
         }
     }

     // Function to respond to a received request
     private func respond(accept: Bool, request: FriendRequestModel) {
         isSending = true
         Task {
             do {
                 try await viewModel.respondToFriendRequest(request: request, accept: accept)
                 // Status will update via listener + .onChange
             } catch {
                  print("❌ Error responding to request: \(error)")
                  // Handle error display if needed
             }
             isSending = false
         }
     }

     // Function to update status based on ViewModel changes
     private func updateStatus() {
         // Ensure user.id is valid before checking status
         guard let userId = user.id else {
             requestStatus = .notFriends // Or handle appropriately
             return
         }
         requestStatus = viewModel.friendshipStatus(with: userId)
     }
}

// Preview Provider (Update if needed)
struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock AuthViewModel for the preview
        let authViewModel = AuthViewModel()
        // Create FriendManagementViewModel, passing the mock AuthViewModel
        let friendManager = FriendManagementViewModel(authViewModel: authViewModel)
        // Simulate logged-in state for preview if necessary
        // authViewModel.user = ... // Assign a mock User if needed for preview logic

        // Use the full User initializer for mock data, providing all arguments
        let mockUser1 = User(id: "user1", name: "Charlie", email: "charlie@example.com", profileImageURL: nil, bio: nil, children: nil, friendIDs: nil, friendRequestIDs: nil, createdAt: Date(), lastActive: Date())
        let mockUser2 = User(id: "user2", name: "Diana", email: "diana@example.com", profileImageURL: nil, bio: nil, children: nil, friendIDs: nil, friendRequestIDs: nil, createdAt: Date(), lastActive: Date())
        let mockUser3 = User(id: "user3", name: "Ethan", email: "ethan@example.com", profileImageURL: nil, bio: nil, children: nil, friendIDs: nil, friendRequestIDs: nil, createdAt: Date(), lastActive: Date()) // User with received request

        friendManager.searchResults = [mockUser1, mockUser2, mockUser3]

        // Simulate different statuses for preview
        friendManager.friends = [mockUser1] // Charlie is a friend
        friendManager.sentFriendRequests = [FriendRequestModel(senderID: "currentUser", receiverID: "user2")] // Request sent to Diana
        friendManager.friendRequests = [FriendRequestModel(id: "req123", senderID: "user3", receiverID: "currentUser", status: .pending, createdAt: Date())] // Request received from Ethan

        return NavigationView { // Embed in NavigationView for title
             AddFriendView(isPresented: .constant(true))
                 .environmentObject(friendManager) // Provide the correct VM
                 .environmentObject(AuthViewModel()) // Provide mock Auth VM if needed
        }
    }
}

// Removed the leftover UserSearchCard struct
