import SwiftUI
import Foundation

struct EnhancedPlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
        GradientCard.primary {
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and time
                HStack {
                    // Date box
                    VStack(spacing: 0) {
                        Text(formatDayOfWeek(playdate.startDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(formatDayOfMonth(playdate.startDate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(formatMonth(playdate.startDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Time
                    Text(formatTime(playdate.startDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                Spacer()
                
                // Playdate details
                VStack(alignment: .leading, spacing: 8) {
                    Text(playdate.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(playdate.location?.name ?? playdate.address ?? "Location TBD")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    
                    // Attendees
                    HStack {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(playdate.attendeeIDs.count) attending")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: 220, height: 180)
        }
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
        EnhancedPlaydateCard(playdate: Playdate.mock)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
