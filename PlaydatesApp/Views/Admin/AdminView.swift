import SwiftUI
import Firebase
import FirebaseFirestore

struct AdminView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel

    @State private var selectedTab = 0
    @State private var userCount = 0
    @State private var playdateCount = 0
    @State private var activityCount = 0
    @State private var isLoading = true
    @State private var error: String?

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            VStack {
                // Admin header
                HStack {
                    Text("Admin Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkText)

                    Spacer()

                    Image(systemName: "shield.fill")
                        .font(.title)
                        .foregroundColor(ColorTheme.primary)
                }
                .padding(.horizontal)
                .padding(.top)

                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Activity").tag(1)
                    Text("Users").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if isLoading {
                    Spacer()
                    ProgressView("Loading admin data...")
                    Spacer()
                } else if let error = error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)

                        Text("Error Loading Data")
                            .font(.headline)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            // Wrap async call in Task for button action
                            Task {
                                await loadData()
                            }
                        }) {
                            Text("Try Again")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(ColorTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    // Content based on selected tab
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case 0:
                                OverviewTabView(
                                    userCount: userCount,
                                    playdateCount: playdateCount,
                                    activityCount: activityCount
                                )
                            case 1:
                                ActivityTabView() // Uses SocialFeedCardView internally now
                            case 2:
                                UsersTabView()
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Admin")
        .onAppear {
            // Wrap async call in Task
            Task {
                await loadData()
            }
        }
    }

    // Make loadData async and run on MainActor for UI updates
    @MainActor
    private func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch counts concurrently using async let
            async let userDocs = db.collection("users").getDocuments()
            async let playdateDocs = db.collection("playdates").getDocuments()
            async let activityDocs = db.collection("activities").getDocuments()

            // Await counts
            let userSnapshot = try await userDocs
            userCount = userSnapshot.count

            let playdateSnapshot = try await playdateDocs
            playdateCount = playdateSnapshot.count

            let activitySnapshot = try await activityDocs
            activityCount = activitySnapshot.count

            // Fetch activities (already runs on MainActor due to ViewModel annotation)
            await appActivityViewModel.fetchActivities(limit: 50)

            // Check for errors from activity fetch
            if let activityError = appActivityViewModel.error {
                 // Prioritize showing this error if it occurred
                 self.error = "Error fetching activities: \(activityError)"
            }

            isLoading = false

        } catch {
            // Catch errors from fetching counts
            self.error = "Error loading counts: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Tab Views

struct OverviewTabView: View {
    let userCount: Int
    let playdateCount: Int
    let activityCount: Int

    var body: some View {
        VStack(spacing: 20) {
            // Stats cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "Users", value: "\(userCount)", icon: "person.fill")
                StatCard(title: "Playdates", value: "\(playdateCount)", icon: "calendar")
                StatCard(title: "Activities", value: "\(activityCount)", icon: "bell.fill")
                StatCard(title: "Active Now", value: "3", icon: "circle.fill") // Placeholder
            }

            // Recent activity chart (placeholder)
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkText)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ColorTheme.primary)
                                .frame(width: 30, height: CGFloat([20, 45, 30, 60, 35, 50, 25][index]))

                            Text("\(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][index])")
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                    }
                }
                .frame(height: 80)
                .padding(.vertical)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

            // System status
            VStack(alignment: .leading, spacing: 12) {
                Text("System Status")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkText)

                VStack(spacing: 12) {
                    StatusRow(name: "Firebase", status: "Online", isOnline: true)
                    StatusRow(name: "Storage", status: "Online", isOnline: true)
                    StatusRow(name: "Authentication", status: "Online", isOnline: true)
                    StatusRow(name: "Push Notifications", status: "Degraded", isOnline: false) // Placeholder
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct ActivityTabView: View {
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent App Activity")
                .font(.headline)
                .foregroundColor(ColorTheme.darkText)

            if appActivityViewModel.activities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.lightText)

                    Text("No Activity Found")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkText)

                    Text("There is no recent activity to display")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
            } else {
                // Use the new SocialFeedCardView here
                LazyVStack(spacing: 0) { // Use spacing 0 as card handles padding
                    ForEach(appActivityViewModel.activities) { activity in
                        SocialFeedCardView(activity: activity)
                            // Optionally, add admin-specific actions or details here
                    }
                }
            }
        }
    }
}

