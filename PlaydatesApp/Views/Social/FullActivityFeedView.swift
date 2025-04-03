import SwiftUI

// Placeholder View for Full Activity Feed
struct FullActivityFeedView: View {
     // Get the ViewModel from the environment
     @EnvironmentObject var appActivityViewModel: AppActivityViewModel

     var body: some View {
         ScrollView {
             // ActivityFeedView will get the viewModel from the environment automatically
             ActivityFeedView()
         }
         .navigationTitle("All Activity")
         // Remove the onAppear fetch, as the ViewModel now fetches automatically
         // when the user logs in or friends change.
     }
}

// Optional: Add a preview provider
#if DEBUG
struct FullActivityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        // Create necessary mock ViewModels for the preview
        let authVM = AuthViewModel()
        let friendVM = FriendManagementViewModel(authViewModel: authVM)
        let activityVM = AppActivityViewModel(authViewModel: authVM, friendManagementViewModel: friendVM)
        // Add some mock data to activityVM if needed for preview
        activityVM.activities = [
             AppActivity(id: "preview1", type: .newPlaydate, title: "Park Fun", description: "Let's meet at Central Park playground tomorrow at 10 AM!", timestamp: Date().addingTimeInterval(-3600*2), userID: "user1", userName: "Alice Smith", userProfileImageURL: nil, contentImageURL: nil, likeCount: 5, commentCount: 2),
             AppActivity(id: "preview2", type: .newFriend, title: "New Connection", description: "You and Bob Johnson are now friends.", timestamp: Date().addingTimeInterval(-86400), userID: "user2", userName: "Bob Johnson", userProfileImageURL: nil)
        ]


        return NavigationView { // Wrap in NavigationView for preview context
            FullActivityFeedView()
                .environmentObject(authVM) // Provide AuthViewModel
                .environmentObject(friendVM) // Provide FriendManagementViewModel
                .environmentObject(activityVM) // Provide AppActivityViewModel
        }
    }
}
#endif
