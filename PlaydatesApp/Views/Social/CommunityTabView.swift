import SwiftUI

struct CommunityTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            CommunityTabBar(selectedTab: $selectedTab)
            
            // Tab content
            TabView(selection: $selectedTab) {
                GroupsView()
                    .tag(0)
                
                CommunityEventsView()
                    .tag(1)
                
                ResourceSharingView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationBarTitle("Community", displayMode: .inline)
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
        .frame(height: 50)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.lightText)
            .background(
                ZStack {
                    if isSelected {
                        Rectangle()
                            .fill(ColorTheme.primary)
                            .frame(height: 3)
                            .offset(y: 16)
                    }
                }
            )
        }
    }
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
    }
}
