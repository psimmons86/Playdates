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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Enhanced animated header
                EnhancedHomeHeader(isAnimating: $isAnimating)
                
                // Featured section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Featured Activities")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkPurple)
                        .padding(.horizontal)
                    
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
                .padding(.bottom, 24)
                
                // Category selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse by Category")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkPurple)
                        .padding(.horizontal)
                    
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
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
                
                // Upcoming Playdates
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Upcoming Playdates")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Spacer()
                        
                        Button(action: {
                            // View all playdates
                        }) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    if playdateViewModel.playdates.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ColorTheme.primary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 40))
                                    .foregroundColor(ColorTheme.primary)
                            }
                            
                            Text("No upcoming playdates")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)
                                .multilineTextAlignment(.center)
                            
                            Text("Create your first playdate to get started")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                // Create playdate
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14))
                                    
                                    Text("Create Playdate")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(ColorTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: ColorTheme.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
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
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 24)
                
                // Popular Activities
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Popular Activities")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Spacer()
                        
                        Button(action: {
                            // View all activities
                        }) {
                            Text("View All")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                    .padding(.horizontal)
                    
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
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
                
                // Wishlist section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Wishlist")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Spacer()
                        
                        if !wishlistActivities.isEmpty {
                            Button(action: {
                                wishlistActivities.removeAll()
                            }) {
                                Text("Clear All")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if wishlistActivities.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(ColorTheme.primary.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "heart")
                                    .font(.system(size: 40))
                                    .foregroundColor(ColorTheme.primary)
                            }
                            
                            Text("Your wishlist is empty")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)
                                .multilineTextAlignment(.center)
                            
                            Text("Add activities to your wishlist by tapping the heart icon")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
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
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
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
