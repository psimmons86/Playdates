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
                activityViewModel.fetchPopularActivities()
                playdateViewModel.fetchPlaydates()
            }
        }
    }
    
    // Helper function to add mock activities if none are found
    private func addMockActivities() {
        let mockActivities = [
            Activity(
                id: nil, // Let Firestore generate the ID
                name: "Central Park Playground",
                description: "A fun playground for kids of all ages",
                type: .park,
                location: Location(name: "Central Park", address: "123 Park Ave", latitude: 37.7749, longitude: -122.4194),
                rating: 4.5,
                reviewCount: 120,
                isPublic: true
            ),
            Activity(
                id: nil, // Let Firestore generate the ID
                name: "Children's Museum",
                description: "Interactive exhibits for children",
                type: .museum,
                location: Location(name: "Downtown Museum", address: "456 Museum St", latitude: 37.7749, longitude: -122.4194),
                rating: 4.8,
                reviewCount: 200,
                isPublic: true
            ),
            Activity(
                id: nil, // Let Firestore generate the ID
                name: "Public Library Story Time",
                description: "Weekly story time for kids",
                type: .library,
                location: Location(name: "Main Library", address: "789 Library Ave", latitude: 37.7749, longitude: -122.4194),
                rating: 4.2,
                reviewCount: 85,
                isPublic: true
            )
        ]
        
        // Use DispatchQueue.main to ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.activityViewModel.activities = mockActivities
            self.activityViewModel.popularActivities = mockActivities
        }
    }
    
    // Helper function to add mock playdates if none are found
    private func addMockPlaydates() {
        guard let userID = AuthViewModel().user?.id ?? Auth.auth().currentUser?.uid else { return }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dayAfterTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        
        let mockPlaydates = [
            Playdate(
                id: nil, // Let Firestore generate the ID
                hostID: userID,
                title: "Park Playdate",
                description: "Let's meet at the park for a fun afternoon",
                activityType: "park",
                location: Location(name: "Central Park", address: "123 Park Ave", latitude: 37.7749, longitude: -122.4194),
                startDate: tomorrow,
                endDate: Calendar.current.date(byAdding: .hour, value: 2, to: tomorrow) ?? tomorrow,
                attendeeIDs: [userID],
                isPublic: true
            ),
            Playdate(
                id: nil, // Let Firestore generate the ID
                hostID: userID,
                title: "Museum Trip",
                description: "Exploring the children's museum",
                activityType: "museum",
                location: Location(name: "Children's Museum", address: "456 Museum St", latitude: 37.7749, longitude: -122.4194),
                startDate: dayAfterTomorrow,
                endDate: Calendar.current.date(byAdding: .hour, value: 3, to: dayAfterTomorrow) ?? dayAfterTomorrow,
                attendeeIDs: [userID],
                isPublic: true
            )
        ]
        
        // Use DispatchQueue.main to ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.playdateViewModel.playdates = mockPlaydates
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
    
    @State private var showingLocationPicker = false
    @State private var selectedLocation: Location?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    // Location picker button
                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            Text(selectedLocation?.name ?? "Select Location")
                                .foregroundColor(selectedLocation == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                    
                    if let location = selectedLocation {
                        Text(location.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        // Create playdate
                        guard let userID = authViewModel.user?.id ?? Auth.auth().currentUser?.uid else { return }
                        guard let location = selectedLocation else { return }
                        
                        let playdate = Playdate(
                            id: nil, // Let Firestore generate the ID
                            hostID: userID,
                            title: title,
                            description: description,
                            activityType: "playdate",
                            location: location,
                            startDate: date,
                            endDate: date.addingTimeInterval(7200), // 2 hours later
                            attendeeIDs: [userID],
                            isPublic: true
                        )
                        
                        // Try to save to Firebase first
                        playdateViewModel.createPlaydate(playdate) { result in
                            // Ensure UI updates happen on the main thread
                            DispatchQueue.main.async {
                                switch result {
                                case .success(_):
                                    // Successfully saved to Firebase
                                    print("Playdate saved to Firebase")
                                case .failure(let error):
                                    // Failed to save to Firebase, add to local array
                                    print("Failed to save to Firebase: \(error.localizedDescription)")
                                    self.playdateViewModel.playdates.append(playdate)
                                }
                                
                                // Reset form
                                self.title = ""
                                self.description = ""
                                self.date = Date()
                                self.selectedLocation = nil
                            }
                        }
                    }) {
                        Text("Create Playdate")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(title.isEmpty || selectedLocation == nil)
                }
            }
            .navigationTitle("Create Playdate")
            .sheet(isPresented: $showingLocationPicker) {
                // Inline LocationPickerView
                NavigationView {
                    LocationPickerContent(selectedLocation: $selectedLocation, isPresented: $showingLocationPicker)
                }
            }
        }
    }
}

