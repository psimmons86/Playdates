import SwiftUI
import Combine
import Firebase

struct FriendsView: View {
    // Use FriendManagementViewModel now, injected via EnvironmentObject
    @EnvironmentObject var viewModel: FriendManagementViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var showingFriendRequests = false // This state might not be needed if using the tab bar
    @State private var selectedTab = 0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Enhanced header - Pass counts from the correct ViewModel
                EnhancedFriendsHeader(
                    isAnimating: $isAnimating,
                    friendCount: viewModel.friends.count,
                    pendingCount: viewModel.friendRequests.count // friendRequests are received pending requests
                )

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search friends", text: $searchText)
                        .foregroundColor(.primary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                Button {
                    showingAddFriendSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(ColorTheme.primary)
                }
                .buttonStyle(PlainButtonStyle())
            )
            .sheet(isPresented: $showingAddFriendSheet) {
                // Pass the correct ViewModel to AddFriendView
                AddFriendView(isPresented: $showingAddFriendSheet)
                    .environmentObject(viewModel) // Pass FriendManagementViewModel
            }
            .onAppear {
                isAnimating = true
                // Fetching is handled by listeners in FriendManagementViewModel's init
                print("✅ FriendsView appeared. Listeners should handle data fetching.")
            }
            // Display errors from the ViewModel
           .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
                Button("OK") {
                    viewModel.error = nil // Clear the error
                }
           } message: { error in
                Text(error.localizedDescription)
           }
        }
         // Ensure the view itself gets the necessary VM if it wasn't passed higher up
         // .environmentObject(FriendManagementViewModel()) // Only if needed and not provided by parent
    }

    // All Friends View
    private var allFriendsView: some View {
        VStack {
            // Use isLoading from FriendManagementViewModel
            if viewModel.isLoading && viewModel.friends.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredFriends.isEmpty && !searchText.isEmpty {
                 Text("No friends found matching \"\(searchText)\".")
                     .foregroundColor(.secondary)
                     .padding()
                 Spacer()
            } else if viewModel.friends.isEmpty {
                emptyStateView // Show empty state if no friends and not loading
            } else {
                friendsList
            }
        }
    }

    // Nearby Friends View (placeholder)
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

            Button("Enable Location") {
                // Implement location-based friend discovery
            }
            .primaryStyle()
            .fixedSize(horizontal: true, vertical: false)
            .padding(.top, 16)
            Spacer()
        }
    }

    // Friend Requests View
    private var requestsView: some View {
        VStack {
             // Use isLoading and friendRequests from FriendManagementViewModel
            if viewModel.isLoading && viewModel.friendRequests.isEmpty {
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
            Button {
                showingAddFriendSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
            }
            .primaryStyle()
            .fixedSize(horizontal: true, vertical: false)
            .padding(.top, 10)
            Spacer()
        }
    }

    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredFriends) { friend in
                    // Pass the correct ViewModel to the card
                    EnhancedFriendCard(friend: friend)
                        .environmentObject(viewModel) // Pass FriendManagementViewModel
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                 // Use friendRequests from FriendManagementViewModel
                ForEach(viewModel.friendRequests) { request in
                    // Pass the correct ViewModel to the card
                    FriendRequestCard(request: request)
                        .environmentObject(viewModel) // Pass FriendManagementViewModel
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // Use friends from FriendManagementViewModel
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

// MARK: - Subviews (Header, Stats, TabBar, Cards)

struct EnhancedFriendsHeader: View {
    @Binding var isAnimating: Bool
    let friendCount: Int
    let pendingCount: Int
     @State private var showingActivityFeed = false
     @EnvironmentObject var appActivityViewModel: AppActivityViewModel // Add EnvironmentObject

     // Computed property for decorative elements to simplify body
     private var decorativeElements: some View {
         ZStack {
             ForEach(0..<3) { i in Circle().fill(Color.white.opacity(0.2)).frame(width: CGFloat([40, 35, 30][i])).offset(x: CGFloat([80, -40, 20][i]), y: CGFloat([-30, 40, -15][i])).blur(radius: 2) }
             Image(systemName: "person.2.fill").font(.system(size: 40)).foregroundColor(.white.opacity(0.3)).offset(x: -80, y: 0).rotationEffect(.degrees(isAnimating ? 3 : -3)).animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
             Image(systemName: "message.fill").font(.system(size: 35)).foregroundColor(.white.opacity(0.3)).offset(x: 0, y: -20).rotationEffect(.degrees(isAnimating ? -3 : 3)).animation(Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: isAnimating)
             Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 35)).foregroundColor(.white.opacity(0.3)).offset(x: 80, y: 0).rotationEffect(.degrees(isAnimating ? 5 : -5)).animation(Animation.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: isAnimating)
         }
     }

     // Computed property for the background gradient/pattern
     private var backgroundGradient: some View {
         ZStack {
             LinearGradient(gradient: Gradient(colors: [ColorTheme.accent.opacity(0.9), ColorTheme.primary, ColorTheme.highlight.opacity(0.7)]), startPoint: .topTrailing, endPoint: .bottomLeading)
             RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.clear]), center: .topTrailing, startRadius: 0, endRadius: 300)
             ZStack { ForEach(0..<15) { i in Circle().fill(Color.white.opacity(0.05)).frame(width: 20, height: 20).offset(x: CGFloat.random(in: -150...150), y: CGFloat.random(in: -60...60)) } }
         }
         .frame(height: 160)
         .clipShape(RoundedRectangle(cornerRadius: 20))
         .padding(.horizontal)
     }

     var body: some View {
         // Assign computed properties to local constants to help compiler
         let bg = backgroundGradient
         let decor = decorativeElements
         let content = headerContent

         ZStack { // Line 261 (approx) - Outer ZStack
             // Use the local constants
             bg

             decor
             content
         }
         .padding(.bottom, 15)
         .sheet(isPresented: $showingActivityFeed) {
            NavigationView {
                ActivityFeedView()
                    .environmentObject(appActivityViewModel) // Inject the instance from the environment
                    .navigationTitle("Recent Activity")
                    .navigationBarItems(trailing: Button("Done") { showingActivityFeed = false })
             }
         }
     }

     // Computed property for the main header content VStack
     private var headerContent: some View {
         VStack(alignment: .leading, spacing: 12) {
             Text("Friends & Connections")
                 .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Connect with parents and schedule playdates")
                    .font(.subheadline).foregroundColor(.white.opacity(0.9))

                // Friend stats
                HStack(spacing: 15) {
                    FriendStat(icon: "person.2", value: "\(friendCount)", title: "Friends") // Use passed friendCount
                    FriendStat(icon: "clock", value: "Recent", title: "Activity", action: { showingActivityFeed = true })
                    FriendStat(icon: "bell", value: "\(pendingCount)", title: "Pending") // Use passed pendingCount
                }
                 .padding(.top, 4)
         }
         .padding(.horizontal, 30)
         .padding(.vertical, 20)
     }
 }

