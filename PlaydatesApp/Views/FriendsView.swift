import SwiftUI
import Combine
import Firebase

struct FriendsView: View {
    @StateObject var viewModel = FriendshipViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var showingFriendRequests = false
    @State private var selectedTab = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Enhanced header
                EnhancedFriendsHeader(
                    isAnimating: $isAnimating,
                    friendCount: viewModel.friends.count,
                    pendingCount: viewModel.friendRequests.count
                )
                
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
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Custom tab bar
                FriendsTabBar(selectedTab: $selectedTab)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // All Friends Tab
                    allFriendsView
                        .tag(0)
                    
                    // Nearby Tab
                    nearbyFriendsView
                        .tag(1)
                    
                    // Requests Tab
                    requestsView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
            .onAppear {
                isAnimating = true
                if let userId = authViewModel.user?.id {
                    viewModel.fetchFriends(for: userId)
                    viewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
    
    // All Friends View
    private var allFriendsView: some View {
        VStack {
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
    }
    
    // Nearby Friends View (placeholder for now)
    private var nearbyFriendsView: some View {
        VStack {
            Spacer()
            Text("Find friends nearby")
                .font(.headline)
                .foregroundColor(ColorTheme.text)
            
            Text("See who's in your area")
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
                .padding(.top, 4)
            
            Button(action: {
                // Would implement location-based friend discovery
            }) {
                Text("Enable Location")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.top, 16)
            Spacer()
        }
    }
    
    // Friend Requests View
    private var requestsView: some View {
        VStack {
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if viewModel.friendRequests.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Friend Requests")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("When someone adds you, they'll appear here")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            } else {
                requestsList
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
                .foregroundColor(ColorTheme.text)
            
            Text("Add friends to plan playdates together")
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredFriends) { friend in
                    EnhancedFriendCard(friend: friend)
                        .environmentObject(viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
    
    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.friendRequests) { request in
                    FriendRequestCard(request: request)
                        .environmentObject(viewModel)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
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

struct EnhancedFriendsHeader: View {
    @Binding var isAnimating: Bool
    let friendCount: Int
    let pendingCount: Int
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorTheme.accent.opacity(0.9),
                        ColorTheme.primary,
                        ColorTheme.highlight.opacity(0.7)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Overlay gradient for depth
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Subtle pattern overlay
                ZStack {
                    ForEach(0..<15) { i in
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 20, height: 20)
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: CGFloat.random(in: -60...60)
                            )
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal)
            
            // Decorative elements
            ZStack {
                // Floating circles representing people
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: CGFloat([40, 35, 30][i]))
                        .offset(
                            x: CGFloat([80, -40, 20][i]),
                            y: CGFloat([-30, 40, -15][i])
                        )
                        .blur(radius: 2)
                }
                
                // Friend icon animations
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: -80, y: 0)
                    .rotationEffect(.degrees(isAnimating ? 3 : -3))
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: "message.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 0, y: -20)
                    .rotationEffect(.degrees(isAnimating ? -3 : 3))
                    .animation(
                        Animation.easeInOut(duration: 3.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 35))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 80, y: 0)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 4.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Header content
            VStack(alignment: .leading, spacing: 12) {
                // Welcome content
                Text("Friends & Connections")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Connect with parents and schedule playdates")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Friend stats
                HStack(spacing: 15) {
                    FriendStat(
                        icon: "person.2",
                        value: "\(friendCount)",
                        title: "Friends"
                    )
                    
                    FriendStat(
                        icon: "clock",
                        value: "Recent",
                        title: "Activity"
                    )
                    
                    FriendStat(
                        icon: "bell",
                        value: "\(pendingCount)",
                        title: "Pending"
                    )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
        .padding(.bottom, 15)
    }
}

struct FriendStat: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}

struct FriendsTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            FriendsTabButton(
                title: "All Friends",
                icon: "person.2",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            FriendsTabButton(
                title: "Nearby",
                icon: "location",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            FriendsTabButton(
                title: "Requests",
                icon: "person.crop.circle.badge.plus",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct FriendsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.lightText)
            .background(
                isSelected ? 
                    Color.white.opacity(0.1) : 
                    Color.clear
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? ColorTheme.primary : Color.clear)
                    .frame(height: 3)
                    .offset(y: 20),
                alignment: .bottom
            )
        }
    }
}

struct EnhancedFriendCard: View {
    let friend: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Profile image
                if #available(iOS 17.0, *) {
                    ProfileImageView(imageURL: friend.profileImageURL, size: 60)
                } else {
                    // Fallback for older iOS versions
                    Circle()
                        .fill(ColorTheme.primary.opacity(0.7))
                        .frame(width: 60, height: 60)
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
                        .foregroundColor(ColorTheme.text)
                    
                    if let children = friend.children, !children.isEmpty {
                        Text("\(children.count) \(children.count == 1 ? "Child" : "Children")")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText)
                        
                        Text(formatLastActive(friend.lastActive))
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Message button
                    Button(action: {
                        // Would open chat with this friend
                    }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.accent)
                            .clipShape(Circle())
                    }
                    
