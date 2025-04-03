import SwiftUI
import Combine
import CoreLocation

// MARK: - Main Explore View

public struct ExploreView: View {
    // Assuming ActivityViewModel, PlaydateViewModel, ColorTheme, LocationManager, Activity,
    // SectionBox, ActivityIcons, ExploreActivityDetailView, ExploreErrorView, ExploreEmptyStateView
    // are defined/accessible elsewhere.
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var mainContainerViewModel: MainContainerViewModel
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var selectedDistance: Double = 10.0 // Default distance
    @State private var showFavoritesOnly = false
    @State private var showingFilterSheet = false // Enable state for filter sheet

    private let categories = ActivityType.allCases.map { $0.title }

    public var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {

                    // Search and Filter Bar
                    VStack(spacing: 12) {
                        HStack {
                            ExploreSearchBar(text: $searchText, placeholder: "Search activities...")
                            Divider().frame(height: 20)
                            Button { showingFilterSheet = true } label: { // Action added
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filter") // TODO: Implement Filter Sheet View
                                }
                            }
                            .buttonStyle(TextButtonStyle())
                        }
                        .padding(12).background(Color.white).cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal).padding(.top, 8).padding(.bottom, 16)

                    // Category Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.title3).fontWeight(.bold).foregroundColor(ColorTheme.darkPurple)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ExploreCategoryButton(category: "All", isSelected: selectedCategory == nil) {
                                    selectedCategory = nil
                                    fetchActivitiesForCategory()
                                }
                                ForEach(categories, id: \.self) { categoryTitle in
                                    ExploreCategoryButton(category: categoryTitle, isSelected: selectedCategory == categoryTitle) {
                                        selectedCategory = (selectedCategory == categoryTitle) ? nil : categoryTitle
                                        fetchActivitiesForCategory()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 16)
                    // TODO: Add .sheet modifier for showingFilterSheet

                    // Preferences Toggle
                    SectionBox(title: "Preferences") {
                        Toggle("Show Favorites Only", isOn: $showFavoritesOnly)
                            .padding(.horizontal)
                            .toggleStyle(SwitchToggleStyle(tint: ColorTheme.primary))
                    }
                    .padding(.bottom, 16)

                    // Results Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results")
                            .font(.title3).fontWeight(.bold).foregroundColor(ColorTheme.darkPurple)
                            .padding(.horizontal)
                        resultsView
                    }
                    .padding(.bottom, 16)

                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitle("Explore Activities", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            // TODO: Navigate to a Map view showing activities
            print("Navigate to Map View")
        }) {
            Image(systemName: "map").font(.system(size: 16, weight: .bold)).foregroundColor(ColorTheme.primary)
        })
        .onAppear(perform: onExploreViewAppear)
        // Add sheet modifier for the filter view
        .sheet(isPresented: $showingFilterSheet) {
            // TODO: Replace Text with the actual Filter View
            Text("Filter View Placeholder")
                .presentationDetents([.medium]) // Example presentation detent
        }
    }

    // MARK: - Computed Views

    @ViewBuilder
    private var resultsView: some View {
        ZStack {
            if activityViewModel.isLoading {
                ProgressView().padding(.vertical, 50)
            } else if let error = activityViewModel.error {
                ExploreErrorView(errorMessage: error, retryAction: fetchActivitiesForCategory)
                    .padding(.vertical, 50)
            } else if filteredActivities.isEmpty {
                ExploreEmptyStateView(
                    message: emptyStateMessage,
                    actionTitle: emptyStateButtonTitle,
                    action: emptyStateButtonAction
                )
                .padding(.vertical, 50)
            } else {
                activityGrid
            }
        }
    }

    private var activityGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(filteredActivities) { activity in
                ExploreActivityCard(activity: activity)
                    .environmentObject(activityViewModel)
            }
        }
        .padding()
    }

    // MARK: - Helper Functions & Computed Properties

