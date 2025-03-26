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
    
    // Wishlist state
    @State private var wishlistActivities: [Activity] = []
    
    private let categories = ["All", "Parks", "Museums", "Playgrounds", "Swimming", "Zoo"]
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Enhanced animated header
                    EnhancedHomeHeader(isAnimating: $isAnimating)
                    
                    // Featured section
                    SectionBox(title: "Featured Activities") {
                        // Featured carousel
                        TabView {
                            ForEach(featuredActivities) { activity in
                                Button(action: {
                                    // Navigate to activity detail
                                }) {
                                    FeaturedActivityCard(activity: activity)
                                }
                            }
                        }
                        .frame(height: 200)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                            ForEach(filteredActivities.prefix(4)) { activity in
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
                    
                    // Wishlist section
                    SectionBox(
                        title: "Your Wishlist",
                        viewAllAction: wishlistActivities.isEmpty ? nil : {
                            wishlistActivities.removeAll()
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
                                                removeFromWishlist(activity)
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
            activityViewModel.fetchActivities()
            activityViewModel.fetchPopularActivities()
            playdateViewModel.fetchPlaydates()
            
            // Start animations
            isAnimating = true
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
    
    // Featured activities (could be curated or just the top rated ones)
    private var featuredActivities: [Activity] {
        // Sort by rating and take the top 3
        return activityViewModel.activities
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Wishlist Functions
    
    // Check if an activity is in the wishlist
    private func isInWishlist(_ activity: Activity) -> Bool {
        return wishlistActivities.contains { $0.id == activity.id }
    }
    
    // Add or remove an activity from the wishlist
    private func toggleWishlist(_ activity: Activity) {
        if isInWishlist(activity) {
            removeFromWishlist(activity)
        } else {
            addToWishlist(activity)
        }
    }
    
    // Add an activity to the wishlist
    private func addToWishlist(_ activity: Activity) {
        // Only add if not already in wishlist
        if !isInWishlist(activity) {
            wishlistActivities.append(activity)
        }
    }
    
    // Remove an activity from the wishlist
    private func removeFromWishlist(_ activity: Activity) {
        wishlistActivities.removeAll { $0.id == activity.id }
    }
}
