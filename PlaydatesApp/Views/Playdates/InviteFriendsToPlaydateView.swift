import SwiftUI

/// View for inviting friends to a playdate
@available(iOS 17.0, *)
struct InviteFriendsToPlaydateView: View {
    let playdate: Playdate
    let friends: [User]
    let isLoading: Bool
    let onInvite: (String) -> Void
    
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
                                    if let friendId = friend.id {
                                        onInvite(friendId)
                                        // Show a success message or update UI
                                        // For demo purposes, we'll just dismiss
                                        presentationMode.wrappedValue.dismiss()
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
            })
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
            Button(action: onInvite) {
                Text("Invite")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorTheme.primary)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
