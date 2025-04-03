import SwiftUI
import FirebaseFirestore

@available(iOS 17.0, *)
struct PlaydateDetailView: View {
    @StateObject private var viewModel = PlaydateDetailViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var friendManagementViewModel: FriendManagementViewModel // Ensure injected
    @EnvironmentObject private var invitationManager: PlaydateInvitationViewModel // Inject Invitation Manager
    @State private var commentText = ""
    @State private var showingInviteSheet = false
    @State private var pendingInvitationForThisPlaydate: PlaydateInvitation? = nil // State for the relevant invitation
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage? = nil // For single image picker
    @State private var showingTagFriendsSheet = false

    let playdateId: String // Changed from playdate: Playdate

    // Computed property depends on viewModel.playdate now
    private var isPastPlaydate: Bool {
        guard let endDate = viewModel.playdate?.endDate else { return false }
        return endDate < Date()
    }

    // Computed property to break down the main VStack content
    @ViewBuilder
    private var detailContent: some View {
        // Ensure playdate is loaded before showing content that depends on it
        if let playdate = viewModel.playdate {
            PlaydateHeaderView(playdate: playdate, host: viewModel.host)

            // Invitation Response Buttons - Show only if a pending invitation exists
            if let invitation = pendingInvitationForThisPlaydate {
                InvitationResponseButtons(invitation: invitation, invitationManager: invitationManager)
            }

            AttendeesSection(
                attendees: viewModel.attendees,
                isLoading: viewModel.isLoadingAttendees,
                onTapInvite: { showingInviteSheet = true }
            )

            if let currentUserId = authViewModel.currentUser?.id {
                // Pass the loaded playdate to the button view
                JoinLeaveButton(
                    playdate: playdate,
                    currentUserId: currentUserId,
                    viewModel: viewModel
                )
            }

            CommentsSection(
                comments: viewModel.comments,
                commentText: $commentText,
                isLoadingComments: viewModel.isLoadingComments,
                onSubmitComment: {
                    guard let userId = authViewModel.currentUser?.id,
                          !commentText.isEmpty else { return }
                    // Use playdateId directly
                    viewModel.addComment(playdateId: playdateId, userId: userId, text: commentText) { success in
                        if success { commentText = "" }
                    }
                }
            )
            .disabled(authViewModel.currentUser?.id == nil) // Simplified condition

            // Extracted Past Playdate Actions
            if isPastPlaydate {
                PastPlaydateActionsView(
                    viewModel: viewModel,
                    showingImagePicker: $showingImagePicker,
                    showingTagFriendsSheet: $showingTagFriendsSheet
                )
            }
        } else {
            // Show loading indicator while playdate details are fetched
            ProgressView("Loading Playdate...")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                detailContent // Use the computed property
            } // End Main VStack
            .padding()
        } // End ScrollView
        .navigationTitle("Playdate Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Invite") { showingInviteSheet = true }
                    .disabled(viewModel.playdate == nil) // Disable if playdate not loaded
            }
        }
        .onAppear {
            if let currentUserId = authViewModel.currentUser?.id {
                // Pass playdateId to the load function
                viewModel.loadPlaydateData(playdateId: playdateId, currentUserId: currentUserId)
                // Find the relevant invitation once the view appears
                findRelevantInvitation()
            }
        }
        // Add listener for changes in invitations (e.g., if accepted/declined elsewhere)
        .onReceive(invitationManager.$pendingInvitations) { _ in
            findRelevantInvitation()
        }
        // Add listener for when the playdate data is loaded by the viewModel
        .onReceive(viewModel.$playdate) { loadedPlaydate in
             if loadedPlaydate != nil {
                 findRelevantInvitation() // Check again once playdate data is confirmed
             }
         }
        .sheet(isPresented: $showingInviteSheet) {
            // Ensure playdate is loaded before showing invite sheet
            if let playdate = viewModel.playdate {
                InviteFriendsToPlaydateView(
                    playdate: playdate,
                    friends: friendManagementViewModel.friends, // Pass friends list
                    isLoading: friendManagementViewModel.isLoading // Pass loading state
                )
                .environmentObject(friendManagementViewModel) // Pass it down
            } else {
                 Text("Loading playdate details...") // Or some placeholder
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) {
             guard let imageToUpload = selectedImage else { return }
             Task {
                 // Use playdateId directly
                 await viewModel.uploadAndAddPhotos(playdateId: playdateId, images: [imageToUpload])
                 selectedImage = nil
             }
        }
        .sheet(isPresented: $showingTagFriendsSheet) {
            // Ensure playdate is loaded
            if let playdate = viewModel.playdate {
                TagFriendsView(playdate: playdate) { selectedFriendIDs in
                    // Use playdateId directly
                    viewModel.updateTaggedFriends(playdateId: playdateId, friendIds: selectedFriendIDs) { success, error in
                        if !success { print("Error updating tagged friends: \(error ?? "Unknown error")") }
                    }
                }
                .environmentObject(friendManagementViewModel)
            } else {
                 Text("Loading playdate details...") // Or some placeholder
            }
        }
    } // End body

    // Helper function to find the relevant pending invitation
    private func findRelevantInvitation() {
        guard let currentUserID = authViewModel.currentUser?.id else {
            pendingInvitationForThisPlaydate = nil
            return
        }
        // Find invitation matching the playdateId and current user as recipient
        pendingInvitationForThisPlaydate = invitationManager.pendingInvitations.first { inv in
            // Ensure optional ID is checked safely
            guard inv.id != nil else { return false } // Check if ID is nil before using it
            return inv.playdateID == self.playdateId && inv.recipientID == currentUserID && inv.status == .pending
        }
        // Add detailed logging
        if let foundInv = pendingInvitationForThisPlaydate {
            // Safely unwrap ID for logging
            print("🔍 Checked for pending invitation for playdate \(playdateId). Found: YES. ID = \(foundInv.id ?? "NIL")")
        } else {
            print("🔍 Checked for pending invitation for playdate \(playdateId). Found: NO.")
        }
    }

} // End struct PlaydateDetailView


