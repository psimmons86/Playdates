import SwiftUI
import Combine
import CoreLocation

// MARK: - Supporting Views (Defined in ExploreView.swift for Scope)

// Note: SectionBox, ActivityIcons, ExploreActivityDetailView, ExploreErrorView, ExploreEmptyStateView
// are assumed defined elsewhere based on previous redeclaration errors.

struct ExploreSearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
                .submitLabel(.search)

            if !text.isEmpty {
                Button(action: { text = "" }) {
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
            .background(isSelected ? ColorTheme.primary.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? ColorTheme.primary : Color.clear, lineWidth: 1)
            )
        }
    }

    private var categoryIcon: some View {
        // Assuming ActivityIcons is accessible from its own file
        SwiftUI.Group {
            switch category {
            case "Parks":       ActivityIcons.ParkIcon(size: 24)
            case "Museums":     ActivityIcons.MuseumIcon(size: 24)
            case "Playgrounds": ActivityIcons.PlaygroundIcon(size: 24)
            case "Libraries":   ActivityIcons.LibraryIcon(size: 24)
            case "Swimming":    ActivityIcons.SwimmingIcon(size: 24)
            case "Sports":      ActivityIcons.SportsIcon(size: 24)
            case "Zoo":         ActivityIcons.ZooIcon(size: 24)
            case "Aquarium":    ActivityIcons.AquariumIcon(size: 24)
            case "Movies":      ActivityIcons.MovieTheaterIcon(size: 24)
            case "Theme Parks": ActivityIcons.ThemeParkIcon(size: 24)
            default:            ActivityIcons.OtherActivityIcon(size: 24)
            }
        }
    }
}

struct ExploreActivityCard: View {
    let activity: Activity
    @StateObject var viewModel = ActivityViewModel.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Assuming ExploreActivityDetailView is accessible from its own file
            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {
                VStack(alignment: .leading, spacing: 6) {
                    activityIcon
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 4)

                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                        .lineLimit(1)

                    Text(activity.type.title)
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)

                    // Distance
                    if let userLocation = LocationManager.shared.location {
                        let activityLocation = CLLocation(latitude: activity.location.latitude, longitude: activity.location.longitude)
                        let distanceInMeters = userLocation.distance(from: activityLocation)
                        let distanceInMiles = distanceInMeters / 1609.34
                        HStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .foregroundColor(ColorTheme.primary).font(.caption2)
                            Text(formatDistance(distanceInMiles))
                                .font(.caption2).foregroundColor(ColorTheme.lightText)
                        }
                    }

                    // Rating
                    if let rating = activity.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(round(rating)) ? "star.fill" : "star")
                                    .foregroundColor(.orange).font(.caption2)
                            }
                            if let reviewCount = activity.reviewCount, reviewCount > 0 {
                                Text("(\(reviewCount))").font(.caption2).foregroundColor(ColorTheme.lightText)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .frame(minHeight: 160)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())

            // Favorite button - Assuming FavoriteButton is defined elsewhere (e.g., ExploreComponents.swift)
             Button(action: { viewModel.toggleFavorite(for: activity) }) {
                 Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                     .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : ColorTheme.lightText)
                     .font(.system(size: 18)).padding(8).background(.thinMaterial).clipShape(Circle())
             }
             .padding(6)
        }
    }

    private var activityIcon: some View {
         // Assuming ActivityIcons is accessible from its own file
         SwiftUI.Group {
            switch activity.type {
            case .park:         ActivityIcons.ParkIcon(size: 50)
            case .museum:       ActivityIcons.MuseumIcon(size: 50)
            case .playground:   ActivityIcons.PlaygroundIcon(size: 50)
            case .library:      ActivityIcons.LibraryIcon(size: 50)
            case .swimmingPool: ActivityIcons.SwimmingIcon(size: 50)
            case .sportingEvent:ActivityIcons.SportsIcon(size: 50)
            case .zoo:          ActivityIcons.ZooIcon(size: 50)
            case .aquarium:     ActivityIcons.AquariumIcon(size: 50)
            case .movieTheater: ActivityIcons.MovieTheaterIcon(size: 50)
            case .themePark:    ActivityIcons.ThemeParkIcon(size: 50)
             default:            ActivityIcons.OtherActivityIcon(size: 50)
            }
        }
    }

    private func formatDistance(_ distanceInMiles: Double) -> String {
        if distanceInMiles < 0.1 { return "Nearby" }
        else if distanceInMiles < 10 { return String(format: "%.1f mi", distanceInMiles) }
        else { return String(format: "%.0f mi", distanceInMiles) }
    }
}