struct UsersTabView: View {
    @State private var users: [User] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Registered Users")
                .font(.headline)
                .foregroundColor(ColorTheme.darkText)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading users...")
                    Spacer()
                }
                .padding(.vertical, 30)
            } else if users.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.lightText)

                    Text("No Users Found")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkText)

                    Text("There are no registered users to display")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(users) { user in
                        UserRow(user: user)
                    }
                }
            }
        }
        .onAppear {
            fetchUsers()
        }
    }

    private func fetchUsers() {
        isLoading = true
        Firestore.firestore().collection("users")
            .order(by: "lastActive", descending: true) // Order by last active date
            .limit(to: 100) // Limit results for performance
            .getDocuments { snapshot, error in
                isLoading = false // Set loading false regardless of outcome here
                if let error = error {
                    print("❌ Error fetching users for admin view: \(error.localizedDescription)")
                    // Optionally set an error state to display to the admin
                    self.users = []
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No user documents found.")
                    self.users = []
                    return
                }

                self.users = documents.compactMap { doc -> User? in
                    do {
                        return try doc.data(as: User.self)
                    } catch {
                        print("❌ Failed to decode user document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                print("✅ Fetched \(self.users.count) users for admin view.")
            }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ColorTheme.primary)

                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkText)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ColorTheme.darkPurple)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatusRow: View {
    let name: String
    let status: String
    let isOnline: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(ColorTheme.darkText)

            Spacer()

            HStack {
                Circle()
                    .fill(isOnline ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(status)
                    .font(.subheadline)
                    .foregroundColor(isOnline ? Color.green : Color.orange)
            }
        }
    }
}

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            // User avatar
            ZStack {
                Circle()
                    .fill(ColorTheme.primary.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text(user.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ColorTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkText)

                // Email
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)

                // Joined date
                // Provide a default Date() if createdAt is nil
                Text("Joined: \(formattedDate(user.createdAt ?? Date()))")
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
                // Last Active date
                // Provide default Date() if lastActive is nil
                Text("Last Active: \(formattedDate(user.lastActive ?? Date(), dateStyle: .short, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
            }

            Spacer()

            // Admin badge for admin user
            if user.email == "hadroncollides@icloud.com" {
                Image(systemName: "shield.fill")
                    .foregroundColor(ColorTheme.primary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // Overload for different styles
    private func formattedDate(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: date)
    }
}

// MARK: - Preview
// Re-applying the corrected preview provider just in case
struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        // Create necessary mock ViewModels for the preview
            let authVM = AuthViewModel()
            // Optionally set admin user for preview
            // Removed isAdmin: true as it's likely not part of the User initializer anymore
            authVM.user = User(id: "adminPreview", name: "Admin Preview", email: "admin@preview.com")

            let friendVM = FriendManagementViewModel(authViewModel: authVM)
        // Optionally add mock friends for preview if needed by activityVM logic
        // friendVM.friends = [...]

        let activityVM = AppActivityViewModel(authViewModel: authVM, friendManagementViewModel: friendVM)
        // Optionally add mock activities for preview
        // activityVM.activities = [...]

        return NavigationView { // Wrap in NavigationView for better preview context
            AdminView()
                .environmentObject(authVM)
                .environmentObject(activityVM) // Inject the correctly initialized activityVM
                // FriendManagementViewModel might also be needed if AdminView uses it directly
                .environmentObject(friendVM)
        }
    }
}