// MARK: - Invitation Response Buttons Subview
struct InvitationResponseButtons: View {
    let invitation: PlaydateInvitation
    @ObservedObject var invitationManager: PlaydateInvitationViewModel // Use ObservedObject

    var body: some View {
        // Log the ID when the button appears
        let _ = print("➡️ InvitationResponseButtons appearing for invitation ID: \(invitation.id ?? "nil")")

        HStack(spacing: 15) {
            Button {
                Task {
                    // Log ID just before calling the function
                    print("▶️ Attempting to ACCEPT invitation with ID: \(invitation.id ?? "nil")") // Log optional ID
                    // Ensure ID is valid before calling
                    guard invitation.id != nil else {
                        print("❌ ERROR: Invitation ID is nil in ACCEPT button action.")
                        return
                    }
                    do {
                        // Pass the full invitation object
                        try await invitationManager.respondToInvitation(invitation: invitation, accept: true)
                        // Optionally add haptic feedback or confirmation message
                    } catch {
                        // Log the specific error from the ViewModel
                        print("❌ Error accepting invitation (ID: \(invitation.id ?? "nil")): \(error.localizedDescription)")
                        // Optionally show an alert to the user
                    }
                }
            } label: {
                Label("Accept", systemImage: "checkmark.circle.fill")
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button {
                 Task {
                     // Log ID just before calling the function
                    print("▶️ Attempting to DECLINE invitation with ID: \(invitation.id ?? "nil")") // Log optional ID
                    // Ensure ID is valid before calling
                    guard invitation.id != nil else {
                        print("❌ ERROR: Invitation ID is nil in DECLINE button action.")
                        return
                    }
                     do {
                         // Pass the full invitation object
                         try await invitationManager.respondToInvitation(invitation: invitation, accept: false)
                         // Optionally add haptic feedback or confirmation message
                     } catch {
                         // Log the specific error from the ViewModel
                         print("❌ Error declining invitation (ID: \(invitation.id ?? "nil")): \(error.localizedDescription)")
                         // Optionally show an alert to the user
                     }
                 }
             } label: {
                 Label("Decline", systemImage: "xmark.circle.fill")
                     .padding(.vertical, 8)
                     .frame(maxWidth: .infinity)
             }
             .buttonStyle(.borderedProminent)
             .tint(.red)
        }
        .padding(.vertical) // Add some vertical padding around the buttons
    }
}


// MARK: - Extracted Subview for Past Playdate Actions
@available(iOS 17.0, *)
struct PastPlaydateActionsView: View {
    @ObservedObject var viewModel: PlaydateDetailViewModel // Use ObservedObject since it's passed down
    @Binding var showingImagePicker: Bool
    @Binding var showingTagFriendsSheet: Bool