// MARK: - Main Explore View

public struct ExploreView: View {
    // Assuming ActivityViewModel, PlaydateViewModel, ColorTheme, LocationManager, Activity,
    // SectionBox, ActivityIcons, ExploreActivityDetailView, ExploreErrorView, ExploreEmptyStateView
    // are defined/accessible elsewhere.
    @ObservedObject var activityViewModel = ActivityViewModel.shared
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var selectedDistance: Double = 10.0
    @State private var showFavoritesOnly = false
    // @State private var showingFilterSheet = false

    private let distanceOptions: [Double] = [5.0, 10.0, 25.0, 50.0, 100.0]
    // Assuming ActivityType enum provides these categories or similar
    private let categories = ActivityType.allCases.map { $0.title } // Dynamically get categories if possible

    public var body: some View {
        ZStack { // Root ZStack
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            ScrollView { // Main ScrollView
                VStack(spacing: 0) { // Main content VStack

                    // --- Search and Filter Bar ---
                    VStack(spacing: 12) {
                        HStack {
                            ExploreSearchBar(text: $searchText, placeholder: "Search activities...") // Use definition from this file
                            Divider().frame(height: 20)
                            Button(action: { /* TODO: showingFilterSheet = true */ }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filter")
                                }
                                .font(.subheadline).foregroundColor(ColorTheme.primary)
                            }
                        }
                        .padding(12).background(Color.white).cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal).padding(.top, 8).padding(.bottom, 8)

                    // --- Category Selector ---
                    // Assuming SectionBox is defined elsewhere
                    SectionBox(title: "Categories") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ExploreCategoryButton(category: "All", isSelected: selectedCategory == nil) { // Use definition from this file
                                    selectedCategory = nil
                                    fetchActivitiesForCategory()
                                }
                                ForEach(categories, id: \.self) { categoryTitle in
                                    ExploreCategoryButton(category: categoryTitle, isSelected: selectedCategory == categoryTitle) { // Use definition from this file
                                        selectedCategory = (selectedCategory == categoryTitle) ? nil : categoryTitle
                                        fetchActivitiesForCategory()
                                    }
                                }
                            } // End HStack
                            .padding(.horizontal)
                        } // End ScrollView (.horizontal)
                    } // End SectionBox "Categories"
                    .padding(.bottom, 16)

                    // --- Favorites Toggle ---
                    // Assuming SectionBox is defined elsewhere
                    SectionBox(title: "Preferences") {
                        Toggle("Show Favorites Only", isOn: $showFavoritesOnly)
                            .padding(.horizontal)
                            .toggleStyle(SwitchToggleStyle(tint: ColorTheme.primary))
                            .onChange(of: showFavoritesOnly) { _ in /* Filter updates via filteredActivities */ }
                    } // End SectionBox "Preferences"
                    .padding(.bottom, 16)

