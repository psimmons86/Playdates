import SwiftUI
import FirebaseFirestore

struct ActivityDetailView: View {
    let activity: AppActivity
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var relatedUser: User?
    @State private var relatedPlaydate: Playdate?
    @State private var isLoadingRelatedContent = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity Header
                HStack(alignment: .top, spacing: 15) {
                    // User Avatar
                    if let imageURL = activity.userProfileImageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            case .failure:
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text(String(activity.userName.prefix(1)))
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24, weight: .medium))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 60, height: 60)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(activity.userName.prefix(1)))
                                    .foregroundColor(.gray)
                                    .font(.system(size: 24, weight: .medium))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // User Name
                        Text(activity.userName)
                            .font(.headline)
                        
                        // Activity Type
                        Text(activityTypeString(activity.type))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Timestamp
                        Text(formatDate(activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Activity Content
                VStack(alignment: .leading, spacing: 15) {
                    // Title
                    if !activity.title.isEmpty {
                        Text(activity.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    // Description
                    if !activity.description.isEmpty {
                        Text(activity.description)
                            .font(.body)
                    }
                    
                    // Content Image if available
                    if let imageURL = activity.contentImageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .overlay(
                                        ProgressView()
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 300)
                                    .cornerRadius(8)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // Related Content Section
                if isLoadingRelatedContent {
                    HStack {
                        Spacer()
                        ProgressView("Loading related content...")
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                } else {
                    // Related User Profile
                    if let user = relatedUser, user.id != authViewModel.user?.id {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("User Profile")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            HStack(spacing: 15) {
                                // User Avatar
                                if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                                    AsyncImage(url: URL(string: profileImageURL)) { phase in
                                        switch phase {
                                        case .empty:
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        case .failure:
                                            Circle()
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                                .overlay(
                                                    Text(String(user.name.prefix(1)))
                                                        .foregroundColor(.gray)
                                                        .font(.system(size: 20, weight: .medium))
                                                )
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(String(user.name.prefix(1)))
                                                .foregroundColor(.gray)
                                                .font(.system(size: 20, weight: .medium))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                    
                                    if let location = user.location, !location.isEmpty {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                NavigationLink(destination: Text("User Profile")) {
                                    Text("View Profile")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(ColorTheme.funBlue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    // Related Playdate
                    if let playdate = relatedPlaydate {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Related Playdate")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(playdate.title)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                if let location = playdate.location?.name, !location.isEmpty {
                                    HStack {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(ColorTheme.funPurple)
                                        Text(location)
                                            .font(.subheadline)
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(ColorTheme.funBlue)
                                    Text(formatDate(playdate.startTime))
                                        .font(.subheadline)
                                }
                                
                                if let description = playdate.description, !description.isEmpty {
                                    Text(description)
                                        .font(.body)
                                        .padding(.top, 5)
                                        .lineLimit(3)
                                }
                                
                                NavigationLink(destination: PlaydateDetailView(playdate: playdate)) {
                                    Text("View Playdate")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(ColorTheme.funBlue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 5)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                
                // Error Message
                if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            loadRelatedContent()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadRelatedContent() {
        isLoadingRelatedContent = true
        errorMessage = nil
        
        // Create a dispatch group to wait for all fetches
        let group = DispatchGroup()
        
        // Fetch related user if it's not the current user
        if activity.userID != authViewModel.user?.id {
            group.enter()
            fetchUser(userId: activity.userID) {
                group.leave()
            }
        }
        
        // Fetch related playdate if applicable
        if activity.type == .newPlaydate || activity.type == .playdateUpdate || activity.type == .joinedPlaydate,
           let playdateId = activity.relatedItemID {
            group.enter()
            fetchPlaydate(playdateId: playdateId) {
                group.leave()
            }
        }
        
        // When all fetches complete, update UI
        group.notify(queue: .main) {
            self.isLoadingRelatedContent = false
        }
    }
    
    private func fetchUser(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to load user: \(error.localizedDescription)"
                completion()
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                self.errorMessage = "User not found"
                completion()
                return
            }
            
            do {
                var user = try snapshot.data(as: User.self)
                user.id = snapshot.documentID
                self.relatedUser = user
            } catch {
                self.errorMessage = "Failed to decode user data"
            }
            
            completion()
        }
    }
    
    private func fetchPlaydate(playdateId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("playdates").document(playdateId).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "Failed to load playdate: \(error.localizedDescription)"
                completion()
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                self.errorMessage = "Playdate not found"
                completion()
                return
            }
            
            do {
                var playdate = try snapshot.data(as: Playdate.self)
                playdate.id = snapshot.documentID
                self.relatedPlaydate = playdate
            } catch {
                self.errorMessage = "Failed to decode playdate data"
            }
            
            completion()
        }
    }
    
    private func activityTypeString(_ type: AppActivity.ActivityType) -> String {
        switch type {
        case .newPlaydate:
            return "Created a playdate"
        case .playdateUpdate:
            return "Updated a playdate"
        case .newFriend:
            return "Made a new friend"
        case .newComment:
            return "Posted a comment"
        case .newGroupPost:
            return "Posted in a group"
        case .newCommunityEvent:
            return "Added a community event"
        case .newSharedResource:
            return "Shared a resource"
        case .userJoined:
            return "Joined Playdates"
        case .childAdded:
            return "Added a child"
        case .joinedPlaydate:
            return "Joined a playdate"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivity = AppActivity(
            id: "activity1",
            type: .newPlaydate,
            title: "Park Playdate",
            description: "Let's meet at Central Park for a fun afternoon!",
            userID: "user1",
            userName: "Jane Smith",
            userProfileImageURL: nil,
            relatedItemID: "playdate1",
            contentImageURL: nil,
            timestamp: Date()
        )
        
        let authVM = AuthViewModel()
        
        return NavigationView {
            ActivityDetailView(activity: mockActivity)
                .environmentObject(authVM)
        }
    }
}
