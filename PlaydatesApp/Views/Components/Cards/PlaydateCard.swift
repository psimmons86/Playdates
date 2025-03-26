import SwiftUI
import Foundation

// MARK: - Playdate Card
struct PlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
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
                VStack(spacing: 0) {
                    Text(dayOfMonth)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(monthAbbreviation)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(ColorTheme.highlight)
                .cornerRadius(8)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
            return Image(systemName: "leaf.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.02, green: 0.84, blue: 0.63))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.02, green: 0.84, blue: 0.63).opacity(0.2))
                .clipShape(Circle())
        case .museum:
            return Image(systemName: "building.columns.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 40, height: 40)
                .background(ColorTheme.accent.opacity(0.2))
                .clipShape(Circle())
        case .playground:
            return Image(systemName: "figure.play")
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.highlight)
                .frame(width: 40, height: 40)
                .background(ColorTheme.highlight.opacity(0.2))
                .clipShape(Circle())
        case .library:
            return Image(systemName: "book.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 40, height: 40)
                .background(ColorTheme.accent.opacity(0.2))
                .clipShape(Circle())
        case .swimmingPool:
            return Image(systemName: "figure.pool.swim")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.07, green: 0.54, blue: 0.7))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.07, green: 0.54, blue: 0.7).opacity(0.2))
                .clipShape(Circle())
        case .sportingEvent:
            return Image(systemName: "sportscourt.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.94, green: 0.28, blue: 0.44))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.94, green: 0.28, blue: 0.44).opacity(0.2))
                .clipShape(Circle())
        case .zoo:
            return Image(systemName: "pawprint.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.highlight)
                .frame(width: 40, height: 40)
                .background(ColorTheme.highlight.opacity(0.2))
                .clipShape(Circle())
        case .aquarium:
            return Image(systemName: "drop.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.07, green: 0.54, blue: 0.7))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.07, green: 0.54, blue: 0.7).opacity(0.2))
                .clipShape(Circle())
        case .movieTheater:
            return Image(systemName: "film.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.46, green: 0.47, blue: 0.93))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.46, green: 0.47, blue: 0.93).opacity(0.2))
                .clipShape(Circle())
        case .themePark:
            return Image(systemName: "ferriswheel")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.94, green: 0.28, blue: 0.44))
                .frame(width: 40, height: 40)
                .background(Color(red: 0.94, green: 0.28, blue: 0.44).opacity(0.2))
                .clipShape(Circle())
        default:
            return Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorTheme.primary)
                .frame(width: 40, height: 40)
                .background(ColorTheme.primary.opacity(0.2))
                .clipShape(Circle())
        }
    }
}
