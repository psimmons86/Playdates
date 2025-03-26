import SwiftUI
import Combine
import CoreLocation

public struct ExploreView: View {
    @ObservedObject var activityViewModel = ActivityViewModel.shared
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var selectedDistance: Double = 10.0 // Default 10 miles
    @State private var showFavoritesOnly = false
    
    private let distanceOptions: [Double] = [5.0, 10.0, 25.0, 50.0, 100.0] // In miles
    
    private let categories = [
        "Parks", "Museums", "Playgrounds", "Libraries", 
        "Swimming", "Sports", "Zoo", "Aquarium", 
        "Movies", "Theme Parks"
    ]
    
    public var body: some View {  // Make body public
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                ExploreSearchBar(text: $searchText, placeholder: "Search activities...")  // Renamed
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            ExploreCategoryButton(  // Renamed
                                category: category,
                                isSelected: selectedCategory == category,
                                action: {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                    fetchActivitiesForCategory()
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // Distance selector and favorites toggle
                VStack(spacing: 8) {
                    HStack {
                        Text("Distance:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Distance", selection: $selectedDistance) {
                            ForEach(distanceOptions, id: \.self) { distance in
                                Text("\(Int(distance)) miles").tag(distance)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedDistance) { _ in
                            fetchActivitiesForCategory()
                        }
                    }
                    
                    // Favorites toggle
                    Toggle(isOn: $showFavoritesOnly) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                            Text("Show Favorites Only")
                                .font(.subheadline)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.red))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Break up complex expressions to help type checking
                ScrollView {
                    ZStack {
                        if activityViewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if let error = activityViewModel.error {
                            ExploreErrorView(message: error)  // Renamed
                        } else if filteredActivities.isEmpty {
                            ExploreEmptyStateView(  // Renamed
                                message: emptyStateMessage,
                                buttonTitle: emptyStateButtonTitle,
                                buttonAction: emptyStateButtonAction
                            )
                        } else {
                            activityGrid  // Extract this to simplify expressions
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .onAppear {
                fetchActivitiesForCategory()
                
                // Debug location services
                let locationManager = LocationManager.shared
                print("Debug: LocationManager authorization status: \(locationManager.authorizationStatus.rawValue)")
                print("Debug: Current location available: \(locationManager.location != nil)")
                if let location = locationManager.location {
                    print("Debug: Current location coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    // Fetch nearby activities using Google Places API
                    activityViewModel.fetchNearbyActivities(location: location)
                } else {
                    print("Debug: Location is nil when trying to fetch nearby activities")
                }
            }
        }
    }
    
    // Empty state message and button based on current filters
    private var emptyStateMessage: String {
        if showFavoritesOnly {
            return "No favorite activities found"
        } else if let category = selectedCategory {
            return "No activities found in \(category)"
        } else {
            return "No activities found"
        }
    }
    
    private var emptyStateButtonTitle: String? {
        if showFavoritesOnly {
            return "Show All Activities"
        } else if selectedCategory != nil {
            return "Show All Activities"
        } else {
            return nil
        }
    }
    
    private var emptyStateButtonAction: (() -> Void)? {
        if showFavoritesOnly || selectedCategory != nil {
            return {
                showFavoritesOnly = false
                selectedCategory = nil
                fetchActivitiesForCategory()
            }
        } else {
            return nil
        }
    }
    
    // Function to fetch activities based on selected category
    private func fetchActivitiesForCategory() {
        // Fetch from Firebase
        activityViewModel.fetchActivities(category: selectedCategory)
        
        // Also fetch from Google Places if location is available
        if let location = LocationManager.shared.location {
            // Convert miles to kilometers (1 mile = 1.60934 km)
            let radiusInKm = selectedDistance * 1.60934
            
            // Pass the selected category and distance to the fetchNearbyActivities method
            activityViewModel.fetchNearbyActivities(
                location: location,
                radiusInKm: radiusInKm,
                activityType: selectedCategory
            )
        }
    }
    
    // Extract complex parts into separate views
    private var activityGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(filteredActivities) { activity in
                ExploreActivityCard(activity: activity)  // Renamed
            }
        }
        .padding()
    }
    
    // Combine activities from Firebase and Google Places
    private var combinedActivities: [Activity] {
        // Combine both arrays, removing duplicates based on name
        var combined = activityViewModel.activities
        
        // Add nearby activities that don't have the same name as any existing activity
        for nearbyActivity in activityViewModel.nearbyActivities {
            if !combined.contains(where: { $0.name == nearbyActivity.name }) {
                combined.append(nearbyActivity)
            }
        }
        
        return combined
    }
    
    private var filteredActivities: [Activity] {
        // Start with all activities
        var filtered = combinedActivities
        
        // Filter by search text if needed
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                activity.description.localizedCaseInsensitiveContains(searchText) ||
                (activity.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter by favorites if enabled
        if showFavoritesOnly {
            filtered = filtered.filter { activity in
                guard let id = activity.id else { return false }
                return activityViewModel.favoriteActivities.contains(id)
            }
        }
        
        // Sort by distance if user location is available
        if let userLocation = LocationManager.shared.location {
            return filtered.sorted { a, b in
                let locationA = CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)
                let locationB = CLLocation(latitude: b.location.latitude, longitude: b.location.longitude)
                
                return userLocation.distance(from: locationA) < userLocation.distance(from: locationB)
            }
        } else {
            return filtered
        }
    }
}

// MARK: - Supporting Views (with renamed components)

struct ExploreSearchBar: View {  // Renamed from SearchBar
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ExploreCategoryButton: View {  // Renamed from CategoryButton
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                categoryIcon
                    .frame(width: 24, height: 24)
                
                Text(category)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color(hex: "91DDCF") : Color(.systemGray6))
            .foregroundColor(isSelected ? Color(hex: "5D4E6D") : .primary)
            .cornerRadius(20)
        }
    }
    
    private var categoryIcon: some View {
        Group {
            switch category {
            case "Parks":
                ActivityIcons.ParkIcon(size: 24)
            case "Museums":
                ActivityIcons.MuseumIcon(size: 24)
            case "Playgrounds":
                ActivityIcons.PlaygroundIcon(size: 24)
            case "Libraries":
                ActivityIcons.LibraryIcon(size: 24)
            case "Swimming":
                ActivityIcons.SwimmingIcon(size: 24)
            case "Sports":
                ActivityIcons.SportsIcon(size: 24)
            case "Zoo":
                ActivityIcons.ZooIcon(size: 24)
            case "Aquarium":
                ActivityIcons.AquariumIcon(size: 24)
            case "Movies":
                ActivityIcons.MovieTheaterIcon(size: 24)
            case "Theme Parks":
                ActivityIcons.ThemeParkIcon(size: 24)
            default:
                ActivityIcons.OtherActivityIcon(size: 24)
            }
        }
    }
}

struct ExploreActivityCard: View {  // Renamed from ActivityCard
    let activity: Activity
    @ObservedObject var viewModel: ActivityViewModel
    
