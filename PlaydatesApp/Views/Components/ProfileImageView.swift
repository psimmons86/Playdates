import SwiftUI

@available(iOS 17.0, *)
public struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat
    
    public init(imageURL: String?, size: CGFloat) {
        self.imageURL = imageURL
        self.size = size
    }
    
    public var body: some View {
        if let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
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

#Preview {
    VStack(spacing: 20) {
        ProfileImageView(imageURL: nil, size: 60)
        ProfileImageView(imageURL: "https://example.com/invalid.jpg", size: 60)
        ProfileImageView(imageURL: "https://example.com/valid.jpg", size: 60)
    }
    .padding()
}
