import SwiftUI
import Foundation

struct EnhancedPlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
        HStack(spacing: 16) { // Use HStack for side-by-side layout
            // Date Box (similar style but adapted for white background)
            VStack(spacing: 2) { // Reduced spacing
                Text(formatDayOfWeek(playdate.startDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primary) // Use primary color
                
                Text(formatDayOfMonth(playdate.startDate))
                    .font(.title) // Slightly larger day
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.darkPurple) // Darker text
                
                Text(formatMonth(playdate.startDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primary) // Use primary color
            }
            .frame(width: 60) // Keep fixed width
            .padding(.vertical, 12) // Adjusted padding
            .background(ColorTheme.primary.opacity(0.1)) // Light background tint
            .cornerRadius(12) // Rounded corners for the date box
            
            // Playdate details
            VStack(alignment: .leading, spacing: 6) { // Reduced spacing
                Text(playdate.title)
                    .font(.headline)
                    .fontWeight(.semibold) // Slightly bolder
                    .foregroundColor(ColorTheme.darkPurple)
                    .lineLimit(2) // Allow wrapping up to 2 lines
                
                HStack(spacing: 4) { // Reduced spacing
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption) // Smaller icon
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text(playdate.location?.name ?? playdate.address ?? "Location TBD")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1) // Prevent wrapping
                }
                
                HStack(spacing: 4) { // Reduced spacing
                    Image(systemName: "clock")
                        .font(.caption) // Smaller icon
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text(formatTime(playdate.startDate))
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                // Attendees
                HStack(spacing: 4) { // Reduced spacing
                    Image(systemName: "person.2")
                        .font(.caption) // Smaller icon
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text("\(playdate.attendeeIDs.count) attending")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
            }
            
            Spacer() // Pushes content to the left
        }
        .padding(16) // Overall padding for the card
        .background(Color.white) // White background
        .cornerRadius(16) // Rounded corners
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2) // Subtle shadow
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct EnhancedPlaydateCard_Previews: PreviewProvider {
    static var previews: some View {
        // Replace Playdate.mock with a basic instance for preview
        EnhancedPlaydateCard(playdate: Playdate(hostID: "previewHost", title: "Preview Playdate", description: "Preview Description", startDate: Date(), endDate: Date().addingTimeInterval(3600), attendeeIDs: ["1", "2"]))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
