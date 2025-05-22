import SwiftUI

// MARK: - Friends Section View
struct FriendsSectionView: View {
    let friends: [User]
    let isLoading: Bool
    let errorMessage: String?
    @Binding var showingAddFriendSheet: Bool

    // Define grid layout for friends
    private let gridItems = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Friends")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white) // Adjust for card background
                
                Spacer()
                
                NavigationLink(destination: AddFriendView(isPresented: $showingAddFriendSheet)) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            }

            if isLoading {
                ProgressView()
                    .tint(.white) // Adjust progress view color
                    .frame(maxWidth: .infinity, minHeight: 50)
            } else if let error = errorMessage {
                Text(error) // Error messages should be localized where they are set
                    .font(.caption)
                    .foregroundColor(.yellow) // Use yellow for error text on dark background
                    .frame(maxWidth: .infinity, minHeight: 50)
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(NSLocalizedString("profile.friendsSection.empty", comment: "Empty state message for friends list"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8)) // Adjust for card background
                        .frame(maxWidth: .infinity)
                    
                    NavigationLink(destination: AddFriendView(isPresented: $showingAddFriendSheet)) {
                        Text("Find Friends")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .background(ColorTheme.primary.opacity(0.7))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                // Use LazyVGrid for a 2-column layout
                LazyVGrid(columns: gridItems, spacing: 16) {
                    ForEach(friends.prefix(6)) { friend in
                        FriendGridItemView(friend: friend)
                    }
                }
                
                if friends.count > 6 {
                    NavigationLink(destination: FriendsView()) {
                        HStack {
                            Text("View All Friends")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                }
            }
        }
        .padding() // Padding inside the card content
        // Background/cornerRadius/shadow handled by RoundedCard
    }
}

// MARK: - Friend Grid Item View
struct FriendGridItemView: View {
    let friend: User

    var body: some View {
        // Use NavigationLink to make the item tappable
        NavigationLink(destination: ProfileView(userId: friend.id, user: friend)) {
            VStack(spacing: 8) {
                ProfileImageView(imageURL: friend.profileImageURL, size: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                Text(friend.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white) // Adjust for card background
                    .lineLimit(1)
                
                if let bio = friend.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(12)
            .frame(height: 120)
            .background(Color.white.opacity(0.1)) // Subtle background for each item
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling from NavigationLink
    }
}
