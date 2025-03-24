import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var playdateViewModel: PlaydateViewModel
    @EnvironmentObject private var activityViewModel: ActivityViewModel
    @EnvironmentObject private var locationManager: LocationManager
    
    @State private var showingCreatePlaydateSheet = false
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome section
                    welcomeSection
                    
                    // Upcoming playdates section
                    upcomingPlaydatesSection
                    
                    // Playdate invitations section
                    playdateInvitationsSection
                    
                    // Nearby activities section
                    nearbyActivitiesSection
                    
                    // Featured activities section
                    featuredActivitiesSection
                }
                .padding()
            }
            .refreshable {
                await refreshData()
            }
            .navigationTitle("Home")
            .navigationBarItems(
                trailing: Button(action: {
                    showingCreatePlaydateSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorTheme.primary)
                        .padding(8)
                        .background(ColorTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            )
            .sheet(isPresented: $showingCreatePlaydateSheet) {
                CreatePlaydateView()
            }
        }
        .onAppear {
            refreshLocation()
        }
    }
    
    // MARK: - Sections
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(authViewModel.user?.name.components(separatedBy: " ").first ?? "Friend")!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text("What would you like to do today?")
                .font(.subheadline)
                .foregroundColor(ColorTheme.text.opacity(0.7))
        }
        .padding(.bottom, 10)
    }
    
    private var upcomingPlaydatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming Playdates", actionText: "See All") {
                // Navigate to Playdates tab
            }
            
            if playdateViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if playdateViewModel.upcomingPlaydates.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Upcoming Playdates",
                    message: "Create a playdate or join one to see it here."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(playdateViewModel.upcomingPlaydates.prefix(5)) { playdate in
                            PlaydateCard(playdate: playdate)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var playdateInvitationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !playdateViewModel.invitedPlaydates.isEmpty {
                SectionHeader(title: "Playdate Invitations", actionText: "See All") {
                    // Navigate to Playdates tab
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(playdateViewModel.invitedPlaydates) { playdate in
                            PlaydateInvitationCard(playdate: playdate)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var nearbyActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Nearby Activities", actionText: "See All") {
                // Navigate to Explore tab
            }
            
            if activityViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if activityViewModel.nearbyActivities.isEmpty {
                EmptyStateView(
                    icon: "map",
                    title: "No Nearby Activities",
                    message: "Enable location services to discover activities near you."
                )
                .onTapGesture {
                    locationManager.requestPermission()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(activityViewModel.nearbyActivities.prefix(5)) { activity in
                            ActivityCard(activity: activity)
                                .frame(width: 200, height: 220)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var featuredActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Featured Activities", actionText: "See All") {
                // Navigate to Explore tab
            }
            
            if activityViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if activityViewModel.featuredActivities.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Featured Activities",
                    message: "Check back later for featured activities."
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(activityViewModel.featuredActivities.prefix(5)) { activity in
                            FeaturedActivityCard(activity: activity)
                                .frame(width: 300, height: 180)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        isRefreshing = true
        
        if let userID = authViewModel.user?.id {
            playdateViewModel.fetchPlaydates(for: userID)
            activityViewModel.fetchActivities()
            
            if let location = locationManager.location {
                activityViewModel.fetchNearbyActivities(location: location)
            }
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
    
    private func refreshLocation() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(PlaydateViewModel())
            .environmentObject(ActivityViewModel())
            .environmentObject(LocationManager())
    }
}