    var body: some View {
        Divider()
        VStack(alignment: .leading, spacing: 15) {
            Text("Memories").font(.title2).fontWeight(.semibold)

            // Photos Section
            if !viewModel.photoURLs.isEmpty {
                 // TODO: Implement a proper photo gallery view
                 Text("Photos (\(viewModel.photoURLs.count))")
            } else if viewModel.isLoadingPhotos {
                 ProgressView() // Show loading indicator for photos
            } else {
                Text("No photos added yet.").font(.caption).foregroundColor(.gray)
            }
            Button { showingImagePicker = true } label: { Label("Add Photos", systemImage: "photo.on.rectangle.angled") }
                .buttonStyle(.bordered).tint(ColorTheme.primary)

            // Tagged Friends Section
            if !viewModel.taggedFriends.isEmpty {
                 // TODO: Implement tagged friends display
                 Text("Tagged Friends (\(viewModel.taggedFriends.count))")
            } else if viewModel.isLoadingTaggedFriends {
                 ProgressView() // Show loading indicator for tags
            } else {
                 Text("No friends tagged yet.").font(.caption).foregroundColor(.gray)
            }
            Button { showingTagFriendsSheet = true } label: { Label("Tag Friends", systemImage: "tag") }
                .buttonStyle(.bordered).tint(ColorTheme.accent)
        }
    }
}


// MARK: - Join/Leave Button Subview
@available(iOS 17.0, *)
struct JoinLeaveButton: View {
    // Use viewModel.playdate which is optional
    let playdate: Playdate?
    let currentUserId: String
    let viewModel: PlaydateDetailViewModel

    private var isHost: Bool { playdate?.hostID == currentUserId }
    private var isAttending: Bool { playdate?.attendeeIDs.contains(currentUserId) ?? false }

    var body: some View {
        // Only show button if playdate is loaded
        if let loadedPlaydate = playdate {
            if isHost {
                Text("You're hosting this playdate").font(.subheadline).foregroundColor(.gray).padding(.vertical, 8)
            } else if isAttending {
                Button(action: {
                    // Use playdateId directly from viewModel or view
                    viewModel.leavePlaydate(playdateId: loadedPlaydate.id!, userId: currentUserId) { _, _ in }
                }) {
                    Text("Leave Playdate").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.red).cornerRadius(10)
                }
            } else {
                Button(action: {
                    // Use playdateId directly from viewModel or view
                    viewModel.joinPlaydate(playdateId: loadedPlaydate.id!, userId: currentUserId) { _, _ in }
                }) {
                    Text("Join Playdate").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.blue).cornerRadius(10)
                }
            }
        } else {
             EmptyView() // Don't show button if playdate isn't loaded
        }
    }
}


#Preview {
    // Need to provide FriendManagementViewModel and PlaydateInvitationViewModel for preview
    let mockAuth = AuthViewModel()
    mockAuth.user = User(id: "previewUser", name: "Preview User", email: "preview@test.com")
    let mockFriendVM = FriendManagementViewModel(authViewModel: mockAuth)
    let mockInvitationVM = PlaydateInvitationViewModel() // Needs mock data setup if needed

    // Preview now uses playdateId
    let previewPlaydateId = "previewPD123"

    // Explicitly return the view
    return NavigationView {
        PlaydateDetailView(playdateId: previewPlaydateId) // Pass ID
            .environmentObject(mockAuth)
            .environmentObject(mockFriendVM) // Provide Friend VM
            .environmentObject(mockInvitationVM) // Provide Invitation VM
            // Mock data loading in viewModel for preview if needed
            .onAppear {
                 // Simulate loading in preview if necessary
                 // let detailVM = PlaydateDetailViewModel()
                 // detailVM.playdate = Playdate(...) // Assign mock playdate
                 // Use detailVM in the preview if state needs setup
            }
    }
}
