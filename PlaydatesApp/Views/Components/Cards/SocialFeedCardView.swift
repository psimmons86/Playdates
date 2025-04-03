import SwiftUI

struct SocialFeedCardView: View {
    let activity: AppActivity
    // Placeholder for potential future properties like like counts, comment counts, images etc.
    // let likeCount: Int = 0
    // let commentCount: Int = 0
    // let contentImageUrl: String? = nil // URL for a potential image in the post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- Header ---
            HStack(spacing: 12) {
                // Use ProfileImageView with the URL from the activity
                ProfileImageView(imageURL: activity.userProfileImageURL, size: 44) // Increased size slightly

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.userName ?? "Unknown User") // Display user name
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorTheme.text) // Use ColorTheme.text

                    Text(activity.timeAgo) // Display time ago
                        .font(.system(size: 13))
                        .foregroundColor(ColorTheme.lightText) // Use ColorTheme.lightText
                }
                Spacer()
                // Optional: More actions button
                Button {
                    // Action for more options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(ColorTheme.lightText) // Use ColorTheme.lightText
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // --- Content ---
            // Display the main description of the activity
            Text(activity.description)
                .font(.system(size: 15))
                .foregroundColor(ColorTheme.text) // Use ColorTheme.text
                .lineSpacing(4)
                .padding(.horizontal)
                .padding(.bottom, 12)

            // --- Content Image ---
            if let imageURLString = activity.contentImageURL, let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit() // Or .scaledToFill() depending on desired cropping
                            .cornerRadius(8) // Optional corner radius for the image
                            .padding(.horizontal) // Match text padding
                            .padding(.bottom, 12)
                    case .failure:
                        // Placeholder or error view if image fails to load
                        EmptyView() // Or Image(systemName: "photo.fill").foregroundColor(.gray)
                    case .empty:
                        // Placeholder while loading
                        ProgressView()
                            .frame(height: 200) // Example height
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // --- Footer ---
            HStack(spacing: 20) {
                Button {
                    // Action for liking - TODO: Add actual like/unlike logic in ViewModel
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: activity.isLiked ? "heart.fill" : "heart") // Use filled heart if liked
                        Text("\(activity.likeCount)") // Display like count
                    }
                }
                .foregroundColor(activity.isLiked ? ColorTheme.primary : ColorTheme.lightText) // Use ColorTheme.lightText

                Button {
                    // Action for commenting
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(activity.commentCount)") // Display comment count
                    }
                }
                .foregroundColor(ColorTheme.lightText) // Use ColorTheme.lightText

                Spacer()

                Button {
                    // Action for sharing
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(ColorTheme.lightText) // Use ColorTheme.lightText
            }
            .font(.system(size: 14))
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.white) // Card background
        .cornerRadius(10)       // Rounded corners
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2) // Subtle shadow
        .padding(.horizontal)   // Padding around the card
        .padding(.vertical, 6)  // Spacing between cards
    }
}

// MARK: - Preview
struct SocialFeedCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivity = AppActivity(
            id: "preview1",
            type: .newPlaydate,
            title: "New Playdate Created", // Title might not be directly used in card header
            description: "Sarah created a new playdate at Golden Gate Park. It's going to be sunny! Who wants to join? We'll bring snacks.",
            timestamp: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
            userID: "user1",
            userName: "Sarah Johnson",
            userProfileImageURL: nil, // Example with no profile image
            contentImageURL: nil, // Example with no content image
            likeCount: 15,
            commentCount: 3,
            isLiked: true // Example where current user liked it
        )
        
        let mockActivity2 = AppActivity(
            id: "preview2",
            type: .newFriend,
            title: "New Friend",
            description: "You and Mark are now friends.",
            timestamp: Date().addingTimeInterval(-86400), // 1 day ago
            userID: "user2",
            userName: "Mark Davis",
            userProfileImageURL: "https://example.com/mark_davis.jpg", // Example with profile image
            likeCount: 0,
            commentCount: 0
        )

        ScrollView { // Wrap in ScrollView for context
            VStack(spacing: 0) { // Use spacing 0 as card handles its own padding
                SocialFeedCardView(activity: mockActivity)
                SocialFeedCardView(activity: mockActivity2)
            }
        }
        .background(ColorTheme.background) // Background for preview
    }
}

// Helper extension moved from ActivityRow (assuming AppActivity has iconColor string)
extension AppActivity {
    var iconColorFromString: Color {
        switch self.iconColor {
            case "primary": return ColorTheme.primary
            case "blue": return .blue
            case "green": return .green
            case "purple": return .purple
            case "orange": return .orange
            case "pink": return .pink
            default: return ColorTheme.primary
        }
    }
}
