import SwiftUI

// Enum to represent the different views accessible from the side menu
// Enum to represent the different views accessible from the side menu
enum AppView: String, CaseIterable {
    case home = "Home"
    case suggestions = "Suggestions" // Added Suggestions case
    case explore = "Explore"
    case social = "Social"
    case community = "Community"
    case create = "Create Playdate"
    case profile = "Profile"
    case notifications = "Notifications" // Added Notifications case
    case wishlist = "Want to Do" // Added Wishlist case
    case admin = "Admin"
}

struct SideMenuView: View {
    @Binding var selectedView: AppView
    @Binding var isShowing: Bool
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading) {
                ZStack {
                    if #available(iOS 17.0, *), let profileImageURL = authViewModel.user?.profileImageURL, !profileImageURL.isEmpty {
                        ProfileImageView(imageURL: profileImageURL, size: 80)
                            .overlay(
                                Circle()
                                    .stroke(ColorTheme.primary, lineWidth: 2)
                            )
                    } else {
                        Circle()
                            .fill(ColorTheme.primary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ColorTheme.primary)
                            )
                    }
                    
                    // Upload button
                    Circle()
                        .fill(ColorTheme.primary)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        )
                        .offset(x: 30, y: 30)
                        .onTapGesture {
                            // Navigate to profile view where user can edit profile
                            selectedView = .profile
                            withAnimation(.spring()) {
                                isShowing = false
                            }
                        }
                }
                Text(authViewModel.user?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primary)
                Text(authViewModel.user?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading)
            .padding(.top, 80) // Increase top padding to avoid overlap with navigation bar
            .padding(.bottom, 30)

            // Menu Items
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    menuButton(icon: "house.fill", title: "Home", view: .home)
                    menuButton(icon: "lightbulb.fill", title: "Suggestions", view: .suggestions) // Added Suggestions button
                    menuButton(icon: "map.fill", title: "Explore", view: .explore)
                    menuButton(icon: "person.2.fill", title: "Social", view: .social)
                    menuButton(icon: "person.3.fill", title: "Community", view: .community)
                    menuButton(icon: "plus.circle.fill", title: "Create Playdate", view: .create)
                    menuButton(icon: "person.fill", title: "Profile", view: .profile)
                    menuButton(icon: "bell.fill", title: "Notifications", view: .notifications) // Added Notifications row
                    menuButton(icon: "bookmark.fill", title: "Want to Do", view: .wishlist) // Added Wishlist row

                    if authViewModel.user?.email == "hadroncollides@icloud.com" {
                        Divider().padding(.vertical)
                        menuButton(icon: "shield.fill", title: "Admin", view: .admin)
                    }
                }
            }

            Spacer()

            // Logout Button
            Divider()
            Button { // Use trailing closure syntax
                authViewModel.signOut()
                isShowing = false
            } label: {
                HStack {
                    Image(systemName: "arrow.left.square.fill")
                    Text("Logout")
                }
                // Color handled by textStyle
                .padding() // Keep padding for spacing
            }
            .textStyle(color: .red) // Apply text style with red color
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Apply edgesIgnoringSafeArea only to the background
    }

    private func menuButton(icon: String, title: String, view: AppView) -> some View {
        Button(action: {
            selectedView = view
            withAnimation(.spring()) {
                isShowing = false
            }
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: 25)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.leading)
            .foregroundColor(selectedView == view ? ColorTheme.primary : ColorTheme.primary)
            .background(selectedView == view ? ColorTheme.primary.opacity(0.1) : Color.clear)
            .cornerRadius(5)
            .padding(.horizontal, 8)
        }
        .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background
    }
}