private func onExploreViewAppear() {
    // Fetch general activities based on current filters
    fetchActivitiesForCategory()
    // Rely on ActivityViewModel's user listener to fetch favorites/wishlist when IDs are loaded/changed.
    // No need for explicit calls here anymore.
}

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
            fetchActivitiesForCategory() // Refetch after clearing filters
        } : nil
    }

    private func fetchActivitiesForCategory() {
        activityViewModel.fetchActivities(category: selectedCategory)
        if let location = LocationManager.shared.location {
            let radiusInKm = selectedDistance * 1.60934
            activityViewModel.fetchNearbyActivities(location: location, radiusInKm: radiusInKm, activityType: selectedCategory)
        }
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

        if !searchText.isEmpty {
            let lowerSearchText = searchText.lowercased()
            filtered = filtered.filter { activity in
                activity.name.lowercased().contains(lowerSearchText) ||
                (activity.description?.lowercased() ?? "").contains(lowerSearchText) ||
                activity.type.title.lowercased().contains(lowerSearchText)
            }
        }

        if showFavoritesOnly {
            filtered = filtered.filter { activity in
                guard let id = activity.id else { return false }
                return activityViewModel.favoriteActivityIDs.contains(id)
            }
        }

        if let userLocation = LocationManager.shared.location {
            let maxDistanceMeters = selectedDistance * 1609.34
            filtered = filtered.filter { activity in
                let activityLocation = CLLocation(latitude: activity.location.latitude, longitude: activity.location.longitude)
                return userLocation.distance(from: activityLocation) <= maxDistanceMeters
            }
            // Apply distance sort only if no category is selected
            if selectedCategory == nil {
                filtered.sort { a, b in
                    let locA = CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)
                    let locB = CLLocation(latitude: b.location.latitude, longitude: b.location.longitude)
                    return userLocation.distance(from: locA) < userLocation.distance(from: locB)
                }
            }
            // Otherwise, rely on the order fetched or default order when a category is selected
        }
        return filtered
    }

}

// MARK: - Extracted Section Content Structs (Corrected)

struct FavoritesSectionContent: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var mainContainerViewModel: MainContainerViewModel

    var body: some View {
        if activityViewModel.isLoadingFavorites {
            ProgressView().frame(height: 180)
        } else if activityViewModel.favoriteActivities.isEmpty {
            ExploreEmptyStateView( // Use correct component
                message: "Tap the heart on activities you love!", // Use message param
                actionTitle: "Explore Activities", // Use actionTitle param
                action: { mainContainerViewModel.selectedView = .explore } // Use action param
            )
            .frame(height: 180)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(activityViewModel.favoriteActivities.prefix(5)) { activity in
                        // Use NavigationLink or similar for navigation
                        // For now, using a Button with a print statement
                        Button {
                            print("Navigate to detail for favorite: \(activity.name)")
                            // TODO: Implement navigation to ExploreActivityDetailView(activity: activity)
                            // Example: mainContainerViewModel.selectedActivity = activity
                            // Example: mainContainerViewModel.navigateToActivityDetail = true (if using separate state)
                        } label: {
                            FeaturedActivityCard(activity: activity, buttonAction: {
                                // Action for the button *inside* the card, if any (e.g., quick add to playdate)
                                print("Featured card internal button tapped for \(activity.name)")
                            })
                                .frame(width: 250)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 180)
        }
    }
}

struct WantToDoSectionContent: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var mainContainerViewModel: MainContainerViewModel

    var body: some View {
        if activityViewModel.isLoadingWishlist {
            ProgressView().frame(height: 180)
        } else if activityViewModel.wishlistActivities.isEmpty {
            ExploreEmptyStateView( // Use correct component
                message: "Add activities you want to try!", // Use message param
                actionTitle: "Explore Activities", // Use actionTitle param
                action: { mainContainerViewModel.selectedView = .explore } // Use action param
            )
            .frame(height: 180)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(activityViewModel.wishlistActivities.prefix(5)) { activity in
                        // Use NavigationLink or similar for navigation
                        // For now, using a Button with a print statement
                        Button {
                             print("Navigate to detail for wishlist: \(activity.name)")
                             // TODO: Implement navigation to ExploreActivityDetailView(activity: activity)
                             // Example: mainContainerViewModel.selectedActivity = activity
                             // Example: mainContainerViewModel.navigateToActivityDetail = true (if using separate state)
                        } label: {
                            // Use WishlistActivityCard without the removed 'onRemove' parameter
                            WishlistActivityCard(activity: activity)
                                .frame(width: 250)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 180)
        }
    }
}
