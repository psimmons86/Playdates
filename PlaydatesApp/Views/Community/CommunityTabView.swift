import SwiftUI

struct CommunityTabView: View {
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var groupViewModel: GroupViewModel
    @EnvironmentObject var resourceViewModel: ResourceViewModel
    @EnvironmentObject var communityEventViewModel: CommunityEventViewModel
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Enhanced header
                CommunityHeader(isAnimating: $isAnimating)
                    .padding(.bottom, 16)
                
                // Custom tab bar
                CommunityTabBar(selectedTab: $selectedTab)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    GroupsView()
                        .environmentObject(groupViewModel)
                        .tag(0)
                    
                    CommunityEventsView()
                        .environmentObject(communityEventViewModel)
                        .tag(1)
                    
                    ResourceSharingView()
                        .environmentObject(resourceViewModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationBarTitle("Community", displayMode: .inline)
        .onAppear {
            isAnimating = true
            
            // Load mock data for testing
            groupViewModel.addMockData()
            resourceViewModel.addMockData()
            communityEventViewModel.addMockData()
        }
    }
}

struct CommunityHeader: View {
    @Binding var isAnimating: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorTheme.primary,
                        ColorTheme.accent,
                        ColorTheme.highlight
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Overlay gradient for depth
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Subtle pattern overlay
                ZStack {
                    ForEach(0..<10) { i in
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 20, height: 20)
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: CGFloat.random(in: -60...60)
                            )
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal)
            
            // Decorative elements
            ZStack {
                // Floating circles
                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 30, height: 30)
                            .offset(x: isAnimating ? 0 : -10, y: isAnimating ? 0 : 5)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .offset(x: -80, y: -40)
                
                // Floating shapes
                ForEach(0..<2) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 25, height: 25)
                        .rotationEffect(.degrees(isAnimating ? 45 : 0))
                        .offset(
                            x: CGFloat([70, -70][i]),
                            y: CGFloat([20, -30][i])
                        )
                        .animation(
                            Animation.easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.5),
                            value: isAnimating
                        )
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("Community")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Connect with other parents and families")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 30)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

struct CommunityTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            CommunityTabButton(
                title: "Groups",
                icon: "person.3",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            CommunityTabButton(
                title: "Events",
                icon: "calendar",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            CommunityTabButton(
                title: "Resources",
                icon: "cube.box",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct CommunityTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.lightText)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ColorTheme.primary.opacity(0.1))
                            .matchedGeometryEffect(id: "background", in: NamespaceWrapper.namespace)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Namespace wrapper for matched geometry effect
struct NamespaceWrapper {
    @Namespace static var namespace
}

// Update MainTabView to include the CommunityTabView
extension MainTabView {
    static func updated() -> some View {
        TabView {
            // Home Tab
            NavigationView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Explore Tab
            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "map.fill")
            }
            
            // Create Tab
            NavigationView {
                NewPlaydateView()
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle.fill")
            }
            
            // Community Tab (New)
            NavigationView {
                CommunityTabView()
            }
            .tabItem {
                Label("Community", systemImage: "person.3.fill")
            }
            
            // Profile Tab
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .accentColor(ColorTheme.primary)
    }
}

struct CommunityTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommunityTabView()
        }
        .environmentObject(AuthViewModel())
        .environmentObject(GroupViewModel.shared)
        .environmentObject(ResourceViewModel.shared)
        .environmentObject(CommunityEventViewModel.shared)
    }
}
