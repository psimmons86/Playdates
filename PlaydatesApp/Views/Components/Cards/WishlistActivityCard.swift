import SwiftUI
import Foundation

struct WishlistActivityCard: View {
    let activity: Activity
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Activity icon
            Circle()
                .fill(activityColor(for: activity.type).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: activityIcon(for: activity.type))
                        .font(.system(size: 24))
                        .foregroundColor(activityColor(for: activity.type))
                )
            
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
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(ColorTheme.lightText)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
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

struct WishlistActivityCard_Previews: PreviewProvider {
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
            )
        )
        
        WishlistActivityCard(
            activity: mockActivity,
            onRemove: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
