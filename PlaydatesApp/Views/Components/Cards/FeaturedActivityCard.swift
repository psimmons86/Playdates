import SwiftUI

struct FeaturedActivityCard: View {
    let activity: Activity
    let buttonAction: (() -> Void)?
    
    // Function to get color based on activity type
    private func getColorForActivityType(_ type: ActivityType) -> Color {
        switch type {
        case .park, .playground, .hikingTrail:
            return ColorTheme.primary
        case .themePark, .beach, .summerCamp:
            return ColorTheme.highlight
        case .museum, .library, .movieTheater:
            return ColorTheme.darkPurple
        case .zoo, .aquarium:
            return ColorTheme.accent
        case .sportingEvent, .swimmingPool, .indoorPlayArea:
            return Color.blue
        case .other:
            return ColorTheme.primaryDark
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image Background
            activityImageView
            
            // Gradient Overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0)]),
                startPoint: .bottom,
                endPoint: .center
            )
            
            // Content Overlay
            VStack(alignment: .leading, spacing: 6) { // Reduced spacing
                Text(activity.name)
                    .font(.headline) // Adjusted font size
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2) // Allow two lines for name
                
                Text(activity.location.name)
                    .font(.caption) // Smaller font for location
                    .foregroundColor(.white.opacity(0.9))
                
                // Rating (optional)
                if let rating = activity.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12) // Adjusted padding
        }
        .frame(height: 200) // Give the card a fixed height
        .background(Color(.systemGray5)) // Background color for loading/error state
        .cornerRadius(16) // More rounded corners
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Softer shadow
        .onTapGesture {
            buttonAction?() // Execute action on tap if provided
        }
    }
    
    // ViewBuilder for the image part
    @ViewBuilder
    private var activityImageView: some View {
        if let photos = activity.photos, let firstPhotoUrlString = photos.first, let url = URL(string: firstPhotoUrlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fill the frame
                case .failure:
                    defaultImagePlaceholder // Show placeholder on failure
                @unknown default:
                    defaultImagePlaceholder
                }
            }
        } else {
            defaultImagePlaceholder // Show placeholder if no photos
        }
    }
    
    // Placeholder view
    private var defaultImagePlaceholder: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeaturedActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock activity for preview
        let mockLocation = Location(name: "Central Park", address: "New York, NY", latitude: 40.7812, longitude: -73.9665)
        let mockActivity = Activity(
            id: "preview-1",
            name: "Family Picnic in the Big Apple Park Area", // Longer name
            description: "Enjoy a day at the park with family activities",
            type: .park,
            location: mockLocation,
            photos: ["https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?ixlib=rb-1.2.1&auto=format&fit=crop&w=600&q=80"], // Example image
            rating: 4.3
        )
        
        return FeaturedActivityCard(
            activity: mockActivity,
            buttonAction: { print("Card tapped") }
        )
        .frame(width: 250) // Adjust width for preview
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
