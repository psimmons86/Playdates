import SwiftUI
import Foundation

// MARK: - ActivityType Helper Functions

func activityTypeColor(for activityType: ActivityType) -> Color {
    switch activityType {
    case .park:
        return ColorTheme.secondary
    case .themePark:
        return ColorTheme.accent
    case .beach:
        return Color.blue
    case .museum:
        return Color.purple
    case .summerCamp:
        return ColorTheme.primary
    default:
        return ColorTheme.primary
    }
}

func activityTypeFromString(_ typeString: String?) -> ActivityType {
    guard let typeStr = typeString,
          let type = ActivityType(rawValue: typeStr) else {
        return .other
    }
    return type
}

// Helper function to check if a playdate is in progress
func isPlaydateInProgress(_ playdate: Playdate) -> Bool {
    let now = Date()
    return playdate.startDate <= now && playdate.endDate >= now
}

// Helper function to check if a playdate is completed
func isPlaydateCompleted(_ playdate: Playdate) -> Bool {
    let now = Date()
    return playdate.endDate < now
}

// Helper function to check if a playdate is planned
func isPlaydatePlanned(_ playdate: Playdate) -> Bool {
    let now = Date()
    return playdate.startDate > now
}

// MARK: - Playdate Cards

struct PlaydateCard: View {
    let playdate: Playdate
    var isPast: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ColorTheme.primary)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text)
                
                Spacer()
                
                if isPast {
                    Text(L10n.Playdate.completed.localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.secondary)
                        .cornerRadius(8)
                } else if isPlaydateInProgress(playdate) {
                    Text(L10n.Playdate.inProgress.localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.accent)
                        .cornerRadius(8)
                }
            }
            
            // Title
            Text(playdate.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
                .lineLimit(1)
            
            // Location
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(ColorTheme.secondary)
                
                Text(playdate.location?.name ?? L10n.Playdate.unknownLocation.localized)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
                    .lineLimit(1)
            }
            
            // Participants
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(ColorTheme.secondary)
                
                Text(String.localizedStringWithFormat(L10n.Playdate.participants.localized, playdate.attendeeIDs.count))
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
            }
            
            Spacer()
            
            // Activity type badge - FIX: Convert String to ActivityType
            if let activityTypeStr = playdate.activityType,
               let activityType = ActivityType(rawValue: activityTypeStr) {
                HStack {
                    Image(systemName: activityType.icon)
                        .foregroundColor(.white)
                    
                    Text(activityType.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(activityTypeColor(for: activityType))
                .cornerRadius(12)
            } else {
                // Fallback if activity type is not available
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                    
                    Text(L10n.Playdate.activity.localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ColorTheme.primary)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: playdate.startDate)
    }
    
    // FIX: Moved icon logic to a function that handles String? to ActivityType conversion
    private func activityTypeIcon(for activityTypeStr: String?) -> String {
        guard let typeStr = activityTypeStr,
              let type = ActivityType(rawValue: typeStr) else {
            return "questionmark.circle"
        }
        return type.icon
    }
}

struct PlaydateInvitationCard: View {
    let playdate: Playdate
    @EnvironmentObject private var playdateViewModel: PlaydateViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with invitation badge
            HStack {
                Text(playdate.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.text)
                    .lineLimit(1)
                
                Spacer()
                
                Text(L10n.Playdate.invitation.localized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.accent)
                    .cornerRadius(8)
            }
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ColorTheme.primary)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text)
            }
            
            // Location
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(ColorTheme.secondary)
                
                Text(playdate.location?.name ?? L10n.Playdate.unknownLocation.localized)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button(action: {
                    acceptInvitation()
                }) {
                    Text(L10n.Playdate.accept.localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(ColorTheme.secondary)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    declineInvitation()
                }) {
                    Text(L10n.Playdate.decline.localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: playdate.startDate)
    }
    
    private func acceptInvitation() {
        guard let userID = authViewModel.user?.id, let playdateID = playdate.id else { return }
        
        // Use joinPlaydate instead of acceptInvitation
        playdateViewModel.joinPlaydate(playdateID: playdateID, userID: userID) { result in
            // Handle result if needed
            switch result {
            case .success:
                print("Successfully joined playdate")
            case .failure(let error):
                print("Failed to join playdate: \(error.localizedDescription)")
            }
        }
    }
    
    private func declineInvitation() {
        guard let userID = authViewModel.user?.id, let playdateID = playdate.id else { return }
        
        // Since there's no direct 'declineInvitation' method,
        // we could either implement that in the ViewModel or handle it differently
        // For now, we'll just print a message
        print("Declined invitation for playdate \(playdateID)")
        
        // If you had a method like this, you could use it:
        /*
        playdateViewModel.declineInvitation(playdateID: playdateID, userID: userID) { result in
            switch result {
            case .success:
                print("Successfully declined playdate invitation")
            case .failure(let error):
                print("Failed to decline playdate invitation: \(error.localizedDescription)")
            }
        }
        */
    }
}

// MARK: - Activity Cards

struct ActivityCard: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Activity image or placeholder
            ZStack {
                if let firstPhotoURL = activity.photos?.first, !firstPhotoURL.isEmpty {
                    AsyncImage(url: URL(string: firstPhotoURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    Image(systemName: activity.type.icon)
                                        .font(.system(size: 30))
                                        .foregroundColor(Color.gray.opacity(0.5))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                        }
                    }
                    .frame(height: 120)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: activity.type.icon)
                                .font(.system(size: 30))
                                .foregroundColor(Color.gray.opacity(0.5))
                        )
                }
                
                // Activity type badge
                VStack {
                    HStack {
                        Spacer()
                        
                        Text(activity.type.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(8)
                    }
                    
                    Spacer()
                }
            }
            .cornerRadius(12)
            
            // Activity name
            Text(activity.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
                .lineLimit(1)
            
            // Rating if available
            if let rating = activity.rating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= Int(rating) ? ColorTheme.accent : Color.gray.opacity(0.3))
                    }
                    
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .foregroundColor(ColorTheme.text.opacity(0.7))
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FeaturedActivityCard: View {
    let activity: Activity
    
    var body: some View {
        ZStack {
            // Background image or placeholder
            if let firstPhotoURL = activity.photos?.first, !firstPhotoURL.isEmpty {
                AsyncImage(url: URL(string: firstPhotoURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: activity.type.icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(Color.gray.opacity(0.5))
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                    }
                }
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: activity.type.icon)
                            .font(.system(size: 30))
                            .foregroundColor(Color.gray.opacity(0.5))
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                
                // Featured badge
                HStack {
                    Text(L10n.Activity.featured.localized)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.accent)
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                // Activity name
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Activity type
                Text(activity.type.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Common UI Components

struct SectionHeader: View {
    let title: String
    let actionText: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Spacer()
            
            Button(action: action) {
                Text(actionText)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primary)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    var title: String = L10n.EmptyState.title
    var message: String = L10n.EmptyState.message
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.primary.opacity(0.7))
            
            Text(title.localized)
                .font(.headline)
                .foregroundColor(ColorTheme.text)
            
            Text(message.localized)
                .font(.subheadline)
                .foregroundColor(ColorTheme.text.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // User avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(comment.userID.prefix(1).uppercased())
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.Common.user.localized)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.text)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                }
                
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: comment.createdAt)
    }
}

// MARK: - Playdate Status Helpers

extension Playdate {
    var currentStatus: PlaydateStatus {
        if isPlaydateCompleted(self) {
            return .completed
        } else if isPlaydateInProgress(self) {
            return .inProgress
        } else {
            return .planned
        }
    }
}