                    // --- Results ---
                    // Assuming SectionBox is defined elsewhere
                    SectionBox(title: "Results") {
                        ZStack { // ZStack for Loading/Error/Empty/Grid
                            if activityViewModel.isLoading {
                                ProgressView().padding(.vertical, 50)
                            } else if let error = activityViewModel.error {
                                // Assuming ExploreErrorView is defined elsewhere
                                ExploreErrorView(errorMessage: error, retryAction: fetchActivitiesForCategory)
                                    .padding(.vertical, 50)
                            } else if filteredActivities.isEmpty {
                                // Assuming ExploreEmptyStateView is defined elsewhere
                                ExploreEmptyStateView(
                                    message: emptyStateMessage,
                                    actionTitle: emptyStateButtonTitle,
                                    action: emptyStateButtonAction
                                )
                                .padding(.vertical, 50)
                            } else {
                                activityGrid // The LazyVGrid
                            }
                        } // End ZStack (Results content)
                    } // End SectionBox "Results"

                } // End Main content VStack
                .padding(.vertical)
            } // End Main ScrollView
        } // End Root ZStack
        .navigationBarItems(trailing: Button(action: { /* TODO: Map view? */ }) {
            Image(systemName: "map").font(.system(size: 16, weight: .bold)).foregroundColor(ColorTheme.primary)
        })
        .onAppear {
            fetchActivitiesForCategory() // Initial fetch
            // printLocationStatus() // Optional debug
        }
        // .sheet(isPresented: $showingFilterSheet) { /* Filter View */ }

    } // <<<< CORRECT END of body COMPUTED PROPERTY

    // --- Helper Functions & Computed Properties ---

    private var emptyStateMessage: String {
        if showFavoritesOnly { return "No favorite activities found" }
        else if let category = selectedCategory { return "No activities found in \(category)" }
        else { return "No activities found matching your criteria" }
    }

    private var emptyStateButtonTitle: String? {
        (showFavoritesOnly || selectedCategory != nil) ? "Clear Filters" : nil
    }

    private var emptyStateButtonAction: (() -> Void)? {
        (showFavoritesOnly || selectedCategory != nil) ? {
            showFavoritesOnly = false
            selectedCategory = nil
        } : nil
    }

    private func fetchActivitiesForCategory() {
        activityViewModel.fetchActivities(category: selectedCategory)
        if let location = LocationManager.shared.location {
            let radiusInKm = selectedDistance * 1.60934
            activityViewModel.fetchNearbyActivities(location: location, radiusInKm: radiusInKm, activityType: selectedCategory)
        }
    }

    // Optional debug helper
    private func printLocationStatus() {
        let locationManager = LocationManager.shared
        print("Debug: Location Status: \(locationManager.authorizationStatus.rawValue)")
        print("Debug: Location Available: \(locationManager.location != nil)")
        if let loc = locationManager.location { print("Debug: Coords: \(loc.coordinate.latitude), \(loc.coordinate.longitude)") }
    }

    private var activityGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(filteredActivities) { activity in
                ExploreActivityCard(activity: activity) // Use definition from this file
            }
        }
        .padding()
    }

    private var combinedActivities: [Activity] {
        var combined = activityViewModel.activities
        let existingNames = Set(combined.map { $0.name })
        for nearbyActivity in activityViewModel.nearbyActivities {
            if !existingNames.contains(nearbyActivity.name) {
                combined.append(nearbyActivity)
            }
        }
        return combined
    }

    private var filteredActivities: [Activity] {
        var filtered = combinedActivities

        // Search Text Filter
        if !searchText.isEmpty {
            let lowerSearchText = searchText.lowercased()
            filtered = filtered.filter { activity in
                activity.name.lowercased().contains(lowerSearchText) ||
                activity.description.lowercased().contains(lowerSearchText) || // Removed optional chaining
                activity.type.title.lowercased().contains(lowerSearchText)
            }
        }

        // Favorites Filter
        if showFavoritesOnly {
            filtered = filtered.filter { activity in
                guard let id = activity.id else { return false }
                return activityViewModel.favoriteActivities.contains(id)
            }
        }

        // Distance Filter & Sort
        if let userLocation = LocationManager.shared.location {
            let maxDistanceMeters = selectedDistance * 1609.34
            filtered = filtered.filter { activity in
                let activityLocation = CLLocation(latitude: activity.location.latitude, longitude: activity.location.longitude)
                return userLocation.distance(from: activityLocation) <= maxDistanceMeters
            }
            filtered.sort { a, b in
                let locA = CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)
                let locB = CLLocation(latitude: b.location.latitude, longitude: b.location.longitude)
                return userLocation.distance(from: locA) < userLocation.distance(from: locB)
            }
        }
        return filtered
    }

} // <<<< CORRECT END of ExploreView STRUCT