// Profile View
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingChildSetupSheet = false
    
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
                        HStack {
                            Text("Your Children")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            Spacer()
                            
                            Button(action: {
                                showingChildSetupSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    
                                    Text("Add Child")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                        }
                        
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
            .sheet(isPresented: $showingChildSetupSheet) {
                ChildProfileSetupView(
                    onComplete: {
                        // Dismiss the sheet when the child is added successfully
                        showingChildSetupSheet = false
                    },
                    onSkip: {
                        // Dismiss the sheet when the user skips
                        showingChildSetupSheet = false
                    }
                )
            }
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

// Location Picker Content View
struct LocationPickerContent: View {
    @Binding var selectedLocation: Location?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a location", text: $searchText)
                    .onChange(of: searchText) { newValue in
                        if !newValue.isEmpty && newValue.count > 2 {
                            searchLocations()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if isSearching {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Text("No locations found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                // Results list
                List {
                    // Current location option
                    if let userLocation = locationManager.location {
                        Button(action: {
                            // Get address for current location
                            let geocoder = CLGeocoder()
                            let clLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                            
                            geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
                                if let error = error {
                                    errorMessage = "Error getting address: \(error.localizedDescription)"
                                    return
                                }
                                
                                if let placemark = placemarks?.first {
                                    let name = placemark.name ?? "Current Location"
                                    
                                    // Format address
                                    var addressComponents: [String] = []
                                    if let thoroughfare = placemark.thoroughfare {
                                        addressComponents.append(thoroughfare)
                                    }
                                    if let locality = placemark.locality {
                                        addressComponents.append(locality)
                                    }
                                    if let administrativeArea = placemark.administrativeArea {
                                        addressComponents.append(administrativeArea)
                                    }
                                    if let postalCode = placemark.postalCode {
                                        addressComponents.append(postalCode)
                                    }
                                    
                                    let address = addressComponents.joined(separator: ", ")
                                    
                                    // Create location
                                    let location = Location(
                                        name: name,
                                        address: address,
                                        latitude: userLocation.coordinate.latitude,
                                        longitude: userLocation.coordinate.longitude
                                    )
                                    
                                    selectedLocation = location
                                    isPresented = false
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                
                                Text("Current Location")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Search results
                    ForEach(searchResults, id: \.id) { location in
                        Button(action: {
                            selectedLocation = location
                            isPresented = false
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.name)
                                    .foregroundColor(.primary)
                                
                                Text(location.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Location")
        .navigationBarItems(trailing: Button("Cancel") {
            isPresented = false
        })
    }
    
    private func searchLocations() {
        isSearching = true
        errorMessage = nil
        
        // Use Google Places API to search for locations
        GooglePlacesService.shared.searchPlaces(query: searchText) { result in
            isSearching = false
            
            switch result {
            case .success(let places):
                // Convert places to locations
                self.searchResults = places.map { place in
                    Location(
                        id: place.placeId,
                        name: place.name,
                        address: place.vicinity,
                        latitude: place.geometry.location.lat,
                        longitude: place.geometry.location.lng
                    )
                }
                
            case .failure(let error):
                self.errorMessage = "Error searching for locations: \(error.localizedDescription)"
            }
        }
    }
}
