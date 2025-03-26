import SwiftUI
import FirebaseFirestore

@available(iOS 17.0, *)
struct PlaydateDetailView: View {
    @StateObject private var viewModel = PlaydateDetailViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var commentText = ""
    
    let playdate: Playdate
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Playdate header
                PlaydateHeaderView(playdate: playdate, host: viewModel.host)
                
                // Attendees section
                AttendeesSection(
                    attendees: viewModel.attendees,
                    isLoading: viewModel.isLoadingAttendees,
                    onTapInvite: {
                        // Handle invite action
                        if let playdateId = playdate.id, let currentUserId = authViewModel.currentUser?.id {
                            // Show invite UI
                        }
                    }
                )
                
                // Join/Leave button
                if let currentUserId = authViewModel.currentUser?.id {
                    JoinLeaveButton(
                        playdate: playdate,
                        currentUserId: currentUserId,
                        viewModel: viewModel
                    )
                }
                
                // Comments section
                CommentsSection(
                    comments: viewModel.comments,
                    commentText: $commentText,
                    isLoadingComments: viewModel.isLoadingComments,
                    onSubmitComment: {
                        guard let playdateId = playdate.id, 
                              let userId = authViewModel.currentUser?.id,
                              !commentText.isEmpty else {
                            return
                        }
                        
                        viewModel.addComment(
                            playdateId: playdateId,
                            userId: userId,
                            text: commentText
                        ) { success in
                            if success {
                                commentText = ""
                            }
                        }
                    },
                    rowBuilder: { comment in
                        DefaultCommentRow(commentWithUser: comment)
                    }
                )
                .disabled(playdate.id == nil || authViewModel.currentUser?.id == nil)
            }
            .padding()
        }
        .navigationTitle("Playdate Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Using optional chaining instead of conditional binding
                Button("Invite") {
                    // Show invite sheet
                    if let currentUserId = authViewModel.currentUser?.id,
                       let playdateId = playdate.id {
                        // Handle invite action
                    }
                }
                .disabled(authViewModel.currentUser?.id == nil || playdate.id == nil)
            }
        }
        .onAppear {
            if let currentUserId = authViewModel.currentUser?.id {
                viewModel.loadPlaydateData(playdate: playdate, currentUserId: currentUserId)
            }
        }
    }
}

@available(iOS 17.0, *)
struct JoinLeaveButton: View {
    let playdate: Playdate
    let currentUserId: String
    let viewModel: PlaydateDetailViewModel
    
    private var isHost: Bool {
        return playdate.hostID == currentUserId
    }
    
    private var isAttending: Bool {
        return playdate.attendeeIDs.contains(currentUserId)
    }
    
    var body: some View {
        if isHost {
            Text("You're hosting this playdate")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 8)
        } else if isAttending {
            Button(action: {
                guard let playdateId = playdate.id else { return }
                viewModel.leavePlaydate(playdateId: playdateId, userId: currentUserId)
            }) {
                Text("Leave Playdate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .disabled(playdate.id == nil)
        } else {
            Button(action: {
                guard let playdateId = playdate.id else { return }
                viewModel.joinPlaydate(playdateId: playdateId, userId: currentUserId)
            }) {
                Text("Join Playdate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(playdate.id == nil)
        }
    }
}


#Preview {
    if #available(iOS 17.0, *) {
        NavigationView {
            PlaydateDetailView(playdate: Playdate.mock)
                .environmentObject(AuthViewModel())
        }
    } else {
        Text("iOS 17.0+ required")
    }
}
