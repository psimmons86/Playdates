import SwiftUI

// MARK: - Profile Image View

/// A reusable view for displaying a user's profile image
struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat
    
    var body: some View {
        if let imageURL = imageURL, !imageURL.isEmpty {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure:
                    defaultImage
                @unknown default:
                    defaultImage
                }
            }
        } else {
            defaultImage
        }
    }
    
    private var defaultImage: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.5))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(ColorTheme.primary.opacity(0.7))
            .clipShape(Circle())
    }
}

// MARK: - Preview Provider

struct SharedComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Profile image with URL
            ProfileImageView(
                imageURL: "https://example.com/profile.jpg",
                size: 60
            )
            
            // Profile image without URL
            ProfileImageView(
                imageURL: nil,
                size: 40
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
