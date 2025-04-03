import SwiftUI

@available(iOS 17.0, *) // Restore availability check
struct TagFriendsView: View { // Opening brace for struct
    let playdate: Playdate
    // Completion handler to pass back selected friend IDs
    let onComplete: ([String]) -> Void

    @EnvironmentObject var friendManagementViewModel: FriendManagementViewModel
    @Environment(\.presentationMode) var presentationMode

    // State to hold the IDs of selected friends
    @State private var selectedFriendIDs: Set<String>
    @State private var searchText = ""

    // Initialize with currently tagged friends already selected
    init(playdate: Playdate, onComplete: @escaping ([String]) -> Void) {
        self.playdate = playdate
        self.onComplete = onComplete
        // Initialize the state with IDs already tagged in the playdate
        _selectedFriendIDs = State(initialValue: Set(playdate.taggedFriendIDs ?? []))
    }

    var body: some View { // Opening brace for body
        // Removed NavigationView for diagnostics
        VStack(spacing: 0) { // Opening brace for VStack
            // Add a temporary title since NavigationView is removed
            Text("Tag Friends")
                .font(.title2).bold()
                .padding(.top)

            // Search bar
            HStack { // Opening brace for HStack
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ColorTheme.lightText)
                TextField("Search friends", text: $searchText)
                    .font(.body)
            } // End HStack
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)

            // Friends list for tagging
            List { // Opening brace for List
                ForEach(filteredFriends) { friend in // Opening brace for ForEach closure
                    HStack { // Opening brace for HStack
                        // Assuming ProfileImageView is compatible
                        ProfileImageView(imageURL: friend.profileImageURL, size: 40)
                        Text(friend.name)
                            .font(.headline)
                        Spacer()
                        // Show checkmark if selected
                        if selectedFriendIDs.contains(friend.id ?? "") { // Opening brace for if
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ColorTheme.primary)
                        } else { // Opening brace for else
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        } // End if/else
                    } // End HStack
                    .contentShape(Rectangle()) // Make entire row tappable
                    .onTapGesture { // Opening brace for onTapGesture closure
                        toggleSelection(friendId: friend.id)
                    } // End onTapGesture closure
                } // End ForEach closure
            } // End List
            .listStyle(PlainListStyle())

            // Add temporary Done/Cancel buttons at the bottom
            HStack {
                 Button("Cancel") {
                     presentationMode.wrappedValue.dismiss()
                 }
                 .buttonStyle(SecondaryButtonStyle()) // Use a different style for visibility
                 Spacer()
                 Button("Done") {
                     onComplete(Array(selectedFriendIDs))
                     presentationMode.wrappedValue.dismiss()
                 }
                 .buttonStyle(PrimaryButtonStyle()) // Use a different style for visibility
            }
            .padding()

        } // End VStack
    } // End body

    // Filter friends based on search text
    private var filteredFriends: [User] { // Opening brace for computed property
        // Use optional chaining in case friendManagementViewModel is nil in some contexts (like previews without it)
        let friends = friendManagementViewModel.friends
        if searchText.isEmpty { // Opening brace for if
            return friends
        } else { // Opening brace for else
            return friends.filter { friend in // Opening brace for filter closure
                friend.name.localizedCaseInsensitiveContains(searchText)
            } // End filter closure
        } // End if/else
    } // End filteredFriends

    // Toggle selection for a friend ID
    private func toggleSelection(friendId: String?) { // Opening brace for function
        guard let friendId = friendId else { return }
        if selectedFriendIDs.contains(friendId) { // Opening brace for if
            selectedFriendIDs.remove(friendId)
        } else { // Opening brace for else
            selectedFriendIDs.insert(friendId)
        } // End if/else
    } // End toggleSelection
} // End struct TagFriendsView (Correct closing brace)

// Preview block completely removed.