                    // More actions button
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(ColorTheme.lightText)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
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
                            self.viewModel.removeFriendship(friendId: friendId)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func formatLastActive(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FriendRequestCard: View {
    let request: FriendRequestModel
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var sender: User?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Profile image
                if let sender = sender {
                    if #available(iOS 17.0, *) {
                        ProfileImageView(imageURL: sender.profileImageURL, size: 60)
                    } else {
                        // Fallback for older iOS versions
                        Circle()
                            .fill(ColorTheme.primary.opacity(0.7))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.7)
                        )
                }
                
                // Sender info
                VStack(alignment: .leading, spacing: 4) {
                    Text(sender?.name ?? "Loading...")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("Wants to be friends")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                    
                    // Time of request
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText)
                        
                        Text(formatDate(request.createdAt))
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
                
                Spacer()
                
                // Action buttons
                if !isLoading {
                    VStack(spacing: 8) {
                        // Accept button
                        Button(action: {
                            acceptFriendRequest()
                        }) {
                            Text("Accept")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 80)
                                .padding(.vertical, 6)
                                .background(ColorTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        
                        // Decline button
                        Button(action: {
                            declineFriendRequest()
                        }) {
                            Text("Decline")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 80)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .foregroundColor(ColorTheme.lightText)
                                .cornerRadius(20)
                        }
                    }
                } else {
                    ProgressView()
                        .padding(.horizontal)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            fetchSender()
        }
    }
    
    private func fetchSender() {
        // Check if senderID is not empty
        guard !request.senderID.isEmpty else { return }
        
        // Fetch the actual user data from Firebase
        viewModel.db.collection("users").document(request.senderID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching sender: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot, document.exists else {
                print("Sender document not found")
                return
            }
            
            // Try to decode the user
            if let user = try? document.data(as: User.self) {
                DispatchQueue.main.async {
                    self.sender = user
                }
            } else {
                // Manual parsing if decoding fails
                if let data = document.data() {
                    let name = data["name"] as? String ?? "Unknown User"
                    let email = data["email"] as? String ?? "unknown@example.com"
                    let profileImageURL = data["profileImageURL"] as? String
                    
                    // Create a User object without directly setting the @DocumentID property
                    var user = User(
                        id: nil,  // Don't set the ID directly to avoid Firestore warning
                        name: name,
                        email: email,
                        profileImageURL: profileImageURL,
                        createdAt: Date(),
                        lastActive: Date()
                    )
                    // Store the ID separately since we need it for display purposes
                    // but don't want to trigger the @DocumentID warning
                    user.id = request.senderID
                    
                    DispatchQueue.main.async {
                        self.sender = user
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func acceptFriendRequest() {
        isLoading = true
        
        if let requestId = request.id {
            self.viewModel.acceptFriendRequest(requestId: requestId) { success in
                self.isLoading = false
            }
        } else {
            self.isLoading = false
        }
    }
    
    private func declineFriendRequest() {
        isLoading = true
        
        if let requestId = request.id {
            self.viewModel.declineFriendRequest(requestId: requestId) { success in
                self.isLoading = false
            }
        } else {
            self.isLoading = false
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
                // Enhanced header
                VStack(spacing: 12) {
                    // Illustration/icon
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(ColorTheme.primary.opacity(0.8))
                        .padding()
                        .background(ColorTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("Find New Friends")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("Search by name or email to connect")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
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
                    
                    // Search button
                    Button(action: searchUsers) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ColorTheme.primary)
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                .padding(.horizontal)
                
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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .foregroundColor(ColorTheme.lightText)
                    }
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(ColorTheme.lightText)
                        
                        Text("No users found")
                            .font(.headline)
                            .foregroundColor(ColorTheme.text)
                        
                        Text("Try a different name or email address")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else if !searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { user in
                                UserSearchCard(user: user)
                                    .environmentObject(viewModel)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                } else {
                    // Initial state with tips
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Text("Search Tips")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            HStack(spacing: 16) {
                                searchTip(icon: "person.text.rectangle", text: "Search by full name")
                                searchTip(icon: "envelope", text: "Search by email")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func searchTip(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.primary.opacity(0.8))
                .frame(width: 50, height: 50)
                .background(ColorTheme.primary.opacity(0.1))
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        print("DEBUG: Starting search with query: \(searchText)")
        isSearching = true
        errorMessage = nil
        
        // Use the combined searchUsers method which is more robust
        viewModel.searchUsers(searchText) { allResults in
            // Remove duplicates (should be handled by searchUsers, but just in case)
            var uniqueResults: [User] = []
            var seenIds = Set<String>()
            
            for user in allResults {
                if let id = user.id, !seenIds.contains(id) {
                    seenIds.insert(id)
                    uniqueResults.append(user)
                }
            }
            
            print("DEBUG: After removing duplicates: \(uniqueResults.count) results")
            
            // Filter out the current user
            if let currentUserId = self.viewModel.currentUserId {
                print("DEBUG: Current user ID: \(currentUserId)")
                uniqueResults = uniqueResults.filter { $0.id != currentUserId }
                print("DEBUG: After filtering out current user: \(uniqueResults.count) results")
            }
            
            // Also filter out users who are already friends
            let beforeFriendFilter = uniqueResults.count
            uniqueResults = uniqueResults.filter { user in
                guard let userId = user.id else { return true }
                return !self.viewModel.isFriend(userId: userId)
            }
            print("DEBUG: After filtering out friends: \(uniqueResults.count) results (removed \(beforeFriendFilter - uniqueResults.count))")
            
            DispatchQueue.main.async {
                self.isSearching = false
                self.searchResults = uniqueResults
                
                if uniqueResults.isEmpty {
                    print("DEBUG: No users found after filtering")
                    self.errorMessage = "No users found matching '\(self.searchText)'. Check connection or try different search terms."
                } else {
                    self.errorMessage = nil
                }
            }
        }
    }
}

struct UserSearchCard: View {
    let user: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var isSending = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Profile image
                if #available(iOS 17.0, *) {
                    ProfileImageView(imageURL: user.profileImageURL, size: 60)
                } else {
                    // Fallback for older iOS versions
                    Circle()
                        .fill(ColorTheme.primary.opacity(0.7))
                        .frame(width: 60, height: 60)
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
                        .foregroundColor(ColorTheme.text)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                    
                    if let children = user.children, !children.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.child")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text("\(children.count) \(children.count == 1 ? "Child" : "Children")")
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                    }
                }
                
                Spacer()
                
                // Add button
                Button(action: {
                    sendFriendRequest()
                }) {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 80, height: 36)
                            .background(ColorTheme.primary)
                            .cornerRadius(18)
                    } else if viewModel.isFriendRequestPending(userId: user.id ?? "") {
                        Text("Sent")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, height: 36)
                            .background(Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    } else {
                        Text("Add")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, height: 36)
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }
                }
                .disabled(isSending || viewModel.isFriendRequestPending(userId: user.id ?? ""))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Friend Request"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func sendFriendRequest() {
        isSending = true
        
        if let userId = user.id, let currentUserId = viewModel.currentUserId {
            viewModel.sendFriendRequest(from: currentUserId, to: userId) { result in
                DispatchQueue.main.async {
                    isSending = false
                    
                    switch result {
                    case .success:
                        alertMessage = "Friend request sent to \(user.name)"
                        showAlert = true
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        }
    }
}