    init(activity: Activity, viewModel: ActivityViewModel = ActivityViewModel.shared) {
        self.activity = activity
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {  // Renamed
                VStack(alignment: .leading) {
                    // Activity icon
                    activityIcon
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 8)
                    
                    // Activity name
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Activity type
                    Text(activity.type.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Distance from user
                    if let userLocation = LocationManager.shared.location {
                        let activityLocation = CLLocation(
                            latitude: activity.location.latitude,
                            longitude: activity.location.longitude
                        )
                        let distanceInMeters = userLocation.distance(from: activityLocation)
                        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            
                            // Format distance based on how far away it is
                            if distanceInMiles < 0.1 {
                                Text("Nearby")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            } else if distanceInMiles < 10 {
                                Text(String(format: "%.1f miles away", distanceInMiles))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            } else {
                                Text(String(format: "%.0f miles away", distanceInMiles))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Rating if available
                    if let rating = activity.rating {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                            
                            if let reviewCount = activity.reviewCount {
                                Text("(\(reviewCount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(height: 200) // Increased height to accommodate distance
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            
            // Favorite button
            Button(action: {
                viewModel.toggleFavorite(for: activity)
            }) {
                Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : .gray)
                    .font(.system(size: 22))
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(8)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 60)
            case .museum:
                ActivityIcons.MuseumIcon(size: 60)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 60)
            case .library:
                ActivityIcons.LibraryIcon(size: 60)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 60)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 60)
            case .zoo:
                ActivityIcons.ZooIcon(size: 60)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 60)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 60)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 60)
            default:
                ActivityIcons.OtherActivityIcon(size: 60)
            }
        }
    }
}

