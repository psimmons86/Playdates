import SwiftUI

struct AppContentView: View {
    // Receive shared AuthViewModel from the environment
    @EnvironmentObject var authViewModel: AuthViewModel
    // Removed friendManager EnvironmentObject as it's now initialized in MainTabView

    // State to manage minimum loading screen display time
    @State private var showContent = false

    var body: some View {
        // Show loading view until initial check is complete AND minimum time has passed
        if !showContent {
            CreativeLoadingView()
                .onAppear {
                    // Wait for auth check AND a minimum delay (e.g., 1.5 seconds)
                    Task {
                        // Wait until the initial auth check is marked complete
                        while !authViewModel.isInitialAuthCheckComplete {
                            try? await Task.sleep(nanoseconds: 100_000_000) // Sleep 100ms
                        }
                        // Add a minimum display duration
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds delay

                        // Now allow content to show
                        withAnimation {
                            showContent = true
                        }
                    }
                }
        } else {
            // Once ready, decide based on sign-in status
            // Once the initial check is complete, decide based on sign-in status
            // Once loading is done OR user is signed in, show the main content
            if authViewModel.isSignedIn {
                // Pass authViewModel to MainTabView initializer
                MainTabView(authViewModel: authViewModel)
            } else {
                // If not loading and not signed in, show AuthView
                AuthView()
            }
        }
        // No .onAppear needed here for auth setup
        // No need to pass environment objects down further here,
        // MainTabView and its children will inherit them.
    }
}

// Optional: Add a preview provider if useful for AppContentView specifically
// struct AppContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         // Need to provide mock environment objects for preview
//         AppContentView()
//             .environmentObject(AuthViewModel()) // Provide mock/dummy instances
//             .environmentObject(FriendManagementViewModel(authViewModel: AuthViewModel())) // Provide mock/dummy instances
//     }
// }
