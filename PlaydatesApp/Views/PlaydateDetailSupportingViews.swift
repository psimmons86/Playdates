import SwiftUI
import MapKit

// MARK: - Supporting Views for PlaydateDetailView

// Section showing attendees with invite button
struct AttendeesSection: View {
    let attendees: [User]
    let isLoading: Bool
    let onTapInvite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with invite button
            HStack {
                Text("Attendees")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                Button(action: onTapInvite) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.caption)
                        
                        Text("Invite")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            
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
                // Attendee list
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(attendees) { attendee in
                            VStack {
                                ProfileImageView(imageURL: attendee.profileImageURL, size: 60)
                                
                                Text(attendee.name.split(separator: " ").first ?? "")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.darkPurple)
                                    .lineLimit(1)
                            }
                            .frame(width: 70)
                        }
                    }
                    .padding(.vertical, 8)
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

// Section showing comments with input field
struct CommentsSection: View {
    let comments: [CommentWithUser]
    @Binding var commentText: String
    let isLoadingComments: Bool
    let onSubmitComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if comments.isEmpty {
                Text("No comments yet")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .padding(.vertical, 8)
            } else {
                // Comments list
                VStack(spacing: 16) {
                    ForEach(comments, id: \.comment.id) { commentWithUser in
                        CommentRow(commentWithUser: commentWithUser)
                    }
                }
            }
            
            // Comment input
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $commentText)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: onSubmitComment) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(commentText.isEmpty ? ColorTheme.lightText : ColorTheme.primary)
                }
                .disabled(commentText.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Row for a single comment
struct CommentRow: View {
    let commentWithUser: CommentWithUser
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
            if commentWithUser.comment.isSystem ?? false {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(ColorTheme.lightText)
                    .clipShape(Circle())
            } else {
                ProfileImageView(imageURL: commentWithUser.user.profileImageURL, size: 36)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // User name and time
                HStack {
                    Text(commentWithUser.user.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Spacer()
                    
                    Text(timeAgo(date: commentWithUser.comment.createdAt))
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                // Comment text
                Text(commentWithUser.comment.text)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// View for displaying a user's profile image
struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat
    
    var body: some View {
        if let imageURL = imageURL, !imageURL.isEmpty {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure:
                    defaultImage
                @unknown default:
                    defaultImage
                }
            }
        } else {
            defaultImage
        }
    }
    
    private var defaultImage: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.5))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(ColorTheme.primary.opacity(0.7))
            .clipShape(Circle())
    }
}

// View for displaying a map
struct MapView: View {
    let location: Location
    @State private var region: MKCoordinateRegion
    
    init(location: Location) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map
            Map(coordinateRegion: $region, annotationItems: [location]) { location in
                MapMarker(coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ), tint: ColorTheme.primary)
            }
            .edgesIgnoringSafeArea(.top)
            
            // Location details
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                
                // Open in Maps button
                Button(action: {
                    openInMaps()
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open in Maps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.white)
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// View for inviting friends to a playdate
struct InviteFriendsToPlaydateView: View {
    let playdate: Playdate
    let friends: [User]
    let isLoading: Bool
    let onInvite: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ColorTheme.lightText)
                        
                        TextField("Search friends", text: $searchText)
                            .foregroundColor(ColorTheme.darkPurple)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if friends.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text("No Friends Yet")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            Text("Add friends to invite them to your playdates")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        Spacer()
                    } else {
                        // Friends list
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredFriends) { friend in
                                    FriendInviteRow(
                                        friend: friend,
                                        onInvite: {
                                            if let friendId = friend.id {
                                                onInvite(friendId)
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

// Row for a friend in the invite list
struct FriendInviteRow: View {
    let friend: User
    let onInvite: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            ProfileImageView(imageURL: friend.profileImageURL, size: 50)
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                if let bio = friend.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Invite button
            Button(action: onInvite) {
                Text("Invite")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorTheme.primary)
                    .cornerRadius(16)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Helper Functions

// Check if a playdate is completed
func isPlaydateCompleted(_ playdate: Playdate) -> Bool {
    return playdate.endDate < Date()
}

// Check if a playdate is in progress
func isPlaydateInProgress(_ playdate: Playdate) -> Bool {
    let now = Date()
    return playdate.startDate <= now && playdate.endDate > now
}

// MARK: - Supporting Models

// Comment model
struct Comment: Identifiable, Codable {
    let id: String
    let userID: String
    let text: String
    let createdAt: Date
    var isSystem: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case text
        case createdAt
        case isSystem
    }
}

// Playdate status enum
enum PlaydateStatus {
    case planned
    case inProgress
    case completed
    case cancelled
}