struct ExploreActivityDetailView: View {  // Renamed from ActivityDetailView
    let activity: Activity
    @ObservedObject var viewModel = ActivityViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Activity icon
                HStack {
                    Spacer()
                    
                    // Use a simpler switch statement to help with type checking
                    Group {
                        switch activity.type {
                        case .park:
                            ActivityIcons.ParkIcon(size: 120)
                        case .museum:
                            ActivityIcons.MuseumIcon(size: 120)
                        case .playground:
                            ActivityIcons.PlaygroundIcon(size: 120)
                        case .library:
                            ActivityIcons.LibraryIcon(size: 120)
                        case .swimmingPool:
                            ActivityIcons.SwimmingIcon(size: 120)
                        case .sportingEvent:
                            ActivityIcons.SportsIcon(size: 120)
                        case .zoo:
                            ActivityIcons.ZooIcon(size: 120)
                        case .aquarium:
                            ActivityIcons.AquariumIcon(size: 120)
                        case .movieTheater:
                            ActivityIcons.MovieTheaterIcon(size: 120)
                        case .themePark:
                            ActivityIcons.ThemeParkIcon(size: 120)
                        default:
                            ActivityIcons.OtherActivityIcon(size: 120)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                // Activity details - break into smaller components
                detailsSection
                
                // Contact information
                contactSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: favoriteButton)
    }
    
    private var favoriteButton: some View {
        Button(action: {
            viewModel.toggleFavorite(for: activity)
        }) {
            Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : .gray)
                .font(.system(size: 22))
        }
    }
    
    // Break up complex views into smaller pieces
    private var detailsSection: some View {
        Group {
            Text(activity.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(activity.type.title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let rating = activity.rating {
                ratingView(rating: rating)
            }
            
            Divider()
            
            Text("Description")
                .font(.headline)
            
            Text(activity.description)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            Text("Location")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.location.name)
                    .fontWeight(.medium)
                
                Text(activity.location.address)
                    .foregroundColor(.secondary)
                
                // Distance from user
                if let userLocation = LocationManager.shared.location {
                    let activityLocation = CLLocation(
                        latitude: activity.location.latitude,
                        longitude: activity.location.longitude
                    )
                    let distanceInMeters = userLocation.distance(from: activityLocation)
                    let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
                    
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                        
                        // Format distance based on how far away it is
                        if distanceInMiles < 0.1 {
                            Text("Nearby")
                                .foregroundColor(.blue)
                        } else if distanceInMiles < 10 {
                            Text(String(format: "%.1f miles from your location", distanceInMiles))
                                .foregroundColor(.blue)
                        } else {
                            Text(String(format: "%.0f miles from your location", distanceInMiles))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // Map placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                )
        }
        .padding(.horizontal)
    }
    
    private func ratingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            
            Text(String(format: "%.1f", rating))
                .fontWeight(.medium)
            
            if let reviewCount = activity.reviewCount {
                Text("(\(reviewCount) reviews)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var contactSection: some View {
        Group {
            if activity.website != nil || activity.phoneNumber != nil {
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let website = activity.website {
                        websiteButton(website: website)
                    }
                    
                    if let phoneNumber = activity.phoneNumber {
                        phoneButton(phoneNumber: phoneNumber)
                    }
                }
            }
        }
    }
    
    private func websiteButton(website: String) -> some View {
        Button(action: {
            // Open website
        }) {
            HStack {
                Image(systemName: "globe")
                Text(website)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private func phoneButton(phoneNumber: String) -> some View {
        Button(action: {
            // Call phone number
        }) {
            HStack {
                Image(systemName: "phone")
                Text(phoneNumber)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct ExploreErrorView: View {  // Renamed from ErrorView
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct ExploreEmptyStateView: View {  // Renamed from EmptyStateView
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "91DDCF"))
                        .foregroundColor(Color(hex: "5D4E6D"))
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
