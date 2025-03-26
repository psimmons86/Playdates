import SwiftUI
import Foundation

// MARK: - Playdate Card
struct PlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
        GradientCard(
            gradientColors: [Color.white, Color.white.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom,
            animation: nil
        ) {
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
                            .foregroundColor(ColorTheme.darkPurple)
                            .lineLimit(1)
                        
                        // Host info if available
                        Text("Hosted by You")
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    }
                    
                    Spacer()
                    
                    // Date badge
                    GradientCard(
                        gradientColors: [ColorTheme.highlight, ColorTheme.highlight.opacity(0.8)],
                        cornerRadius: 8,
                        shadowRadius: 4,
                        shadowColor: ColorTheme.highlight.opacity(0.3),
                        animation: Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
                    ) {
                        VStack(spacing: 0) {
                            Text(dayOfMonth)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(monthAbbreviation)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                    }
                }
                
                Divider()
                
                // Date and time
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(ColorTheme.primary)
                    
                    Text(formatTime(playdate.startDate))
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(ColorTheme.primary)
                    
                    Text(playdate.location?.name ?? playdate.address ?? "Location TBD")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                }
                
                // Attendees
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(ColorTheme.primary)
                    
                    Text("\(playdate.attendeeIDs.count) attending")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
            }
            .padding()
        }
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
    
    // Activity type icon based on playdate activity type
    private var activityTypeIcon: some View {
        let activityType = ActivityType(rawValue: playdate.activityType ?? "other") ?? .other
        
        switch activityType {
        case .park:
            return activityIconView(
                systemName: "leaf.fill",
                color: Color(red: 0.02, green: 0.84, blue: 0.63)
            )
        case .museum:
            return activityIconView(
                systemName: "building.columns.fill",
                color: ColorTheme.accent
            )
        case .playground:
            return activityIconView(
                systemName: "figure.play",
                color: ColorTheme.highlight
            )
        case .library:
            return activityIconView(
                systemName: "book.fill",
                color: ColorTheme.accent
            )
        case .swimmingPool:
            return activityIconView(
                systemName: "figure.pool.swim",
                color: Color(red: 0.07, green: 0.54, blue: 0.7)
            )
        case .sportingEvent:
            return activityIconView(
                systemName: "sportscourt.fill",
                color: Color(red: 0.94, green: 0.28, blue: 0.44)
            )
        case .zoo:
            return activityIconView(
                systemName: "pawprint.fill",
                color: ColorTheme.highlight
            )
        case .aquarium:
            return activityIconView(
                systemName: "drop.fill",
                color: Color(red: 0.07, green: 0.54, blue: 0.7)
            )
        case .movieTheater:
            return activityIconView(
                systemName: "film.fill",
                color: Color(red: 0.46, green: 0.47, blue: 0.93)
            )
        case .themePark:
            return activityIconView(
                systemName: "ferriswheel",
                color: Color(red: 0.94, green: 0.28, blue: 0.44)
            )
        default:
            return activityIconView(
                systemName: "mappin.circle.fill",
                color: ColorTheme.primary
            )
        }
    }
    
    private func activityIconView(systemName: String, color: Color) -> some View {
        GradientCard(
            gradientColors: [color, color.opacity(0.8)],
            cornerRadius: 20,
            shadowRadius: 4,
            shadowColor: color.opacity(0.3),
            animation: Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
        ) {
            Image(systemName: systemName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
    }
}
