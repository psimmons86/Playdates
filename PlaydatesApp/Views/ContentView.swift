import SwiftUI
import Firebase

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var locationManager = LocationManager()
    
    // Track onboarding state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            if authViewModel.isSignedIn {
                // User is signed in - show main app
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(locationManager)
            } else if !hasCompletedOnboarding || showingOnboarding {
                // User hasn't completed onboarding - show onboarding flow
                OnboardingCoordinator(onComplete: {
                    hasCompletedOnboarding = true
                    showingOnboarding = false
                })
                .transition(.opacity)
            } else {
                // User has completed onboarding but isn't signed in - show auth view
                AuthView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.isSignedIn)
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .animation(.easeInOut, value: showingOnboarding)
        .overlay(alignment: .topTrailing) {
            // Debug button to reset onboarding (only in debug builds)
            #if DEBUG
            if !showingOnboarding && hasCompletedOnboarding && !authViewModel.isSignedIn {
                Button(action: {
                    showingOnboarding = true
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .padding(8)
                        .background(Color.black.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding()
            }
            #endif
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
