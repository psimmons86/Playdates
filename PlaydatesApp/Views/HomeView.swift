import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase

// MARK: - Home View

struct HomeView: View {
    // View Models
    @StateObject private var playdateViewModel = PlaydateViewModel()
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainContainerViewModel: MainContainerViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel // Keep for other potential uses

    // State Variables
    @State private var isAnimating = false
    @State private var selectedPlaydate: Playdate? = nil
    @State private var showPlaydateDetail = false
    @State private var showingAllPlaydates = false
    @State private var showingAllActivities = false
    @State private var selectedPlace: ActivityPlace? = nil
    @State private var showPlaceDetail = false

    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)

            ScrollView {
                // Original structure before adding Favorites/WantToDo
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section Content
                    EnhancedHomeHeader(isAnimating: $isAnimating)
                        .environmentObject(authViewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 16) // Keep bottom padding for spacing between cards

                    // Weather Section Content wrapped in RoundedCard
                    RoundedCard {
                        WeatherView()
                            .padding() // Add padding inside the card
                    }
                    .padding(.horizontal) // Padding for the card itself
                    .padding(.bottom, 16)

                    // Calendar Section Content wrapped in RoundedCard
                    RoundedCard {
                        HomeCalendarView()
                            .environmentObject(playdateViewModel)
                            .padding() // Add padding inside the card
                    }
                    .padding(.horizontal) // Padding for the card itself
                    .padding(.bottom, 16)

                    // Upcoming Playdates Section (already uses SectionBox which uses RoundedCard)
                    SectionBox(
                        title: "Upcoming Playdates",
                        viewAllAction: { showingAllPlaydates = true }
                    ) {
                        UpcomingPlaydatesSectionContent( // Use the extracted struct
                            playdateViewModel: playdateViewModel,
                            selectedPlaydate: $selectedPlaydate,
                            showPlaydateDetail: $showPlaydateDetail,
                            upcomingPlaydates: upcomingPlaydates()
                        )
                    }
                    // .padding(.horizontal) // Padding handled by SectionBox

                    // Nearby Places Section Content wrapped in RoundedCard
                    RoundedCard {
                        NearbyPlacesSection { tappedPlace in
                            selectedPlace = tappedPlace
                            showPlaceDetail = true
                            print("Tapped on nearby place: \(tappedPlace.name)")
                        }
                        .environmentObject(authViewModel) // Pass explicitly if needed
                        .padding() // Add padding inside the card
                    }
                    .padding(.horizontal) // Padding for the card itself
                    .padding(.bottom, 16)


                    // Recent Activity Section (already uses SectionBox which uses RoundedCard)
                    SectionBox(
                        title: "Recent Activity",
                        viewAllAction: { showingAllActivities = true }
                    ) {
                        RecentActivitySectionContent() // Use the extracted struct
                    }
                    // .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .background(navigationLinks) // Restore background links
        }
        .onAppear(perform: onHomeViewAppear)
        .onDisappear(perform: onHomeViewDisappear)
    }

    // Hidden Navigation Links
    private var navigationLinks: some View {
        VStack {
            // Corrected initializer to pass playdateId (String) instead of the whole Playdate object
            NavigationLink(destination: PlaydateDetailView(playdateId: selectedPlaydate?.id ?? "invalid_id"), isActive: $showPlaydateDetail) { EmptyView() }
            NavigationLink(destination: PlaydatesListView(), isActive: $showingAllPlaydates) { EmptyView() }
            NavigationLink(destination: FullActivityFeedView(), isActive: $showingAllActivities) { EmptyView() }
            if let place = selectedPlace {
                NavigationLink(destination: PlaceDetailView(place: place), isActive: $showPlaceDetail) { EmptyView() }
            }
        }
    }

    // MARK: - Helper Functions & Lifecycle

    private func onHomeViewAppear() {
        print("HomeView appeared - fetching data...")
        if playdateViewModel.playdates.isEmpty {
             playdateViewModel.fetchPlaydates()
        }
        // NOTE: No longer fetching favorites/wishlist here
        // Fetch necessary data for existing sections if needed
        if appActivityViewModel.activities.isEmpty { // Example: Fetch recent activity if needed
             // appActivityViewModel.fetchActivities() // Assuming this method exists
        }
        isAnimating = true
        setupNotificationObservers()
    }

    private func onHomeViewDisappear() {
        removeNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToCreatePlaydate"), object: nil, queue: .main) { _ in
            mainContainerViewModel.selectedView = .create
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToExplore"), object: nil, queue: .main) { _ in
            mainContainerViewModel.selectedView = .explore
        }
    }

    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToCreatePlaydate"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToExplore"), object: nil)
    }

    private func upcomingPlaydates() -> [Playdate] {
        let now = Date()
        let upcoming = playdateViewModel.playdates
            .filter { $0.id != nil && $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
        
        var uniquePlaydates = [Playdate]()
        var seenIDs = Set<String>()
        for playdate in upcoming {
            if let id = playdate.id, !seenIDs.contains(id) {
                uniquePlaydates.append(playdate)
                seenIDs.insert(id)
            }
        }
        return uniquePlaydates
    }
}

