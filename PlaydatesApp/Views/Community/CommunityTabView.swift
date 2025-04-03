import SwiftUI

struct CommunityTabView: View {
    @State private var selectedTab = 0
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header for Community tab
            EnhancedCommunityHeader(isAnimating: $isAnimating)
            
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
        .onAppear {
            isAnimating = true
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
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(12)
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.lightText)
            .background(
                isSelected ? 
                    Color.white.opacity(0.1) : 
                    Color.clear
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? ColorTheme.primary : Color.clear)
                    .frame(height: 3)
                    .offset(y: 20),
                alignment: .bottom
            )
        }
        .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background/overlay
    }
}

// Enhanced header similar to the HomeView's header
struct EnhancedCommunityHeader: View {
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorTheme.accent,
                        ColorTheme.primary,
                        ColorTheme.highlight.opacity(0.8)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Overlay gradient for depth
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Subtle pattern overlay
                ZStack {
                    ForEach(0..<15) { i in
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
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: CGFloat([40, 30, 20][i]))
                        .offset(
                            x: CGFloat([120, -60, 40][i]),
                            y: CGFloat([-40, 50, -20][i])
                        )
                        .blur(radius: 2)
                }
                
                // Group icon
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: -80, y: 0)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Calendar icon
                Image(systemName: "calendar")
                    .font(.system(size: 35))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 0, y: -20)
                    .rotationEffect(.degrees(isAnimating ? -5 : 5))
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Resource icon
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 80, y: 0)
                    .rotationEffect(.degrees(isAnimating ? 7 : -7))
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Community content
            VStack(alignment: .leading, spacing: 12) {
                // Welcome content
                Text("Connect & Share")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Join groups, find events, and share resources")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Community stats
                HStack(spacing: 15) {
                    CommunityStat(
                        icon: "person.3",
                        value: "15",
                        title: "Groups"
                    )
                    
                    CommunityStat(
                        icon: "calendar",
                        value: "8",
                        title: "Events"
                    )
                    
                    CommunityStat(
                        icon: "cube.box",
                        value: "24",
                        title: "Resources"
                    )
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
        .padding(.bottom, 15)
    }
}

struct CommunityStat: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}
