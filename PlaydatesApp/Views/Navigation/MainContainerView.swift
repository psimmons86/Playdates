import SwiftUI
import Firebase

// Regular import for SocialTabView
import SwiftUI

struct MainContainerView: View {
    @StateObject private var viewModel = MainContainerViewModel.shared

    // Environment Objects needed by subviews
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityViewModel: ActivityViewModel // Changed to EnvironmentObject
    @StateObject private var playdateViewModel = PlaydateViewModel()
    // Replaced FriendshipViewModel with FriendManagementViewModel and PlaydateInvitationViewModel
    // Receive friendManager from the environment now
    @EnvironmentObject var friendManager: FriendManagementViewModel
    @EnvironmentObject var invitationManager: PlaydateInvitationViewModel // Now injected from PlaydatesApp
    // ChatViewModel is typically instantiated within specific chat views, not globally here.
    @StateObject private var notificationViewModel = NotificationViewModel() // Use default init
    @StateObject private var groupViewModel = GroupViewModel.shared
    @StateObject private var resourceViewModel = ResourceViewModel.shared
    @StateObject private var communityEventViewModel = CommunityEventViewModel.shared
    // Get AppActivityViewModel from the environment
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel

    // State for navigation using .sheet(item:)
    @State private var selectedFriendForProfile: User? = nil // Optional User triggers profile sheet
    @State private var selectedFriendForChat: User? = nil    // Optional User triggers chat sheet
    @State private var selectedFriendForInvite: User? = nil   // Optional User triggers invite sheet
    // State for programmatic NavigationLink
    @State private var selectedPlaydateIDForDetail: String? = nil // Optional String triggers playdate detail navigation

    // Removed custom init()

    // Computed property for menu width
    private var menuWidth: CGFloat {
        UIScreen.main.bounds.width * 0.75 // 75% of screen width
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background NavigationLink for programmatic push
                // Note: The label content doesn't matter much as it's hidden/zero-sized
                NavigationLink(
                    destination: PlaydateDetailView(playdateId: selectedPlaydateIDForDetail ?? ""), // Destination view
                    tag: selectedPlaydateIDForDetail ?? "", // Tag must match the ID
                    selection: $selectedPlaydateIDForDetail // Binding to the state variable
                ) {
                    EmptyView() // The link itself is invisible
                }
                .hidden() // Keep it out of the layout

                // Main Content View
                VStack {
                    if viewModel.selectedView == .home {
                        HomeView()
                            .environmentObject(activityViewModel)
                            .environmentObject(playdateViewModel)
                    } else if viewModel.selectedView == .suggestions { // Add case for Suggestions
                        WeatherSuggestionView()
                            .environmentObject(activityViewModel) // Pass ActivityViewModel
                    } else if viewModel.selectedView == .explore {
                        ExploreView()
                            .environmentObject(activityViewModel)
                            .environmentObject(playdateViewModel)
                    } else if viewModel.selectedView == .social {
                        SocialTabView()
                            // Pass the new friendManager instead of friendshipViewModel
                            .environmentObject(friendManager)
                            // appActivityViewModel is already in the environment
                            // Also pass invitationManager if needed by SocialTabView or its children
                            .environmentObject(invitationManager)
                    } else if viewModel.selectedView == .community {
                        CommunityTabView()
                            .environmentObject(groupViewModel)
                            .environmentObject(resourceViewModel)
                            .environmentObject(communityEventViewModel)
                    } else if viewModel.selectedView == .create {
                        NewPlaydateView()
                            .environmentObject(playdateViewModel)
                    } else if viewModel.selectedView == .profile {
                        // Show current user's profile
                        ProfileView()
                            .environmentObject(authViewModel)
                            .environmentObject(activityViewModel) // Inject ActivityViewModel
                    } else if viewModel.selectedView == .wishlist { // Add case for Wishlist
                        WishlistView()
                            .environmentObject(activityViewModel) // Pass ActivityViewModel
                    } else if viewModel.selectedView == .notifications { // Add case for Notifications
                        NotificationCenterView()
                            .environmentObject(notificationViewModel) // Pass the @StateObject instance
                            .environmentObject(authViewModel)
                    } else if viewModel.selectedView == .admin {
                        if authViewModel.user?.email == "hadroncollides@icloud.com" {
                            AdminView()
                                .environmentObject(authViewModel)
                                // appActivityViewModel is already in the environment
                        } else {
                            Text("Access Denied")
                                .navigationTitle("Admin")
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
                // Pass necessary environment objects down
                .environmentObject(friendManager)
                .environmentObject(invitationManager)
                .disabled(viewModel.isShowingSideMenu)
                .blur(radius: viewModel.isShowingSideMenu ? 3 : 0)

                // Side Menu View
                if viewModel.isShowingSideMenu {
                    // Dimming overlay
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                viewModel.isShowingSideMenu = false
                            }
                        }

                    SideMenuView(selectedView: $viewModel.selectedView, isShowing: $viewModel.isShowingSideMenu)
                        .environmentObject(authViewModel)
                        .frame(width: menuWidth)
                        .offset(x: -UIScreen.main.bounds.width / 2 + menuWidth / 2)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle(viewModel.selectedView.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.isShowingSideMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.white) // Use white as requested by the user
                        .font(.system(size: 28, weight: .bold)) // Make the icon larger and bolder
                        .padding(5) // Add padding around the icon
                        .overlay( // Add badge overlay
                            NotificationBadge(count: notificationViewModel.unreadCount) // Use the count from NotificationViewModel
                                .offset(x: 18, y: -15), // Adjust position as needed
                            alignment: .topTrailing
                        )
                }
            )
            // Removed hidden NavigationLink for profile
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Setup ViewModels that depend on AuthViewModel
            notificationViewModel.setup(authViewModel: authViewModel)
            // Removed activityViewModel.setup() - now handled in PlaydatesApp
            setupNotificationObservers()
        }
        .onDisappear {
            removeNotificationObservers()
        }
        // Sheets triggered by optional User state variables
        .sheet(item: $selectedFriendForProfile) { friend in
            // Profile View presented as a sheet
            NavigationView { // Embed in NavigationView for title/buttons if needed inside sheet
                ProfileView(userId: friend.id, user: friend) // Pass friend data
                    .environmentObject(authViewModel) // Pass needed environment objects
                    .environmentObject(activityViewModel) // Inject ActivityViewModel
                    .navigationBarItems(leading: Button("Done") { selectedFriendForProfile = nil }) // Add Done button
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear { print("➡️ Presenting ProfileView sheet for \(friend.name)") }
        }
        .sheet(item: $selectedFriendForChat) { friend in
             EnhancedChatView(recipientUser: friend)
                 .onAppear { print("➡️ Presenting EnhancedChatView sheet for \(friend.name)") }
                 .environmentObject(authViewModel)
         }
         .sheet(item: $selectedFriendForInvite) { friend in
             InviteToPlaydateView(friend: friend)
                 .onAppear { print("➡️ Presenting InviteToPlaydateView sheet for \(friend.name)") }
                 .environmentObject(authViewModel)
         }
    }

