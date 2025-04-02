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
                            loadData()
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
                                ActivityTabView()
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
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        error = nil
        
        let group = DispatchGroup()
        
        // Fetch user count
        group.enter()
        db.collection("users").getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                self.error = "Error fetching users: \(error.localizedDescription)"
                return
            }
            
            userCount = snapshot?.documents.count ?? 0
        }
        
        // Fetch playdate count
        group.enter()
        db.collection("playdates").getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                self.error = "Error fetching playdates: \(error.localizedDescription)"
                return
            }
            
            playdateCount = snapshot?.documents.count ?? 0
        }
        
        // Fetch activity count
        group.enter()
        db.collection("activities").getDocuments { snapshot, error in
            defer { group.leave() }
            
            if let error = error {
                self.error = "Error fetching activities: \(error.localizedDescription)"
                return
            }
            
            activityCount = snapshot?.documents.count ?? 0
        }
        
        // Fetch activities for the activity tab
        group.enter()
        appActivityViewModel.fetchActivities(limit: 50) // Fetch more for admin view
        group.leave()
        
        group.notify(queue: .main) {
            // If we have no real data, use mock data for testing
            if userCount == 0 && playdateCount == 0 && activityCount == 0 {
                userCount = 24
                playdateCount = 37
                activityCount = 89
                
                if appActivityViewModel.activities.isEmpty {
                    appActivityViewModel.addMockActivities()
                }
            }
            
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
                StatCard(title: "Active Now", value: "3", icon: "circle.fill")
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
                    StatusRow(name: "Push Notifications", status: "Degraded", isOnline: false)
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
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(appActivityViewModel.activities) { activity in
                        ActivityRow(activity: activity)
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
            // In a real app, this would fetch users from Firebase
            // For now, we'll use mock data
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                users = [
                    User(id: "user1", name: "Sarah Johnson", email: "sarah@example.com", createdAt: Date().addingTimeInterval(-86400 * 10), lastActive: Date().addingTimeInterval(-3600)),
                    User(id: "user2", name: "Michael Smith", email: "michael@example.com", createdAt: Date().addingTimeInterval(-86400 * 8), lastActive: Date().addingTimeInterval(-7200)),
                    User(id: "user3", name: "Jessica Williams", email: "jessica@example.com", createdAt: Date().addingTimeInterval(-86400 * 5), lastActive: Date().addingTimeInterval(-10800)),
                    User(id: "user4", name: "David Brown", email: "david@example.com", createdAt: Date().addingTimeInterval(-86400 * 3), lastActive: Date().addingTimeInterval(-86400)),
                    User(id: "user5", name: "Lisa Davis", email: "lisa@example.com", createdAt: Date().addingTimeInterval(-86400), lastActive: Date().addingTimeInterval(-172800)),
                    User(id: "admin", name: "Admin User", email: "hadroncollides@icloud.com", createdAt: Date().addingTimeInterval(-86400 * 30), lastActive: Date())
                ]
                isLoading = false
            }
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
                    .foregroundColor(ColorTheme.mediumText)
                
                // Joined date
                Text("Joined \(formattedDate(user.createdAt))")
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
}

// MARK: - Preview
struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppActivityViewModel.shared)
    }
}
