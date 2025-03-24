import SwiftUI
import Foundation

struct PlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(playdate.title)
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
                .lineLimit(1)
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ColorTheme.primary)
                
                Text(formatDate(playdate.startDate))
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
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
