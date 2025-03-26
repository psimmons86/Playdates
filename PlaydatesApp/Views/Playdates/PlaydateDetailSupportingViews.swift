import SwiftUI

// MARK: - Supporting Views for PlaydateDetailView

@available(iOS 17.0, *)
struct PlaydateHeaderView: View {
    let playdate: Playdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(playdate.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.darkPurple)
            
            // Date and time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(ColorTheme.primary)
                
                Text(formatTimeRange(start: playdate.startDate, end: playdate.endDate))
                    .foregroundColor(ColorTheme.text)
            }
            
            // Location if available
            if let location = playdate.location {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(ColorTheme.primary)
                    
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .fontWeight(.medium)
                        
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
            }
            
            // Status badge - using helper function to determine status
            let status = getPlaydateStatus(playdate)
            HStack {
                Circle()
                    .fill(statusColor(for: status))
                    .frame(width: 8, height: 8)
                
                Text(statusText(for: status))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(for: status))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(statusColor(for: status).opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Helper function to determine playdate status
    private func getPlaydateStatus(_ playdate: Playdate) -> PlaydateStatus {
        let now = Date()
        if now > playdate.endDate {
            return .completed
        } else if now >= playdate.startDate {
            return .inProgress
        } else {
            return .planned
        }
    }
}

@available(iOS 17.0, *)
struct PlaydateDescriptionView: View {
    let playdate: Playdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this playdate")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if hasDescription(playdate.description) {
                Text(playdate.description ?? "")
                    .foregroundColor(ColorTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No description provided")
                    .foregroundColor(ColorTheme.lightText)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

@available(iOS 17.0, *)
struct PlaydateActionButtonsView: View {
    let playdate: Playdate
    let isHost: Bool
    let isAttending: Bool
    let onJoin: () -> Void
    let onLeave: () -> Void
    let onInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if isHost {
                // Host actions
                Button(action: onInvite) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Friends")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else if isAttending {
                // Attendee actions
                Button(action: onLeave) {
                    HStack {
                        Image(systemName: "person.badge.minus")
                        Text("Leave Playdate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                // Non-attendee actions
                Button(action: onJoin) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Playdate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

@available(iOS 17.0, *)
struct PlaydateHostView: View {
    let host: User?
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if isLoading {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 14)
                            .frame(width: 120)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 80)
                    }
                    
                    Spacer()
                }
                .redacted(reason: .placeholder)
            } else if let host = host {
                HStack {
                    ProfileImageView(imageURL: host.profileImageURL, size: 50)
                    
                    VStack(alignment: .leading) {
                        Text(host.name)
                            .fontWeight(.medium)
                        
                        if hasBio(host.bio) {
                            Text(getBio(host.bio))
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                Text("Host information unavailable")
                    .foregroundColor(ColorTheme.lightText)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
