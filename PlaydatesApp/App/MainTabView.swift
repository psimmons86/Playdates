import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit

// Main tab view that contains all the tabs
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    // Create the view models here instead of passing them in
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var playdateViewModel = PlaydateViewModel()
    @StateObject private var friendshipViewModel = FriendshipViewModel()
    
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .environmentObject(activityViewModel)
                .environmentObject(playdateViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Explore Tab
            ExploreView()
                .environmentObject(activityViewModel)
                .environmentObject(playdateViewModel)
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
            
            // Create Tab
            NewPlaydateView()
                .environmentObject(playdateViewModel)
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
            
            // Friends Tab
            FriendsView()
                .environmentObject(friendshipViewModel)
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            // Profile Tab
            ProfileView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(ColorTheme.primary)
    }
}

// Home Tab View
struct HomeView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Text("Find fun activities for your kids")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Playdates
                    Text("Upcoming Playdates")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if playdateViewModel.playdates.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text("No upcoming playdates")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Action to create playdate
                            }) {
                                Text("Create Playdate")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(ColorTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(playdateViewModel.playdates.prefix(5)) { playdate in
                                    PlaydateCard(playdate: playdate)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Popular Activities
                    Text("Popular Activities")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(activityViewModel.activities.prefix(3)) { activity in
                        HomeActivityCard(activity: activity)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .onAppear {
                activityViewModel.fetchActivities()
                playdateViewModel.fetchPlaydates()
            }
        }
    }
}

// Create Playdate View
struct NewPlaydateView: View {
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var location = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Location", text: $location)
                }
                
                Section {
                    Button(action: {
                        // Create playdate
                        guard let userID = authViewModel.user?.id else { return }
                        
                        let playdate = Playdate(
                            id: nil,
                            hostID: userID,
                            title: title,
                            description: description,
                            activityType: "playdate",
                            location: nil,
                            address: location,
                            startDate: date,
                            endDate: date.addingTimeInterval(7200), // 2 hours later
                            attendeeIDs: [userID],
                            isPublic: true
                        )
                        
                        playdateViewModel.createPlaydate(playdate) { _ in
                            // Reset form
                            title = ""
                            description = ""
                            date = Date()
                            location = ""
                        }
                    }) {
                        Text("Create Playdate")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
            .navigationTitle("Create Playdate")
        }
    }
}

// Profile View
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Profile image
                        Circle()
                            .fill(ColorTheme.primary.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ColorTheme.primary)
                            )
                        
                        // User name
                        Text(authViewModel.currentUser?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        // User info
                        Text(authViewModel.currentUser?.email ?? "user@example.com")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Children section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Children")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        if let children = authViewModel.currentUser?.children, !children.isEmpty {
                            ForEach(children, id: \.id) { child in
                                ChildProfileCard(child: child)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "person.and.person")
                                    .font(.system(size: 40))
                                    .foregroundColor(ColorTheme.lightText)
                                
                                Text("No children added yet")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    // Navigate to ChildProfileSetupView
                                    let childSetupView = ChildProfileSetupView(
                                        onComplete: {
                                            // Child will be added through the ChildProfileSetupView
                                            // No need to manually refresh user data as addChild updates the user property
                                        },
                                        onSkip: {
                                            // Do nothing on skip
                                        }
                                    )
                                    
                                    // Create a UIHostingController to present the view
                                    let hostingController = UIHostingController(rootView: childSetupView)
                                    
                                    // Get the current UIViewController
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootViewController = windowScene.windows.first?.rootViewController {
                                        rootViewController.present(hostingController, animated: true)
                                    }
                                }) {
                                    Text("Add Child")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(ColorTheme.primary)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Settings section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        SettingsRow(icon: "gear", title: "Account Settings")
                        SettingsRow(icon: "bell", title: "Notifications")
                        SettingsRow(icon: "lock", title: "Privacy")
                        SettingsRow(icon: "questionmark.circle", title: "Help & Support")
                        
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.red)
                                
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.lightText)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
        }
    }
}

// Helper Views

struct ChildProfileCard: View {
    let child: Child
    
    var body: some View {
        HStack(spacing: 16) {
            // Child image
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(ColorTheme.accent)
                )
            
            // Child info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text("\(child.age) years old")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
            }
            
            Spacer()
            
            // Edit button
            Button(action: {
                // Edit action
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(ColorTheme.primary)
                    .padding(8)
                    .background(ColorTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ColorTheme.primary)
            
            Text(title)
                .foregroundColor(ColorTheme.darkPurple)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
        }
        .padding(.vertical, 8)
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ColorTheme.primary : ColorTheme.primary.opacity(0.1))
                .foregroundColor(isSelected ? .white : ColorTheme.primary)
                .cornerRadius(20)
        }
    }
}

// HomeActivityCard (renamed from ExploreActivityCard to fix redeclaration)
struct HomeActivityCard: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Activity icon
                Circle()
                    .fill(ColorTheme.primary)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: activity.type.iconName)
                            .foregroundColor(.white)
                    )
                
                // Activity details
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text(activity.location.name)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                Spacer()
                
                // Distance or rating
                if let rating = activity.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.darkPurple)
                    }
                }
            }
            
            // Tags
            HStack {
                Text(activity.type.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.accent.opacity(0.3))
                    .foregroundColor(ColorTheme.darkPurple)
                    .cornerRadius(8)
                
                if let tags = activity.tags, !tags.isEmpty {
                    Text(tags[0])
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.secondary)
                        .foregroundColor(ColorTheme.darkPurple)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// FriendRequestCard - Modified to handle FriendRequestModel (from FriendshipViewModel)
struct FriendRequestCard: View {
    // Changed type from FriendRequest to FriendRequestModel
    let request: FriendRequestModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            Circle()
                .fill(ColorTheme.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(ColorTheme.primary)
                )
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.senderID)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text("Sent you a friend request")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
            }
            
            Spacer()
            
            // Accept/Decline buttons
            HStack(spacing: 8) {
                Button(action: {
                    // Accept action
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(ColorTheme.highlight)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    // Decline action
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// FriendsView using proper types
struct FriendsView: View {
    @EnvironmentObject var friendshipViewModel: FriendshipViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ColorTheme.lightText)
                        
                        TextField("Search friends", text: $searchText)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Friend Requests
                    if !friendshipViewModel.friendRequests.isEmpty {
                        Text("Friend Requests")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                            .padding(.horizontal)
                        
                        ForEach(friendshipViewModel.friendRequests) { request in
                            FriendRequestCard(request: request)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Friends
                    Text("Your Friends")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if friendshipViewModel.friends.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2")
                                .font(.system(size: 40))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text("You haven't added any friends yet")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Action to add friends
                            }) {
                                Text("Find Friends")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(ColorTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(friendshipViewModel.friends) { friend in
                            FriendCard(friend: friend)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Friends")
            .onAppear {
                if let userId = authViewModel.user?.id {
                    friendshipViewModel.fetchFriends(for: userId)
                    friendshipViewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
}

// FriendCard using User type
struct FriendCard: View {
    let friend: User
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            Circle()
                .fill(ColorTheme.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(ColorTheme.primary)
                )
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text("Friend")
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
            }
            
            Spacer()
            
            // Message button
            Button(action: {
                // Message action
            }) {
                Image(systemName: "message")
                    .foregroundColor(ColorTheme.primary)
                    .padding(8)
                    .background(ColorTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ExploreView is now imported from PlaydatesApp/Views/ExploreView.swift
// This view uses the fun activity icons from ActivityIcons.swift
