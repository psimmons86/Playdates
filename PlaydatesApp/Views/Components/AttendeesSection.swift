import SwiftUI

/// Section showing playdate attendees
struct AttendeesSection: View {
    let attendees: [User]
    let isLoading: Bool
    let onTapInvite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and invite button
            HStack {
                Text("Attendees")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                Button(action: onTapInvite) {
                    Label("Invite", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primary)
                }
            }
            
            // Attendees list or loading state
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if attendees.isEmpty {
                Text("No attendees yet")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .padding(.vertical, 8)
            } else {
                // Attendees list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(attendees, id: \.id) { attendee in
                            AttendeeItem(attendee: attendee)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

/// Individual attendee item
struct AttendeeItem: View {
    let attendee: User
    
    var body: some View {
        VStack {
            // Profile image
            ProfileImageView(imageURL: attendee.profileImageURL, size: 60)
            
            // Name
            Text(attendee.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.darkPurple)
                .lineLimit(1)
                .frame(width: 70)
                .truncationMode(.tail)
        }
    }
}
