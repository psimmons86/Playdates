import SwiftUI
import Foundation

struct PopularActivityCard: View {
    let activity: Activity
    let onAddToWishlist: () -> Void
    let isInWishlist: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Activity image or icon
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(activityColor(for: activity.type).opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: activityIcon(for: activity.type))
                            .font(.system(size: 30))
                            .foregroundColor(activityColor(for: activity.type))
                    )
                
                // Wishlist button
                Button(action: onAddToWishlist) {
                    Image(systemName: isInWishlist ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isInWishlist ? ColorTheme.highlight : ColorTheme.lightText)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .offset(x: 10, y: -10)
            }
            .padding(.top, 8)
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                    .lineLimit(1)
                
                Text(activity.location.name)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(1)
                
                // Rating
                if let rating = activity.rating {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < Int(rating) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(i < Int(rating) ? .yellow : ColorTheme.lightText)
                        }
                        
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                            .padding(.leading, 2)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func activityColor(for type: ActivityType) -> Color {
        switch type {
        case .park:
            return Color.green
        case .museum:
            return Color.orange
        case .playground:
            return Color.blue
        case .swimmingPool:
            return Color.cyan
        case .zoo:
            return Color.brown
        default:
            return ColorTheme.primary
        }
    }
    
    private func activityIcon(for type: ActivityType) -> String {
        switch type {
        case .park:
            return "leaf.fill"
        case .museum:
            return "building.columns.fill"
        case .playground:
            return "figure.play"
        case .swimmingPool:
            return "drop.fill"
        case .zoo:
            return "pawprint.fill"
        default:
            return "star.fill"
        }
    }
}

struct PopularActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivity = Activity(
            id: "mock-id",
            name: "Central Park",
            description: "A beautiful park in the heart of the city",
            type: .park,
            location: Location(
                id: "loc-1",
                name: "Central Park",
                address: "New York, NY",
                latitude: 40.7812,
                longitude: -73.9665
            ),
            rating: 4.5,
            createdAt: Date()
        )
        
        PopularActivityCard(
            activity: mockActivity,
            onAddToWishlist: {},
            isInWishlist: false
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
