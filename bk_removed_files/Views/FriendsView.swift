import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendshipViewModel: FriendshipViewModel
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                HStack {
                    TabButton(title: "Friends", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Requests", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search bar
                if selectedTab == 0 {
                    searchBar
                }
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Friends list
                    friendsListView
                        .tag(0)
                    
                    // Friend requests
                    friendRequestsView
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing: addButton)
            .onAppear {
                if let userID = authViewModel.user?.id {
                    friendshipViewModel.fetchFriends(for: userID)
                    friendshipViewModel.fetchFriendRequests(for: userID)
                }
            }
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView()
            }
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ColorTheme.text.opacity(0.5))
            
            TextField("Search friends...", text: $searchText)
                .foregroundColor(ColorTheme.text)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var friendsListView: some View {
        ScrollView {
            if friendshipViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if friendshipViewModel.friends.isEmpty {
                emptyStateView(
                    icon: "person.2",
                    title: "No Friends Yet",
                    message: "Add friends to plan playdates together."
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredFriends) { friend in
                        FriendRow(friend: friend)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            if let userID = authViewModel.user?.id {
                friendshipViewModel.fetchFriends(for: userID)
            }
        }
    }
    
    private var friendRequestsView: some View {
        ScrollView {
            if friendshipViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if friendshipViewModel.friendRequests.isEmpty && friendshipViewModel.sentRequests.isEmpty {
                emptyStateView(
                    icon: "person.badge.plus",
                    title: "No Friend Requests",
                    message: "Friend requests you receive will appear here."
                )
            } else {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    if !friendshipViewModel.friendRequests.isEmpty {
                        Section(header: sectionHeader("Received Requests")) {
                            ForEach(friendshipViewModel.friendRequests, id: \.id) { request in
                                FriendRequestRow(request: request)
                            }
                        }
                    }
                    
                    if !friendshipViewModel.sentRequests.isEmpty {
                        Section(header: sectionHeader("Sent Requests")) {
                            ForEach(friendshipViewModel.sentRequests, id: \.id) { request in
                                SentRequestRow(request: request)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .refreshable {
            if let userID = authViewModel.user?.id {
                friendshipViewModel.fetchFriendRequests(for: userID)
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddFriendSheet = true
        }) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary)
                .padding(8)
                .background(ColorTheme.primary.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(ColorTheme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(ColorTheme.background)
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(ColorTheme.primary.opacity(0.7))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text(message)
                .font(.body)
                .foregroundColor(ColorTheme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddFriendSheet = true
            }) {
                Text("Add Friend")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ColorTheme.primary)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friendshipViewModel.friends
        } else {
            return friendshipViewModel.friends.filter { friend in
                friend.name.lowercased().contains(searchText.lowercased()) ||
                friend.email.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if let profileImageURL = friend.profileImageURL, !profileImageURL.isEmpty {
                AsyncImage(url: URL(string: profileImageURL)) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Text(friend.name.prefix(1).uppercased())
                                    .foregroundColor(ColorTheme.text.opacity(0.5))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Text(friend.name.prefix(1).uppercased())
                                    .foregroundColor(ColorTheme.text.opacity(0.5))
                            )
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 50, height: 50)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(friend.name.prefix(1).uppercased())
                            .foregroundColor(ColorTheme.text.opacity(0.5))
                    )
            }
            
            // Friend details
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                if let children = friend.children, !children.isEmpty {
                    Text("\(children.count) \(children.count == 1 ? "child" : "children")")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Message friend
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme.primary)
                        .padding(8)
                        .background(ColorTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
                
                NavigationLink(destination: FriendProfileView(friend: friend)) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @EnvironmentObject private var friendshipViewModel: FriendshipViewModel
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("U")
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                )
            
            // Request details
            VStack(alignment: .leading, spacing: 4) {
                Text(request.senderID) // In a real app, you'd show the user's name
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                if let message = request.message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                        .lineLimit(1)
                }
                
                Text("Sent \(timeAgo(date: request.createdAt))")
                    .font(.caption)
                    .foregroundColor(ColorTheme.text.opacity(0.5))
            }
            
            Spacer()
            
            // Action buttons
            if isLoading {
                ProgressView()
                    .padding(.horizontal)
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        acceptRequest()
                    }) {
                        Text("Accept")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.secondary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        declineRequest()
                    }) {
                        Text("Decline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func acceptRequest() {
        isLoading = true
        
        friendshipViewModel.acceptFriendRequest(request) { result in
            isLoading = false
            // Handle result if needed
        }
    }
    
    private func declineRequest() {
        isLoading = true
        
        friendshipViewModel.declineFriendRequest(request) { result in
            isLoading = false
            // Handle result if needed
        }
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SentRequestRow: View {
    let request: FriendRequest
    @EnvironmentObject private var friendshipViewModel: FriendshipViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("U")
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                )
            
            // Request details
            VStack(alignment: .leading, spacing: 4) {
                Text(request.recipientID) // In a real app, you'd show the user's name
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                if let message = request.message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                        .lineLimit(1)
                }
                
                Text("Sent \(timeAgo(date: request.createdAt))")
                    .font(.caption)
                    .foregroundColor(ColorTheme.text.opacity(0.5))
            }
            
            Spacer()
            
            // Status badge
            Text("Pending")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ColorTheme.accent.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FriendProfileView: View {
    let friend: User
    @EnvironmentObject private var friendshipViewModel: FriendshipViewModel
    @State private var showingRemoveFriendAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile header
                VStack(spacing: 16) {
                    // Profile image
                    if let profileImageURL = friend.profileImageURL, !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { phase in
                            switch phase {
                            case .empty:
                                profileImagePlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure:
                                profileImagePlaceholder
                            @unknown default:
                                profileImagePlaceholder
                            }
                        }
                    } else {
                        profileImagePlaceholder
                    }
                    
                    // Name and bio
                    VStack(spacing: 8) {
                        Text(friend.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.text)
                        
                        if let bio = friend.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundColor(ColorTheme.text.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            // Create playdate with friend
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(ColorTheme.primary)
                                
                                Text("Playdate")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.text)
                            }
                            .frame(width: 70)
                        }
                        
                        Button(action: {
                            // Message friend
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "message")
                                    .font(.system(size: 20))
                                    .foregroundColor(ColorTheme.primary)
                                
                                Text("Message")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.text)
                            }
                            .frame(width: 70)
                        }
                        
                        Button(action: {
                            showingRemoveFriendAlert = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "person.fill.xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.red)
                                
                                Text("Remove")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.text)
                            }
                            .frame(width: 70)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Children section
                if let children = friend.children, !children.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Children")
                            .font(.headline)
                            .foregroundColor(ColorTheme.text)
                        
                        ForEach(children) { child in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(ColorTheme.primary.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(child.name.prefix(1).uppercased())
                                            .foregroundColor(ColorTheme.primary)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(child.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(ColorTheme.text)
                                    
                                    Text("\(child.age) years old")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.text.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if let interests = child.interests, !interests.isEmpty {
                                    Text(interests.first ?? "")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ColorTheme.primary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Past playdates section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Past Playdates")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("You haven't had any playdates with this friend yet.")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingRemoveFriendAlert) {
            Alert(
                title: Text("Remove Friend"),
                message: Text("Are you sure you want to remove \(friend.name) from your friends list?"),
                primaryButton: .destructive(Text("Remove")) {
                    removeFriend()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var profileImagePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Text(friend.name.prefix(1).uppercased())
                    .font(.system(size: 40))
                    .foregroundColor(ColorTheme.text.opacity(0.5))
            )
    }
    
    private func removeFriend() {
        // In a real app, you'd call the friendshipViewModel to remove the friend
    }
}

struct AddFriendView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendshipViewModel: FriendshipViewModel
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var message = ""
    @State private var selectedUser: User?
    @State private var showingMessageSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                    
                    TextField("Search by name or email", text: $searchText)
                        .foregroundColor(ColorTheme.text)
                        .onSubmit {
                            searchUsers()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ColorTheme.text.opacity(0.5))
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search results
                if isSearching {
                    ProgressView()
                        .padding()
                } else if !searchText.isEmpty && searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(ColorTheme.primary.opacity(0.7))
                        
                        Text("No Users Found")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.text)
                        
                        Text("Try a different search term or invite them to join.")
                            .font(.body)
                            .foregroundColor(ColorTheme.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { user in
                            Button(action: {
                                selectedUser = user
                                showingMessageSheet = true
                            }) {
                                HStack(spacing: 12) {
                                    // Profile image placeholder
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(user.name.prefix(1).uppercased())
                                                .foregroundColor(ColorTheme.text.opacity(0.5))
                                        )
                                    
                                    // User details
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.headline)
                                            .foregroundColor(ColorTheme.text)
                                        
                                        Text(user.email)
                                            .font(.subheadline)
                                            .foregroundColor(ColorTheme.text.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    // Add button
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(ColorTheme.primary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingMessageSheet) {
                if let user = selectedUser {
                    SendFriendRequestView(user: user, onSend: { message in
                        sendFriendRequest(to: user, message: message)
                    })
                }
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty, let currentUserID = authViewModel.user?.id else { return }
        
        isSearching = true
        
        friendshipViewModel.searchUsers(query: searchText, currentUserID: currentUserID) { result in
            isSearching = false
            
            switch result {
            case .success(let users):
                searchResults = users
            case .failure(let error):
                print("Error searching users: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendFriendRequest(to user: User, message: String) {
        guard let currentUserID = authViewModel.user?.id, let recipientID = user.id else { return }
        
        friendshipViewModel.sendFriendRequest(from: currentUserID, to: recipientID, message: message) { result in
            switch result {
            case .success(_):
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Error sending friend request: \(error.localizedDescription)")
            }
        }
    }
}

struct SendFriendRequestView: View {
    let user: User
    let onSend: (String) -> Void
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User info
                VStack(spacing: 12) {
                    // Profile image placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(user.name.prefix(1).uppercased())
                                .font(.system(size: 30))
                                .foregroundColor(ColorTheme.text.opacity(0.5))
                        )
                    
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.text)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                }
                .padding()
                
                // Message input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a message (optional)")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    TextEditor(text: $message)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding()
                
                Spacer()
                
                // Send button
                Button(action: {
                    onSend(message)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Send Friend Request")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.primary)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Friend Request")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
            .environmentObject(AuthViewModel())
            .environmentObject(FriendshipViewModel())
    }
}
