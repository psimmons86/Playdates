import SwiftUI
import Combine
import CoreLocation

public struct ExploreView: View {
    @ObservedObject var activityViewModel = ActivityViewModel.shared
    @EnvironmentObject var playdateViewModel: PlaydateViewModel // Keep if needed, otherwise remove
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var selectedDistance: Double = 10.0 // Default 10 miles
    @State private var showFavoritesOnly = false
    // Add state for filter sheet if needed
    // @State private var showingFilterSheet = false

    private let distanceOptions: [Double] = [5.0, 10.0, 25.0, 50.0, 100.0] // In miles

    private let categories = [
        "Parks", "Museums", "Playgrounds", "Libraries",
        "Swimming", "Sports", "Zoo", "Aquarium",
        "Movies", "Theme Parks"
    ]

    public var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            // Use a single ScrollView for the whole page content
            ScrollView {
                VStack(spacing: 0) { // Main content VStack
                    // --- Search and Filter Bar ---
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ColorTheme.lightText)

                            TextField("Search activities...", text: $searchText)
                                .foregroundColor(ColorTheme.text)
                                .submitLabel(.search) // Improve keyboard

                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ColorTheme.lightText)
                                }
                            }

                            Divider().frame(height: 20)

                            Button(action: {
                                // TODO: Show filter sheet/view
                                // showingFilterSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filter")
                                }
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.primary)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8) // Keep top padding consistent
                    .padding(.bottom, 8) // Add bottom padding consistent

                    // --- Category Selector ---
                    SectionBox(title: "Categories") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Add "All" button
                                ExploreCategoryButton(
                                    category: "All",
                                    isSelected: selectedCategory == nil,
                                    action: {
                                        selectedCategory = nil
                                        fetchActivitiesForCategory()
                                    }
                                )
                                ForEach(categories, id: \.self) { category in
                                    ExploreCategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            if selectedCategory == category {
                                                selectedCategory = nil // Deselect if tapped again
                                            } else {
                                                selectedCategory = category
                                            }
                                            fetchActivitiesForCategory()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal) // Padding inside ScrollView for content
                        }
                        // SectionBox handles vertical padding
                    }
                    .padding(.bottom, 16) // Padding after the section

                    // --- Filters ---
                    SectionBox(title: "Filters") {
                        VStack(spacing: 12) { // Increased spacing
                            HStack {
                                Text("Distance:")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.text) // Use standard text color
                                Picker("Distance", selection: $selectedDistance) {
                                    ForEach(distanceOptions, id: \.self) { distance in
                                        Text("\(Int(distance)) mi").tag(distance) // Shorten label
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: selectedDistance) { _ in
                                    fetchActivitiesForCategory()
                                }
                            }

                            Toggle(isOn: $showFavoritesOnly.animation()) { // Add animation
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                    Text("Show Favorites Only")
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.text) // Use standard text color
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ColorTheme.primary)) // Use primary color
                            .onChange(of: showFavoritesOnly) { _ in
                                // No need to call fetch here, filteredActivities handles it
                            }
                        }
                        // Padding handled by SectionBox
                    }
                    .padding(.bottom, 16) // Padding after the section

                    // --- Results ---
                    SectionBox(title: "Results") {
                        ZStack {
                            if activityViewModel.isLoading {
                                ProgressView()
                                    .padding(.vertical, 50) // Add padding for loading state
                            } else if let error = activityViewModel.error {
                                ExploreErrorView(message: error)
                                    .padding(.vertical, 50)
                            } else if filteredActivities.isEmpty {
                                ExploreEmptyStateView(
                                    message: emptyStateMessage,
                                    buttonTitle: emptyStateButtonTitle,
                                    buttonAction: emptyStateButtonAction
                                )
                                .padding(.vertical, 50)
                            } else {
                                activityGrid // Display the grid directly
                            }
                        }
                        // Padding handled by SectionBox and activityGrid
                    }
                    // No bottom padding needed here if it's the last section

                } // End Main VStack
                .padding(.vertical) // Add padding around the whole VStack content
            } // End ScrollView
        } // End ZStack
        // Remove navigation title, add navigation bar items
        // .navigationTitle("Explore") // Removed
        .navigationBarItems(trailing: Button(action: {
            // TODO: Implement action (e.g., show map view?)
        }) {
            Image(systemName: "map") // Example icon
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary)
        })
        .onAppear {
            fetchActivitiesForCategory() // Initial fetch

            // Debug location services (keep for now)
            let locationManager = LocationManager.shared
            print("Debug: LocationManager authorization status: \(locationManager.authorizationStatus.rawValue)")
            print("Debug: Current location available: \(locationManager.location != nil)")
            if let location = locationManager.location {
                print("Debug: Current location coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                // Fetch nearby activities using Google Places API - consider if needed on appear or only on filter change
                // activityViewModel.fetchNearbyActivities(location: location)
            } else {
                print("Debug: Location is nil when trying to fetch nearby activities")
            }
        }
        // Add sheet modifier if filter button is implemented
        // .sheet(isPresented: $showingFilterSheet) {
        //     // Filter View
        // }
    }

    // --- Helper Functions & Computed Properties (remain inside the struct) ---

    private var emptyStateMessage: String {
        if showFavoritesOnly {
            return "No favorite activities found"
        } else if let category = selectedCategory {
            return "No activities found in \(category)"
        } else {
            return "No activities found matching your criteria" // More general message
        }
    }

    private var emptyStateButtonTitle: String? {
        if showFavoritesOnly || selectedCategory != nil {
            return "Clear Filters" // More accurate title
        } else {
            return nil
        }
    }

    private var emptyStateButtonAction: (() -> Void)? {
        if showFavoritesOnly || selectedCategory != nil {
            return {
                showFavoritesOnly = false
                selectedCategory = nil
                // fetchActivitiesForCategory() // Fetch is triggered by state change
            }
        } else {
            return nil
        }
    }

    private func fetchActivitiesForCategory() {
        // Fetch from Firebase based on category
        activityViewModel.fetchActivities(category: selectedCategory)

        // Fetch from Google Places based on category and distance if location available
        if let location = LocationManager.shared.location {
            let radiusInKm = selectedDistance * 1.60934
            activityViewModel.fetchNearbyActivities(
                location: location,
                radiusInKm: radiusInKm,
                activityType: selectedCategory // Pass category for potential API filtering
            )
        }
    }

    private var activityGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(filteredActivities) { activity in
                ExploreActivityCard(activity: activity) // ViewModel passed implicitly
            }
        }
        .padding() // Padding around the grid
    }

    private var combinedActivities: [Activity] {
        var combined = activityViewModel.activities
        for nearbyActivity in activityViewModel.nearbyActivities {
            if !combined.contains(where: { $0.name == nearbyActivity.name }) {
                combined.append(nearbyActivity)
            }
        }
        return combined
    }

    private var filteredActivities: [Activity] {
        var filtered = combinedActivities

        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                let nameMatch = activity.name.localizedCaseInsensitiveContains(searchText)
                let descriptionMatch = activity.description?.localizedCaseInsensitiveContains(searchText) ?? false
                // Assuming activity.type is non-optional based on Activity model, and type.title is non-optional based on ActivityType model
                let typeMatch = activity.type.title.localizedCaseInsensitiveContains(searchText)
                return nameMatch || descriptionMatch || typeMatch
            }
        }

        if showFavoritesOnly {
            filtered = filtered.filter { activity in
                guard let id = activity.id else { return false }
                return activityViewModel.favoriteActivities.contains(id)
            }
        }

        // Distance filtering (apply only if location is available)
        if let userLocation = LocationManager.shared.location {
            let maxDistanceMeters = selectedDistance * 1609.34 // Convert miles to meters
            filtered = filtered.filter { activity in
                let activityLocation = CLLocation(latitude: activity.location.latitude, longitude: activity.location.longitude)
                return userLocation.distance(from: activityLocation) <= maxDistanceMeters
            }

            // Sort by distance
            filtered.sort { a, b in
                let locationA = CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)
                let locationB = CLLocation(latitude: b.location.latitude, longitude: b.location.longitude)
                return userLocation.distance(from: locationA) < userLocation.distance(from: locationB)
            }
        }
        // If no location, sorting by distance is skipped

        return filtered
    }
} // End of ExploreView struct

