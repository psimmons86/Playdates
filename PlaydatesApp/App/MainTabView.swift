import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var activityViewModel: ActivityViewModel

    // Initialize FriendManagementViewModel here
    // It depends on AuthViewModel, which is available as an EnvironmentObject
    @StateObject private var friendManagementViewModel: FriendManagementViewModel

    // Custom initializer to capture authViewModel for friendManagementViewModel initialization
    init(authViewModel: AuthViewModel) {
        _friendManagementViewModel = StateObject(wrappedValue: FriendManagementViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        // Directly use MainContainerView to avoid circular reference
        MainContainerView()
            .environmentObject(authViewModel)
            .environmentObject(locationManager)
            .environmentObject(activityViewModel)
            .environmentObject(friendManagementViewModel) // Inject FriendManagementViewModel
    }
}