// MARK: - Extracted Section Content Structs (Corrected - Removed .redacted errors)

struct UpcomingPlaydatesSectionContent: View {
    @ObservedObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var mainContainerViewModel: MainContainerViewModel
    @Binding var selectedPlaydate: Playdate?
    @Binding var showPlaydateDetail: Bool
    let upcomingPlaydates: [Playdate]

    var body: some View {
        // Restore original conditional logic
        if playdateViewModel.isLoading && upcomingPlaydates.isEmpty {
             ProgressView().frame(height: 150)
        } else if upcomingPlaydates.isEmpty {
            EmptyStateBox(
                icon: "calendar.badge.exclamationmark",
                title: "No upcoming playdates",
                message: "Plan your next adventure!",
                buttonTitle: "Create Playdate",
                buttonAction: { mainContainerViewModel.selectedView = .create }
            )
            .frame(height: 150)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(upcomingPlaydates.prefix(5)) { playdate in // Iterate over actual data
                        Button {
                            selectedPlaydate = playdate
                            showPlaydateDetail = true
                        } label: {
                             EnhancedPlaydateCard(playdate: playdate)
                                 .frame(width: 280)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 150)
        }
        // Removed .redacted modifier entirely as it caused issues
    }
}

struct RecentActivitySectionContent: View {
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel

    var body: some View {
        // Restore original conditional logic
         if appActivityViewModel.isLoading && appActivityViewModel.activities.isEmpty {
             ProgressView().frame(height: 200)
         } else if appActivityViewModel.activities.isEmpty {
             EmptyStateBox(
                 icon: "sparkles",
                 title: "No recent activity",
                 message: "See what your friends are up to!",
                 buttonTitle: nil,
                 buttonAction: nil
             )
             .frame(height: 200)
         } else {
             ActivityFeedView()
                 .frame(height: 300)
                 .clipped()
                 // Removed allowsHitTesting modifier
         }
         // Removed .redacted modifier entirely
    }
}


// MARK: - Preview Provider (Adjusted)

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let friendVM = FriendManagementViewModel(authViewModel: authVM)
        let appActivityVM = AppActivityViewModel(authViewModel: authVM, friendManagementViewModel: friendVM)
        let activityVM = ActivityViewModel.shared // Still needed in environment
        let mainContainerVM = MainContainerViewModel.shared

        authVM.user = User(id: "previewUser", name: "Preview User", email: "preview@test.com")
        appActivityVM.activities = [
             AppActivity(id: "preview1", type: .newPlaydate, title: "Park Fun", description: "Let's meet at Central Park playground tomorrow at 10 AM!", timestamp: Date().addingTimeInterval(-3600*2), userID: "user1", userName: "Alice Smith", userProfileImageURL: nil, contentImageURL: nil, likeCount: 5, commentCount: 2)
        ]

        return NavigationView {
            HomeView()
                .environmentObject(authVM)
                .environmentObject(appActivityVM)
                .environmentObject(mainContainerVM)
                .environmentObject(activityVM) // Keep activityVM in environment
                .environmentObject(friendVM)
        }
    }
}
