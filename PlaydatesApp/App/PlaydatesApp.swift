import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CoreLocation

@main
struct PlaydatesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var locationManager = LocationManager.shared
    
    init() {
        // Set up appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
                .environmentObject(authViewModel)
                .environmentObject(locationManager)
        }
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ColorTheme.primary)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
        
        // Configure tab bar appearance
        UITabBar.appearance().tintColor = UIColor(ColorTheme.primary)
    }
}

struct AppContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var groupViewModel = GroupViewModel.shared
    @StateObject private var resourceViewModel = ResourceViewModel.shared
    @StateObject private var communityEventViewModel = CommunityEventViewModel.shared
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isSignedIn {
                MainTabView()
                    .environmentObject(groupViewModel)
                    .environmentObject(resourceViewModel)
                    .environmentObject(communityEventViewModel)
            } else {
                AuthView()
            }
        }
        .onAppear {
            // Check if user is already logged in
            authViewModel.checkAuthState()
            
            // Load mock data for Community features
            loadMockData()
        }
    }
    
    private func loadMockData() {
        // Add a slight delay to ensure view models are fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Use the AppDelegate's loadMockData method
            AppDelegate.shared?.loadMockData()
        }
    }
}
