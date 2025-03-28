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
        let activityColor = getColorForActivityType(activity.type)
        
        ZStack(alignment: .bottomLeading) {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [activityColor, activityColor.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Activity icon
                Image(systemName: activity.type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                Spacer()
                
                // Activity name
                Text(activity.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Activity location
                Text(activity.location.name)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Action button if provided
                if let action = buttonAction {
                    Button(action: action) {
                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(activityColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
        // Removed fixed height to allow natural sizing
        .cornerRadius(16)
        .shadow(color: activityColor.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

struct FeaturedActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock activity for preview
        let mockLocation = Location(name: "Central Park", address: "New York, NY", latitude: 40.7812, longitude: -73.9665)
        let mockActivity = Activity(
            id: "preview-1",
            name: "Family Picnic",
            description: "Enjoy a day at the park with family activities",
            type: .park,
            location: mockLocation
        )
        
        return FeaturedActivityCard(
            activity: mockActivity,
            buttonAction: nil
        )
        .frame(width: 300, height: 200)
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
