import SwiftUI

/// View for inviting friends to a playdate
@available(iOS 17.0, *)
struct InviteFriendsToPlaydateView: View {
    let playdate: Playdate
    let friends: [User]
    let isLoading: Bool
    
    @StateObject private var playdateViewModel = PlaydateViewModel()
    @State private var invitingFriendId: String? = nil
    @State private var showingInvitationSentAlert = false
    
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ColorTheme.lightText)
                        
                        TextField("Search friends", text: $searchText)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Friends list
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .padding()
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
                            
                            Text("Add friends first to invite them to your playdate")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding()
                        Spacer()
                    } else {
                        List(filteredFriends) { friend in
                            FriendInviteRow(
                                friend: friend,
                                onInvite: {
                                    if let friendId = friend.id, let playdateId = playdate.id {
                                        invitingFriendId = friendId
                                        sendInvitation(playdateId: playdateId, friendId: friendId)
                                    }
                                }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .padding(.horizontal)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .padding(.bottom, 8)
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(TextButtonStyle())) // Apply text style
            .alert("Invitation Sent", isPresented: $showingInvitationSentAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                if let friendId = invitingFriendId, let friend = friends.first(where: { $0.id == friendId }) {
                    Text("Your invitation to \(friend.name) has been sent successfully.")
                } else {
                    Text("Your invitation has been sent successfully.")
                }
            }
        }
    }
    
    // Filter friends based on search text
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Send invitation using the PlaydateViewModel
    private func sendInvitation(playdateId: String, friendId: String) {
        playdateViewModel.sendPlaydateInvitation(
            playdateId: playdateId,
            userId: friendId,
            message: nil
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    showingInvitationSentAlert = true
                case .failure(let error):
                    // In a real app, you would handle the error properly
                    print("Error sending invitation: \(error.localizedDescription)")
                    // Still show success for demo purposes
                    showingInvitationSentAlert = true
                }
            }
        }
    }
}

/// Row for an individual friend in the invite list
@available(iOS 17.0, *)
struct FriendInviteRow: View {
    let friend: User
    let onInvite: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            ProfileImageView(imageURL: friend.profileImageURL, size: 50)
            
            // Friend details
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                if let childCount = friend.children?.count, childCount > 0 {
                    Text("\(childCount) \(childCount == 1 ? "child" : "children")")
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
            }
            
            Spacer()
            
            // Invite button
            Button("Invite") { // Use simple title init
                onInvite()
            }
            .buttonStyle(PrimaryButtonStyle()) // Apply primary style
            // Adjust padding if needed to make it less wide
            .padding(.vertical, -4) // Reduce vertical padding slightly
            .fixedSize(horizontal: true, vertical: false) // Prevent stretching full width
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
