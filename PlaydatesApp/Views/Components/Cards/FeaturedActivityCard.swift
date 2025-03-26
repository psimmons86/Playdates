import SwiftUI
import Foundation

struct FeaturedActivityCard: View {
    let activity: Activity
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or color
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            activityColor(for: activity.type).opacity(0.7),
                            activityColor(for: activity.type)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Activity type badge
                HStack(spacing: 4) {
                    Image(systemName: activityIcon(for: activity.type))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text(activity.type.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                Spacer()
                
                // Activity details
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(activity.location.name)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Rating
                    if let rating = activity.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < Int(rating) ? "star.fill" : "star")
                                    .font(.system(size: 12))
                                    .foregroundColor(i < Int(rating) ? .yellow : .white.opacity(0.5))
                            }
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.leading, 4)
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 180)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
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

struct FeaturedActivityCard_Previews: PreviewProvider {
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
            rating: 4.5
        )
        
        FeaturedActivityCard(activity: mockActivity)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