    // Set up notification observers for friend interactions
    private func setupNotificationObservers() {
        print("➡️ MainContainerView: Setting up notification observers...") // Log setup
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ViewFriendProfile"),
            object: nil,
            queue: .main
        ) { notification in
            print("🔔 MainContainerView: Received ViewFriendProfile notification") // Log received
            if let userInfo = notification.userInfo,
               let friend = userInfo["friend"] as? User {
                print("  👤 Friend to view: \(friend.name) (ID: \(friend.id ?? "N/A"))")
                // Set the optional User state to trigger the sheet(item:)
                print("  🔄 Setting selectedFriendForProfile (Current ID: \(self.selectedFriendForProfile?.id ?? "nil"))")
                self.selectedFriendForProfile = friend
                print("  ✅ Set selectedFriendForProfile to \(friend.name)")
            } else {
                print("  ⚠️ Failed to extract friend info from ViewFriendProfile notification.") // Log failure
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenChatWithFriend"),
            object: nil,
            queue: .main
        ) { notification in
            print("🔔 MainContainerView: Received OpenChatWithFriend notification") // Log received
            // Expect a User object now
            if let userInfo = notification.userInfo,
               let friend = userInfo["friend"] as? User {
                print("  👤 Friend to chat with: \(friend.name) (ID: \(friend.id ?? "N/A"))")
                // Set the optional User state to trigger the sheet(item:)
                print("  🔄 Setting selectedFriendForChat (Current ID: \(self.selectedFriendForChat?.id ?? "nil"))")
                self.selectedFriendForChat = friend
                print("  ✅ Set selectedFriendForChat to \(friend.name)")
            } else {
                 print("  ⚠️ Failed to extract friend info from OpenChatWithFriend notification.") // Log failure
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InviteFriendToPlaydate"),
            object: nil,
            queue: .main
        ) { notification in
             print("🔔 MainContainerView: Received InviteFriendToPlaydate notification") // Log received
            // Expect a User object now
            if let userInfo = notification.userInfo,
               let friend = userInfo["friend"] as? User {
                 print("  👤 Friend to invite: \(friend.name) (ID: \(friend.id ?? "N/A"))")
                 // Set the optional User state to trigger the sheet(item:)
                 print("  🔄 Setting selectedFriendForInvite (Current ID: \(self.selectedFriendForInvite?.id ?? "nil"))")
                 self.selectedFriendForInvite = friend
                 print("  ✅ Set selectedFriendForInvite to \(friend.name)")
            } else {
                 print("  ⚠️ Failed to extract friend info from InviteFriendToPlaydate notification.") // Log failure
            }
        }

        // Observer for navigating to Playdate Detail
        NotificationCenter.default.addObserver(
            forName: .navigateToPlaydateDetail, // Use the name defined in NotificationCenterView
            object: nil,
            queue: .main
        ) { notification in
            print("🔔 MainContainerView: Received navigateToPlaydateDetail notification")
            if let userInfo = notification.userInfo,
               let playdateID = userInfo["playdateID"] as? String {
                print("  🆔 Playdate ID to view: \(playdateID)")
                // Set the state variable to trigger the NavigationLink
                self.selectedPlaydateIDForDetail = playdateID
                print("  ✅ Set selectedPlaydateIDForDetail to \(playdateID)")
            } else {
                print("  ⚠️ Failed to extract playdateID from navigateToPlaydateDetail notification.")
            }
        }
    }

    // Remove notification observers
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ViewFriendProfile"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("OpenChatWithFriend"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("InviteFriendToPlaydate"), object: nil)
        NotificationCenter.default.removeObserver(self, name: .navigateToPlaydateDetail, object: nil) // Remove the new observer
    }
}
