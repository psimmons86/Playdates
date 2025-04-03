import SwiftUI
import Foundation

// MARK: - Playdate Card
struct PlaydateCard: View {
    let playdate: Playdate
    // Removed @State private var isAnimating = false
    
    var body: some View {
        RoundedCard { // Replaced GradientCard with RoundedCard
            VStack(alignment: .leading, spacing: 12) {
                // Header with activity type icon
                HStack {
                    // Activity type icon
                    activityTypeIcon
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        // Title
                        Text(playdate.title)
                            .font(.headline)
                            .foregroundColor(ColorTheme.text) // Changed from .white
                            .lineLimit(1)
                        
                        // Host info if available
                        Text("Hosted by You") // TODO: Replace with actual host name if available
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText) // Changed from .white.opacity(0.8)
                    }
                    
                    Spacer()
                    
                    // Date badge
                    VStack(spacing: 0) {
                        Text(dayOfMonth)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ColorTheme.darkPurple) // Changed from .white
                        
                        Text(monthAbbreviation)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorTheme.darkPurple) // Changed from .white
                    }
                    .frame(width: 40, height: 40)
                    .background(ColorTheme.primaryLight.opacity(0.5)) // Changed background
                    .cornerRadius(8)
                }
                
                Divider()
                    .background(ColorTheme.lightText.opacity(0.3)) // Changed divider color
                
                // Date and time
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(ColorTheme.lightText) // Changed from .white
                    
                    Text(formatTime(playdate.startDate))
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text) // Changed from .white.opacity(0.9)
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(ColorTheme.lightText) // Changed from .white
                    
                    Text(playdate.location?.name ?? playdate.address ?? "Location TBD")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text) // Changed from .white.opacity(0.9)
                        .lineLimit(1)
                }
                
                // Attendees
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(ColorTheme.lightText) // Changed from .white
                    
                    Text("\(playdate.attendeeIDs.count) attending")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text) // Changed from .white.opacity(0.9)
                }
            }
            .padding()
        }
        // Removed activityColor computed property
    }
    
    // Helper properties for date formatting
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: playdate.startDate)
    }
    
    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: playdate.startDate)
    }
    
    // Helper function to format time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Removed activityColor computed property
    
    // Activity type icon based on playdate activity type
    private var activityTypeIcon: some View {
        let activityType = ActivityType(rawValue: playdate.activityType ?? "other") ?? .other
        
        let systemName: String
        switch activityType {
        case .park:
            systemName = "leaf.fill"
        case .museum:
            systemName = "building.columns.fill"
        case .playground:
            systemName = "figure.play"
        case .library:
            systemName = "book.fill"
        case .swimmingPool:
            systemName = "figure.pool.swim"
        case .sportingEvent:
            systemName = "sportscourt.fill"
        case .zoo:
            systemName = "pawprint.fill"
        case .aquarium:
            systemName = "drop.fill"
        case .movieTheater:
            systemName = "film.fill"
        case .themePark:
            systemName = "ferriswheel"
        default:
            systemName = "mappin.circle.fill"
        }
        
        return Image(systemName: systemName)
            .font(.system(size: 24))
            .foregroundColor(ColorTheme.darkPurple) // Changed from .white
            .frame(width: 40, height: 40)
            .background(ColorTheme.primaryLight.opacity(0.5)) // Changed background
            .clipShape(Circle())
    }
}
