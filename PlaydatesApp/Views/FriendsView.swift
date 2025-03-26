import SwiftUI
import Combine

struct FriendsView: View {
    @StateObject var viewModel = FriendshipViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var showingFriendRequests = false
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search friends", text: $searchText)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Friend requests button
                if !viewModel.friendRequests.isEmpty {
                    Button(action: {
                        showingFriendRequests = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(ColorTheme.primary)
                            
                            Text("\(viewModel.friendRequests.count) Friend Request\(viewModel.friendRequests.count > 1 ? "s" : "")")
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Friends list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.friends.isEmpty {
                    emptyStateView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing:
                Button(action: {
                    showingAddFriendSheet = true
                }) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                }
            )
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView(isPresented: $showingAddFriendSheet)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingFriendRequests) {
                FriendRequestsView(isPresented: $showingFriendRequests)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if let userId = authViewModel.user?.id {
                    viewModel.fetchFriends(for: userId)
                    viewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add friends to plan playdates together")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddFriendSheet = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(ColorTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var friendsList: some View {
        List {
            ForEach(filteredFriends) { friend in
                FriendRow(friend: friend)
                    .environmentObject(viewModel)
            }
            .listRowBackground(Color.white)
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return viewModel.friends
        } else {
            return viewModel.friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                ProfileImageView(imageURL: friend.profileImageURL, size: 50)
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                
                if let children = friend.children, !children.isEmpty {
                    Text("\(children.count) \(children.count == 1 ? "Child" : "Children")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action button
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Friend Options"),
                buttons: [
                    .default(Text("Message")) {
                        // Open chat with this friend
                    },
                    .default(Text("Invite to Playdate")) {
                        // Invite to playdate
                    },
                    .destructive(Text("Remove Friend")) {
                        if let friendId = friend.id {
                            viewModel.removeFriendship(friendId: friendId)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct AddFriendView: View {
    @EnvironmentObject var viewModel: FriendshipViewModel
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by name or email", text: $searchText, onCommit: {
                        searchUsers()
                    })
                    .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text("No users found")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(searchResults) { user in
                            UserSearchRow(user: user)
                                .environmentObject(viewModel)
                        }
                        .listRowBackground(Color.white)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        // Simulate searching users - replace with actual implementation
        // that interacts with the FriendshipViewModel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // This is a placeholder for the real implementation
            let mockUsers = [
                User(id: UUID().uuidString, name: "Jane Smith", email: "jane@example.com", createdAt: Date(), lastActive: Date()),
                User(id: UUID().uuidString, name: "John Doe", email: "john@example.com", createdAt: Date(), lastActive: Date())
            ]
            
            self.isSearching = false
            self.searchResults = mockUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(self.searchText) ||
                user.email.localizedCaseInsensitiveContains(self.searchText)
            }
            
            if self.searchResults.isEmpty {
                self.errorMessage = "No users found matching '\(self.searchText)'"
            }
        }
    }
}

struct UserSearchRow: View {
    let user: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                ProfileImageView(imageURL: user.profileImageURL, size: 50)
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add button
            Button(action: {
                if let userId = user.id {
                    viewModel.sendFriendRequest(from: "currentUserId", to: userId)
                }
            }) {
                if viewModel.isFriendRequestPending(userId: user.id ?? "") {
                    Text("Sent")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                } else if viewModel.isFriend(userId: user.id ?? "") {
                    Text("Friend")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                } else {
                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ColorTheme.primary)
                        .cornerRadius(16)
                }
            }
            .disabled(viewModel.isFriendRequestPending(userId: user.id ?? "") || viewModel.isFriend(userId: user.id ?? ""))
        }
        .padding(.vertical, 8)
    }
}

struct FriendRequestsView: View {
    @EnvironmentObject var viewModel: FriendshipViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.friendRequests.isEmpty {
                    Spacer()
                    Text("No friend requests")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.friendRequests) { request in
                            FriendRequestRow(request: request)
                                .environmentObject(viewModel)
                        }
                        .listRowBackground(Color.white)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .onAppear {
                if let userId = viewModel.currentUserId {
                    viewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequestModel
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var sender: User?
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                if let sender = sender {
                    ProfileImageView(imageURL: sender.profileImageURL, size: 50)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(sender?.name ?? "Loading...")
                    .font(.headline)
                
                Text("Wants to be friends")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            if !isLoading {
                HStack(spacing: 8) {
                    // Decline button
                    Button(action: {
                        declineFriendRequest()
                    }) {
                        Text("Decline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(16)
                    }
                    
                    // Accept button
                    Button(action: {
                        acceptFriendRequest()
                    }) {
                        Text("Accept")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.primary)
                            .cornerRadius(16)
                    }
                }
            } else {
                ProgressView()
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            fetchSender()
        }
    }
    
    private func fetchSender() {
        // Check if senderID exists and is not empty
        let senderID = request.senderID ?? ""
        if !senderID.isEmpty {
            // Simulate fetching the sender user
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // This is a placeholder. In the real app, you would use viewModel to fetch the user
                self.sender = User(
                    id: senderID,
                    name: "John Doe",
                    email: "john@example.com",
                    createdAt: Date(),
                    lastActive: Date()
                )
            }
        }
    }
    
    private func acceptFriendRequest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let requestId = request.id {
                viewModel.acceptFriendRequest(requestId: requestId) { success in
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    private func declineFriendRequest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let requestId = request.id {
                viewModel.declineFriendRequest(requestId: requestId) { success in
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
}

// Add this extension to the FriendshipViewModel to support the interface
extension FriendshipViewModel {
    // Friend status checks
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.id == userId }
    }
    
    func isFriendRequestPending(userId: String) -> Bool {
        return friendRequests.contains { $0.senderID == userId }
    }
    
    var currentUserId: String? {
        // This would be implemented to return the current user's ID
        return nil
    }
    
    // Friend request actions
    func acceptFriendRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        // Implementation would be added here
        completion(true)
    }
    
    func declineFriendRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        // Implementation would be added here
        completion(true)
    }
    
    func removeFriendship(friendId: String) {
        // Implementation would be added here
    }
    
    func sendFriendRequest(from senderId: String, to recipientId: String) {
        // Implementation would be added here
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
