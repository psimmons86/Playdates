import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase

// Main tab view that contains all the tabs
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    // Create the view models here instead of passing them in
    @StateObject private var activityViewModel = ActivityViewModel.shared
    @StateObject private var playdateViewModel = PlaydateViewModel.shared
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    
    // Add state to track selected tab
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Show HomeView instead of SocialFeedView
            NavigationView {
                HomeView()
                    .environmentObject(activityViewModel)
                    .environmentObject(playdateViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Explore Tab
            NavigationView {
                ExploreView()
                    .environmentObject(activityViewModel)
                    .environmentObject(playdateViewModel)
            }
            .tabItem {
                Label("Explore", systemImage: "map.fill")
            }
            .tag(1)
            
            // Create Tab - ActivitySearchView is appropriate here
            NavigationView {
                NewPlaydateView()
                    .environmentObject(playdateViewModel)
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle.fill")
            }
            .tag(2)
            
            // Friends Tab - Use the existing FriendsView
            NavigationView {
                FriendsView()
                    .environmentObject(friendshipViewModel)
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .tag(3)
            
            // Profile Tab - Show ProfileView instead of AuthView
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(ColorTheme.primary)
        .onAppear {
            // Apply gradient to tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Add subtle gradient to tab bar
            let tabBarAppearance = UITabBar.appearance()
            tabBarAppearance.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                tabBarAppearance.scrollEdgeAppearance = appearance
            }
            
            // Set tint color
            tabBarAppearance.tintColor = UIColor(ColorTheme.primary)
        }
    }
}
