import SwiftUI
import Foundation

struct ActivityFeedView: View {
    // Already using @EnvironmentObject, which is correct. No change needed here.
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel
    // Remove the local isLoading state, rely on viewModel.isLoading
    // @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section matching screenshot
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent Activity")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "4A4A4A"))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }

            // Use viewModel.isLoading directly
            if appActivityViewModel.isLoading {
                LoadingView()
            } else if appActivityViewModel.activities.isEmpty {
                EmptyStateView()
            } else {
                ActivityList()
            }
        }
        .background(Color(hex: "F8F8F8"))
        // Remove onAppear and loadActivities(), as the ViewModel handles fetching automatically.
    }
}

// MARK: - Supporting Views

private struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading activity feed...")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
            }
            .padding(.vertical, 30)
            Spacer()
        }
    }
}

private struct EmptyStateView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(ColorTheme.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bell.badge")
                    .font(.system(size: 36))
                    .foregroundColor(ColorTheme.primary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            Text("No Recent Activity")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.darkPurple)
            
            Text("Activity from you and your friends will appear here")
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: {
                // This is a placeholder action that would typically create a new activity
                // In a real app, this would navigate to create a playdate or other action
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create a Playdate")
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(ColorTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .padding(.top, 10)
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

// Use ScrollView + LazyVStack for efficient loading
private struct ActivityList: View {
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) { // No spacing between cards, handled by card padding
                ForEach(appActivityViewModel.activities) { activity in
                    SocialFeedCardView(activity: activity)
                        // Add potential navigation link or tap gesture here if needed
                }
            }
            .padding(.top, 8) // Add some padding at the top of the list
        }
    }
}


// MARK: - Preview
struct ActivityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        // Create necessary mock ViewModels for the preview
        let authVM = AuthViewModel()
        let friendVM = FriendManagementViewModel(authViewModel: authVM)
        let activityVM = AppActivityViewModel(authViewModel: authVM, friendManagementViewModel: friendVM)
        // Add some mock data to activityVM if needed for preview
        activityVM.activities = [
             AppActivity(id: "preview1", type: .newPlaydate, title: "Park Fun", description: "Let's meet at Central Park playground tomorrow at 10 AM!", timestamp: Date().addingTimeInterval(-3600*2), userID: "user1", userName: "Alice Smith", userProfileImageURL: nil, contentImageURL: nil, likeCount: 5, commentCount: 2),
             AppActivity(id: "preview2", type: .newFriend, title: "New Connection", description: "You and Bob Johnson are now friends.", timestamp: Date().addingTimeInterval(-86400), userID: "user2", userName: "Bob Johnson", userProfileImageURL: nil),
             AppActivity(id: "preview3", type: .childAdded, title: "Family Update", description: "Charlie added their child, Leo.", timestamp: Date().addingTimeInterval(-86400*3), userID: "user3", userName: "Charlie Brown", userProfileImageURL: nil)
        ]

        return NavigationView { // Wrap in NavigationView for title context
             ActivityFeedView()
                 .environmentObject(authVM) // Provide AuthViewModel
                 .environmentObject(friendVM) // Provide FriendManagementViewModel
                 .environmentObject(activityVM) // Provide AppActivityViewModel
        }
    }
}

// Note: ActivityRow and its preview are removed as they are replaced by SocialFeedCardView