struct FriendStat: View {
    let icon: String
    let value: String
    let title: String
    var action: (() -> Void)? = nil

    var body: some View { // Keep as is
        Button(action: { action?() }) {
            VStack(spacing: 4) {
                HStack(spacing: 6) { Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white); Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.white) }
                Text(title).font(.system(size: 11)).foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8).background(Color.white.opacity(0.2)).cornerRadius(10)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct FriendsTabBar: View {
    @Binding var selectedTab: Int

    var body: some View { // Keep as is
        HStack(spacing: 0) {
            FriendsTabButton(title: "All Friends", icon: "person.2", isSelected: selectedTab == 0, action: { selectedTab = 0 })
            FriendsTabButton(title: "Nearby", icon: "location", isSelected: selectedTab == 1, action: { selectedTab = 1 })
            FriendsTabButton(title: "Requests", icon: "person.crop.circle.badge.plus", isSelected: selectedTab == 2, action: { selectedTab = 2 })
        }
        .padding(.vertical, 8).background(Color.white).cornerRadius(12).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2).padding(.horizontal).padding(.bottom, 8)
    }
}

struct FriendsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View { // Keep as is
        Button(action: action) {
            VStack(spacing: 6) { Image(systemName: icon).font(.system(size: 22)); Text(title).font(.system(size: 12, weight: .medium)) }
            .frame(maxWidth: .infinity).padding(.vertical, 10).foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.lightText)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .overlay(Rectangle().fill(isSelected ? ColorTheme.primary : Color.clear).frame(height: 3).offset(y: 20), alignment: .bottom)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedFriendCard: View {
    let friend: User
    // Use FriendManagementViewModel
    @EnvironmentObject var viewModel: FriendManagementViewModel
    @State private var showingActionSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Profile image logic... (Keep as is)
                 if #available(iOS 17.0, *) { ProfileImageView(imageURL: friend.profileImageURL, size: 60) } else { Circle().fill(ColorTheme.primary.opacity(0.7)).frame(width: 60, height: 60).overlay(Image(systemName: "person.fill").font(.system(size: 25)).foregroundColor(.white)) }

                // Friend info... (Keep as is)
                 VStack(alignment: .leading, spacing: 4) {
                     Text(friend.name).font(.headline).foregroundColor(ColorTheme.text)
                     if let children = friend.children, !children.isEmpty { Text("\(children.count) \(children.count == 1 ? "Child" : "Children")").font(.subheadline).foregroundColor(ColorTheme.lightText) }
                     HStack(spacing: 4) { Image(systemName: "clock").font(.system(size: 12)).foregroundColor(ColorTheme.lightText); Text(formatLastActive(friend.lastActive)).font(.caption).foregroundColor(ColorTheme.lightText) }
                 }

                Spacer()

                // Action buttons... (Keep as is, actions updated below)
                 HStack(spacing: 12) {
                     Button { NotificationCenter.default.post(name: NSNotification.Name("OpenChatWithFriend"), object: nil, userInfo: ["friend": friend]) } label: { Image(systemName: "message.fill").font(.system(size: 16)).foregroundColor(.white).frame(width: 36, height: 36).background(ColorTheme.accent).clipShape(Circle()) }.buttonStyle(PlainButtonStyle())
                     Button { showingActionSheet = true } label: { Image(systemName: "ellipsis").font(.system(size: 20)).foregroundColor(ColorTheme.lightText).frame(width: 36, height: 36).background(Color(.systemGray6)).clipShape(Circle()) }.buttonStyle(PlainButtonStyle())
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
                    .default(Text("View Profile")) {
                         if let friendId = friend.id { NotificationCenter.default.post(name: NSNotification.Name("ViewFriendProfile"), object: nil, userInfo: ["friendId": friendId, "friend": friend]) }
                    },
                    .default(Text("Message")) {
                         NotificationCenter.default.post(name: NSNotification.Name("OpenChatWithFriend"), object: nil, userInfo: ["friend": friend])
                    },
                    .default(Text("Invite to Playdate")) {
                         NotificationCenter.default.post(name: NSNotification.Name("InviteFriendToPlaydate"), object: nil, userInfo: ["friend": friend])
                    },
                    .destructive(Text("Remove Friend")) {
                        // Use the async removeFriend method from FriendManagementViewModel
                        Task {
                            guard let friendId = friend.id else { return }
                            do {
                                try await viewModel.removeFriend(friendId: friendId)
                            } catch {
                                // Error should be displayed by the main view's alert
                                print("❌ Error removing friend \(friendId): \(error)")
                            }
                        }
                    },
                    .cancel()
                ]
            )
        }
        .onTapGesture { // Keep as is
             if let friendId = friend.id { NotificationCenter.default.post(name: NSNotification.Name("ViewFriendProfile"), object: nil, userInfo: ["friendId": friendId, "friend": friend]) }
                 }
    }

    // Modified to handle optional Date
    private func formatLastActive(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" } // Return "Unknown" if date is nil
        let formatter = RelativeDateTimeFormatter(); formatter.unitsStyle = .short; return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FriendRequestCard: View {
    let request: FriendRequestModel
    // Use FriendManagementViewModel
    @EnvironmentObject var viewModel: FriendManagementViewModel
    @State private var sender: User?
    @State private var isResponding = false // Renamed for clarity

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // Profile image logic... (Keep as is)
                 if let sender = sender { if #available(iOS 17.0, *) { ProfileImageView(imageURL: sender.profileImageURL, size: 60) } else { Circle().fill(ColorTheme.primary.opacity(0.7)).frame(width: 60, height: 60).overlay(Image(systemName: "person.fill").font(.system(size: 25)).foregroundColor(.white)) } } else { Circle().fill(Color.gray.opacity(0.3)).frame(width: 60, height: 60).overlay(ProgressView().scaleEffect(0.7)) }

                // Sender info... (Keep as is)
                 VStack(alignment: .leading, spacing: 4) {
                     Text(sender?.name ?? "Loading...").font(.headline).foregroundColor(ColorTheme.text)
                     Text("Wants to be friends").font(.subheadline).foregroundColor(ColorTheme.lightText)
                     HStack(spacing: 4) { Image(systemName: "clock").font(.system(size: 12)).foregroundColor(ColorTheme.lightText); Text(formatDate(request.createdAt)).font(.caption).foregroundColor(ColorTheme.lightText) }
                 }

                Spacer()

                // Action buttons
                if !isResponding { // Use renamed state variable
                    VStack(spacing: 8) {
                        Button("Accept") {
                            respondToRequest(accept: true) // Call unified respond function
                        }
                        .primaryStyle()
                        .padding(.vertical, -6)
                        .frame(width: 80)

                        Button("Decline") {
                            respondToRequest(accept: false) // Call unified respond function
                        }
                        .secondaryStyle()
                        .padding(.vertical, -6)
                        .frame(width: 80)
                    }
                } else {
                    ProgressView() // Show progress while responding
                        .padding(.horizontal)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .task { // Use .task for async fetch
            await fetchSender()
        }
    }

    // Use async fetchSender
    private func fetchSender() async {
        guard !request.senderID.isEmpty else { return }
        let db = Firestore.firestore()
        do {
            let document = try await db.collection("users").document(request.senderID).getDocument()
            // Use Codable conformance directly
            self.sender = try document.data(as: User.self)
        } catch {
            print("❌ Error fetching sender \(request.senderID): \(error.localizedDescription)")
            // Optionally set sender name to "Unknown User" or handle error state
        }
    }

    private func formatDate(_ date: Date) -> String { // Keep as is
        let formatter = RelativeDateTimeFormatter(); formatter.unitsStyle = .short; return formatter.localizedString(for: date, relativeTo: Date())
    }

    // Unified function to respond using FriendManagementViewModel's async method
    private func respondToRequest(accept: Bool) {
        isResponding = true
        Task {
            do {
                try await viewModel.respondToFriendRequest(request: request, accept: accept)
                // Success: Listener updates UI.
                print("✅ Responded to request \(request.id ?? "N/A") successfully.")
            } catch {
                // Failure: Error displayed by main view's alert.
                print("❌ Failed to respond to request \(request.id ?? "N/A"): \(error)")
            }
            // Ensure state is reset
            isResponding = false
        }
    }
}
