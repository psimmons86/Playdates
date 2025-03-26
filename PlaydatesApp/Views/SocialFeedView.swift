import SwiftUI

// MARK: - Social Activity Feed

struct SocialFeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SocialFeedViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if viewModel.feedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.wave.2")
                            .font(.system(size: 50))
                            .foregroundColor(ColorTheme.lightText)
                        
                        Text("No Activity Yet")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Text("Connect with friends and join playdates to see activity in your feed")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button(action: {
                            // Find friends
                        }) {
                            Text("Find Friends")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(ColorTheme.primary)
                                .cornerRadius(20)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.feedItems) { item in
                                FeedItemCard(item: item)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshFeed()
                    }
                }
            }
            .navigationTitle("Activity Feed")
            .onAppear {
                viewModel.loadFeed()
            }
        }
    }
}

class SocialFeedViewModel: ObservableObject {
    @Published var feedItems: [ActivityFeedItem] = []
    @Published var isLoading = false
    
    func loadFeed() {
        isLoading = true
        
        // In a real app, this would fetch from a database
        // For demo purposes, we'll use mock data with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.feedItems = self.generateMockFeedItems()
            self.isLoading = false
        }
    }
    
    func refreshFeed() async {
        // Simulate an async refresh
        isLoading = true
        
        // Wait for 1 second to simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update the feed with new items
        let newItems = generateMockFeedItems(count: 2, newer: true)
        
        // Update on main thread
        DispatchQueue.main.async {
            self.feedItems.insert(contentsOf: newItems, at: 0)
            self.isLoading = false
        }
    }
    
    private func generateMockFeedItems(count: Int = 5, newer: Bool = false) -> [ActivityFeedItem] {
        var items: [ActivityFeedItem] = []
        
        let activityTypes: [FeedActivityType] = [.friendJoined, .newPlaydate, .playdateInvite, .friendActivity]
        let names = ["Emma Johnson", "James Smith", "Sophia Martinez", "Oliver Brown", "Ava Williams"]
        let activityDescriptions = [
            "went to the playground",
            "is hosting a playdate",
            "joined the swimming class",
            "invited you to the zoo",
            "is attending the museum trip"
        ]
        
        for i in 0..<count {
            let activityType = activityTypes.randomElement()!
            let timestamp = newer ? 
                Date().addingTimeInterval(-Double(i) * 3600) : // Recent items for refresh
                Date().addingTimeInterval(-Double(Int.random(in: 1...72)) * 3600) // Random times for initial load
                
            let item = ActivityFeedItem(
                id: UUID().uuidString,
                activityType: activityType,
                userName: names.randomElement()!,
                userID: UUID().uuidString,
                activityDescription: activityDescriptions.randomElement()!,
                timestamp: timestamp,
                relatedPlaydateID: UUID().uuidString
            )
            
            items.append(item)
        }
        
        return items
    }
}

struct ActivityFeedItem: Identifiable {
    let id: String
    let activityType: FeedActivityType
    let userName: String
    let userID: String
    let activityDescription: String
    let timestamp: Date
    var relatedPlaydateID: String? = nil
}

enum FeedActivityType {
    case friendJoined
    case newPlaydate
    case playdateInvite
    case friendActivity
    
    var icon: String {
        switch self {
        case .friendJoined:
            return "person.badge.plus"
        case .newPlaydate:
            return "calendar.badge.plus"
        case .playdateInvite:
            return "envelope"
        case .friendActivity:
            return "person.2"
        }
    }
    
    var color: Color {
        switch self {
        case .friendJoined:
            return ColorTheme.primary
        case .newPlaydate:
            return ColorTheme.highlight
        case .playdateInvite:
            return ColorTheme.accent
        case .friendActivity:
            return ColorTheme.primary.opacity(0.8)
        }
    }
}

struct FeedItemCard: View {
    let item: ActivityFeedItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(item.activityType.color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.activityType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.userName)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Spacer()
                    
                    Text(timeAgo(date: item.timestamp))
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                // Activity description
                Text(activityDescription)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var activityDescription: String {
        switch item.activityType {
        case .friendJoined:
            return "joined Playdates App"
        case .newPlaydate:
            return "created a new playdate"
        case .playdateInvite:
            return "invited you to a playdate"
        case .friendActivity:
            return item.activityDescription
        }
    }
    
    // Helper function to format time ago
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
