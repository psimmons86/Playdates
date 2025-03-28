import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase

struct HomeView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCategoryIndex = 0
    @State private var isAnimating = false
    @State private var showWeather = true
    
    // We'll use the activityViewModel's favoriteActivities instead of local state
    
    private let categories = ["All", "Parks", "Museums", "Playgrounds", "Swimming", "Zoo"]
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Enhanced animated header
                    EnhancedHomeHeader(isAnimating: $isAnimating)
                    
                    // Weather widget
                    if showWeather {
                        SectionBox(title: "Today's Weather") {
                            WeatherView()
                                .frame(height: 120)
                        }
                    }
                    
                    // Calendar events section
                    SectionBox(title: "Upcoming Calendar Events") {
                        CalendarEventsPreview()
                    }
                    
                    // Featured section
                    SectionBox(title: "Featured Activities") {
                        if featuredActivities.isEmpty {
                            EmptyStateBox(
                                icon: "star",
                                title: "No Featured Activities",
                                message: "Featured activities will appear here",
                                buttonTitle: nil,
                                buttonAction: nil
                            )
                        } else {
                            // Featured carousel
                            TabView {
                                ForEach(featuredActivities) { activity in
                                    Button(action: {
                                        // Navigate to activity detail
                                    }) {
                                        FeaturedActivityCard(
                                            activity: activity,
                                            buttonAction: nil
                                        )
                                    }
                                }
                            }
                            .frame(height: 200)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        }
                    }
                    
                    // Category selector
                    SectionBox(title: "Browse by Category") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<categories.count, id: \.self) { index in
                                    CategoryButton(
                                        title: categories[index],
                                        isSelected: selectedCategoryIndex == index,
                                        action: {
                                            selectedCategoryIndex = index
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Upcoming Playdates
                    SectionBox(
                        title: "Upcoming Playdates",
                        viewAllAction: {
                            // View all playdates
                        }
                    ) {
                        if playdateViewModel.playdates.isEmpty {
                            EmptyStateBox(
                                icon: "calendar",
                                title: "No upcoming playdates",
                                message: "Create your first playdate to get started",
                                buttonTitle: "Create Playdate",
                                buttonAction: {
                                    // Create playdate
                                }
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(playdateViewModel.playdates.prefix(5)) { playdate in
                                        Button(action: {
                                            // Navigate to playdate detail
                                        }) {
                                            EnhancedPlaydateCard(playdate: playdate)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Popular Activities
                    SectionBox(
                        title: "Popular Activities",
                        viewAllAction: {
                            // View all activities
                        }
                    ) {
                        if activityViewModel.popularActivities.isEmpty {
                            EmptyStateBox(
                                icon: "star.circle",
                                title: "No Popular Activities",
                                message: "Popular activities will appear here",
                                buttonTitle: nil,
                                buttonAction: nil
                            )
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ForEach(activityViewModel.popularActivities.prefix(4)) { activity in
                                    Button(action: {
                                        // Navigate to activity detail
                                    }) {
                                        PopularActivityCard(
                                            activity: activity,
                                            onAddToWishlist: {
                                                toggleWishlist(activity)
                                            },
                                            isInWishlist: isInWishlist(activity)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Wishlist section
                    SectionBox(
                        title: "Your Wishlist",
                        viewAllAction: wishlistActivities.isEmpty ? nil : {
                            // Clear all favorites
                            activityViewModel.favoriteActivities.removeAll()
                        }
                    ) {
                        if wishlistActivities.isEmpty {
                            EmptyStateBox(
                                icon: "heart",
                                title: "Your wishlist is empty",
                                message: "Add activities to your wishlist by tapping the heart icon",
                                buttonTitle: nil,
                                buttonAction: nil
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(wishlistActivities) { activity in
                                    Button(action: {
                                        // Navigate to activity detail
                                    }) {
                                        WishlistActivityCard(
                                            activity: activity,
                                            onRemove: {
                                                toggleWishlist(activity)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Home")
        .onAppear {
            // Fetch activities from Firebase
            activityViewModel.fetchActivities()
            activityViewModel.fetchPopularActivities()
            activityViewModel.fetchFeaturedActivities()
            playdateViewModel.fetchPlaydates()
            
            // Start animations
            isAnimating = true
            
            // Debug logging
            print("HomeView appeared - fetching data from Firebase")
            
            // Add mock data if needed for testing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Add mock activities if needed
                if activityViewModel.activities.isEmpty && activityViewModel.popularActivities.isEmpty {
                    addMockActivities()
                }
                
                // Add mock playdates if needed
                if playdateViewModel.playdates.isEmpty {
                    playdateViewModel.addMockPlaydates()
                }
            }
        }
    }
    
    // Filtered activities based on selected category
    private var filteredActivities: [Activity] {
        if selectedCategoryIndex == 0 {
            return activityViewModel.activities
        } else {
            let categoryName = categories[selectedCategoryIndex].lowercased()
            return activityViewModel.activities.filter { activity in
                if categoryName == "parks" && activity.type == .park {
                    return true
                } else if categoryName == "museums" && activity.type == .museum {
                    return true
                } else if categoryName == "playgrounds" && activity.type == .playground {
                    return true
                } else if categoryName == "swimming" && activity.type == .swimmingPool {
                    return true
                } else if categoryName == "zoo" && activity.type == .zoo {
                    return true
                }
                return false
            }
        }
    }
    
    // Featured activities (prioritize activities marked as featured, then fall back to top rated)
    private var featuredActivities: [Activity] {
        // First try to find activities explicitly marked as featured
        let featured = activityViewModel.activities.filter { $0.isFeatured == true }
        
        // If we have enough featured activities, use those
        if featured.count >= 3 {
            return Array(featured.prefix(3))
        }
        
        // Otherwise, supplement with top-rated activities
        let topRated = activityViewModel.activities
            .filter { $0.isFeatured == false && ($0.rating ?? 0) > 4.0 }
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        
        // Combine featured and top-rated, ensuring no duplicates
        var result = featured
        for activity in topRated {
            if !result.contains(where: { $0.id == activity.id }) && result.count < 3 {
                result.append(activity)
            }
        }
        
        return result
    }
    
    // MARK: - Wishlist Functions
    
    // Check if an activity is in the wishlist
    private func isInWishlist(_ activity: Activity) -> Bool {
        guard let id = activity.id else { return false }
        return activityViewModel.favoriteActivities.contains(id)
    }
    
    // Add or remove an activity from the wishlist
    private func toggleWishlist(_ activity: Activity) {
        activityViewModel.toggleFavorite(for: activity)
    }
    
    // Compute wishlist activities from favoriteActivities IDs
    private var wishlistActivities: [Activity] {
        return activityViewModel.activities.filter { activity in
            guard let id = activity.id else { return false }
            return activityViewModel.favoriteActivities.contains(id)
        }
    }
    
    // Add mock activities for testing
    private func addMockActivities() {
        // Create mock location
        let sfLocation = Location(
            name: "Golden Gate Park",
            address: "San Francisco, CA",
            latitude: 37.7694,
            longitude: -122.4862
        )
        
        // Create mock activities
        let activities = [
            Activity(
                id: "park1",
                name: "Golden Gate Park",
                description: "Beautiful urban park with gardens, museums, and playgrounds",
                type: .park,
                location: sfLocation,
                rating: 4.8,
                reviewCount: 1250,
                isPublic: true,
                isFeatured: true
            ),
            Activity(
                id: "museum1",
                name: "California Academy of Sciences",
                description: "Natural history museum with aquarium, planetarium, and rainforest",
                type: .museum,
                location: sfLocation,
                rating: 4.7,
                reviewCount: 980,
                isPublic: true,
                isFeatured: true
            ),
            Activity(
                id: "playground1",
                name: "Koret Children's Quarter",
                description: "Historic playground with concrete slide and carousel",
                type: .playground,
                location: sfLocation,
                rating: 4.6,
                reviewCount: 750,
                isPublic: true
            ),
            Activity(
                id: "zoo1",
                name: "San Francisco Zoo",
                description: "100-acre zoo with over 2,000 exotic, endangered and rescued animals",
                type: .zoo,
                location: Location(
                    name: "San Francisco Zoo",
                    address: "Sloat Blvd & Upper Great Highway, San Francisco, CA",
                    latitude: 37.7325,
                    longitude: -122.5014
                ),
                rating: 4.5,
                reviewCount: 890,
                isPublic: true,
                isFeatured: true
            ),
            Activity(
                id: "swimming1",
                name: "Hamilton Recreation Center Pool",
                description: "Public indoor swimming pool with lessons for all ages",
                type: .swimmingPool,
                location: Location(
                    name: "Hamilton Recreation Center",
                    address: "1900 Geary Blvd, San Francisco, CA",
                    latitude: 37.7841,
                    longitude: -122.4344
                ),
                rating: 4.3,
                reviewCount: 320,
                isPublic: true
            )
        ]
        
        // Add activities to the view model
        activityViewModel.activities = activities
        
        // Add some to popular activities
        activityViewModel.popularActivities = Array(activities.prefix(3))
    }
}

// MARK: - Calendar Events Preview
struct CalendarEventsPreview: View {
    @State private var hasCalendarAccess = false
    @State private var upcomingEvents: [String] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading calendar events...")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .padding(.leading, 8)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .center)
            } else if !hasCalendarAccess {
                Button(action: {
                    CalendarService.shared.requestCalendarAccess { granted in
                        hasCalendarAccess = granted
                        if granted {
                            loadEvents()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(ColorTheme.primary)
                        Text("Connect to Calendar")
                            .foregroundColor(ColorTheme.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ColorTheme.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 30))
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else {
                ForEach(upcomingEvents, id: \.self) { event in
                    HStack {
                        Circle()
                            .fill(ColorTheme.primary)
                            .frame(width: 8, height: 8)
                        
                        Text(event)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            checkCalendarAccess()
        }
    }
    
    private func checkCalendarAccess() {
        hasCalendarAccess = CalendarService.shared.hasCalendarAccess
        if hasCalendarAccess {
            loadEvents()
        } else {
            isLoading = false
        }
    }
    
    private func loadEvents() {
        // Simulate loading events
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, this would fetch actual calendar events
            upcomingEvents = [
                "Playdate with Emma - Today, 3:00 PM",
                "Swimming lessons - Tomorrow, 10:00 AM",
                "Zoo trip - Saturday, 9:00 AM"
            ]
            isLoading = false
        }
    }
}