// MARK: - Supporting Views (Keep as is, they seem fine)

struct ExploreSearchBar: View {
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

struct ExploreCategoryButton: View {
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
            // Use ColorTheme for consistency if available, otherwise keep original
            .background(isSelected ? ColorTheme.primary.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? ColorTheme.primary : Color.clear, lineWidth: 1)
            )
        }
    }

    // Keep categoryIcon implementation
    private var categoryIcon: some View {
        SwiftUI.Group {
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

struct ExploreActivityCard: View {
    let activity: Activity
    // Use shared instance directly if appropriate, or keep @ObservedObject if needed per card
    @StateObject var viewModel = ActivityViewModel.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {
                VStack(alignment: .leading, spacing: 6) { // Reduced spacing
                    activityIcon
                        .frame(width: 50, height: 50) // Slightly smaller icon
                        .padding(.bottom, 4)

                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.text) // Use theme color
                        .lineLimit(1)

                    Text(activity.type.title)
                        .font(.caption) // Smaller font for type
                        .foregroundColor(ColorTheme.lightText) // Use theme color
                        .lineLimit(1)

                    // Distance
                    if let userLocation = LocationManager.shared.location {
                        let activityLocation = CLLocation(
                            latitude: activity.location.latitude,
                            longitude: activity.location.longitude
                        )
                        let distanceInMeters = userLocation.distance(from: activityLocation)
                        let distanceInMiles = distanceInMeters / 1609.34

                        HStack(spacing: 2) { // Reduced spacing
                            Image(systemName: "location.fill") // Filled icon
                                .foregroundColor(ColorTheme.primary) // Use theme color
                                .font(.caption2) // Smaller icon
                            Text(formatDistance(distanceInMiles))
                                .font(.caption2) // Smaller font
                                .foregroundColor(ColorTheme.lightText) // Use theme color
                        }
                    }

                    // Rating
                    if let rating = activity.rating {
                        HStack(spacing: 2) { // Reduced spacing
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(round(rating)) ? "star.fill" : "star") // Use rounded rating
                                    .foregroundColor(.orange) // Consistent color
                                    .font(.caption2) // Smaller stars
                            }
                            if let reviewCount = activity.reviewCount, reviewCount > 0 {
                                Text("(\(reviewCount))")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.lightText)
                            }
                        }
                    }
                    Spacer() // Pushes content up
                }
                .padding(12) // Consistent padding
                .frame(minHeight: 160) // Min height for consistency
                .background(Color.white) // Use white background
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Consistent shadow
            }
            .buttonStyle(PlainButtonStyle()) // Remove default button styling

            // Favorite button
            Button(action: {
                viewModel.toggleFavorite(for: activity)
            }) {
                Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : ColorTheme.lightText) // Use theme color
                    .font(.system(size: 18)) // Slightly smaller
                    .padding(8) // Smaller padding
                    .background(.thinMaterial) // Use material background
                    .clipShape(Circle())
            }
            .padding(6) // Adjust padding
        }
        // Removed outer shadow as card has its own
    }

    // Keep activityIcon implementation
    private var activityIcon: some View {
         SwiftUI.Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 50)
            case .museum:
                ActivityIcons.MuseumIcon(size: 50)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 50)
            case .library:
                ActivityIcons.LibraryIcon(size: 50)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 50)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 50)
            case .zoo:
                ActivityIcons.ZooIcon(size: 50)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 50)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 50)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 50)
            default:
                ActivityIcons.OtherActivityIcon(size: 50)
            }
        }
    }

    // Helper to format distance
    private func formatDistance(_ distanceInMiles: Double) -> String {
        if distanceInMiles < 0.1 {
            return "Nearby"
        } else if distanceInMiles < 10 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
}

struct ExploreErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill") // Filled icon
                .font(.system(size: 40)) // Slightly smaller
                .foregroundColor(.orange)

            Text("Oops!") // Friendlier title
                .font(.title2) // Slightly smaller title
                .fontWeight(.semibold) // Less bold
                .foregroundColor(ColorTheme.text)

            Text(message)
                .font(.subheadline) // Smaller text
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.lightText)
        }
        .padding(30) // More padding
        .frame(maxWidth: .infinity)
    }
}

struct ExploreEmptyStateView: View {
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "binoculars.fill") // Different icon
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.lightText) // Use theme color

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.lightText) // Use theme color

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10) // Slightly more vertical padding
                        .background(ColorTheme.primary.opacity(0.1)) // Lighter background
                        .foregroundColor(ColorTheme.primary) // Theme color
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(ColorTheme.primary, lineWidth: 1) // Add border
                        )
                }
            }
        }
        .padding(30) // More padding
        .frame(maxWidth: .infinity)
    }
}
