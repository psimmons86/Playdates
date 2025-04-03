import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CoreLocation
// Removed Combine import

@main
struct PlaydatesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Declare StateObjects but initialize them in init() AFTER Firebase config
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var locationManager: LocationManager
    @StateObject private var friendManager: FriendManagementViewModel
    @StateObject private var appActivityViewModel: AppActivityViewModel // Add AppActivityViewModel
    @StateObject private var invitationManager: PlaydateInvitationViewModel // Add Invitation Manager
    @StateObject private var activityViewModel = ActivityViewModel.shared // Add ActivityViewModel singleton
    @StateObject private var mainContainerViewModel = MainContainerViewModel.shared // Add MainContainerViewModel singleton

    init() {
        // --- Firebase Configuration FIRST ---
        print("📱 PlaydatesApp.init: Configuring Firebase...")
        FirebaseApp.configure()
        print("✅ PlaydatesApp.init: Firebase configured.")

        // Configure Firebase Services (Auth, Firestore, Storage)
        // Ensure services are ready before ViewModels access them
        print("🚀 PlaydatesApp.init: Configuring Firebase Services...")
        FirebaseAuthService.shared.configure()
        FirestoreService.shared.configure()
        FirebaseStorageService.shared.configure()
        print("✅ PlaydatesApp.init: Firebase Services configured.")
        // --- End Firebase Configuration ---

        // --- Initialize ViewModels AFTER Firebase Config ---
        // Create instances first
        let authVM = AuthViewModel()
        let friendVM = FriendManagementViewModel(authViewModel: authVM) // Pass authVM here
        let activityVM = AppActivityViewModel(authViewModel: authVM, friendManagementViewModel: friendVM) // Pass authVM and friendVM
        let invitationMgr = PlaydateInvitationViewModel() // Create Invitation Manager
        let locationMgr = LocationManager.shared

        // Assign to StateObject properties
        _authViewModel = StateObject(wrappedValue: authVM)
        _friendManager = StateObject(wrappedValue: friendVM)
        _appActivityViewModel = StateObject(wrappedValue: activityVM)
        _invitationManager = StateObject(wrappedValue: invitationMgr) // Assign Invitation Manager
        _locationManager = StateObject(wrappedValue: locationMgr)
        // _activityViewModel is already initialized via .shared

        // Setup ActivityViewModel AFTER authVM is ready
        ActivityViewModel.shared.setup(authViewModel: authVM)

        print("✅ PlaydatesApp.init: ViewModels initialized and setup.")
        // --- End ViewModel Initialization ---

        // Configure appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            // Show AppContentView directly
            AppContentView()
                .environmentObject(authViewModel)
                .environmentObject(locationManager)
                .environmentObject(friendManager) // Pass friendManager
                .environmentObject(appActivityViewModel) // Pass appActivityViewModel
                .environmentObject(invitationManager) // Inject Invitation Manager
                .environmentObject(activityViewModel) // Inject ActivityViewModel
                .environmentObject(mainContainerViewModel) // Inject MainContainerViewModel
        }
    }

    // Keep configureAppearance as it doesn't involve Firebase
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(ColorTheme.primary) // Use app's primary color
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .black // Change to black for better visibility

        // Configure tab bar appearance
        UITabBar.appearance().tintColor = UIColor(ColorTheme.primary) // Use app's primary color
    }
}

// AppContentView has been moved to PlaydatesApp/App/AppContentView.swift
