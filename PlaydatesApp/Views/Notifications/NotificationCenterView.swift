import SwiftUI
import FirebaseFirestore // Import Firestore
import FirebaseFirestoreSwift // Import for Codable support

// Add Notification Name definition if it doesn't exist elsewhere
// Ensure this name is unique and consistently used where navigation is handled.
extension Notification.Name {
    static let navigateToPlaydateDetail = Notification.Name("navigateToPlaydateDetail")
    // static let navigateToFriendRequests = Notification.Name("navigateToFriendRequests") // Example
    // static let navigateToChat = Notification.Name("navigateToChat") // Example
}

struct NotificationCenterView: View {
    // ViewModel is passed via EnvironmentObject from MainContainerView
    @EnvironmentObject var viewModel: NotificationViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Needed for user context if refresh logic is added
    private let db = Firestore.firestore() // Add Firestore instance

    var body: some View {
        // Restore the List implementation
        List {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView("Loading notifications...")
                    .listRowSeparator(.hidden)
            } else if viewModel.notifications.isEmpty {
                Text("No notifications yet.")
                    .foregroundColor(.secondary)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .contentShape(Rectangle()) // Make whole row tappable
                        .onTapGesture {
                            handleNotificationTap(notification)
                        }
                        // Add swipe action to mark as read
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                Task {
                                    await viewModel.markAsRead(notificationID: notification.id ?? "")
                                }
                            } label: {
                                Label("Mark as Read", systemImage: "envelope.open.fill")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Notifications") // Uses parent NavigationView's title
        .toolbar { // Restore the toolbar
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Mark All Read") {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                }
                .disabled(viewModel.unreadCount == 0)
            }
        }
        .refreshable {
            // Optional: Add manual refresh logic if needed, though listener should handle updates
            // if let userId = authViewModel.user?.id {
            //     viewModel.setupNotificationListener(for: userId)
            // }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
             Button("OK") { viewModel.error = nil }
        } message: { error in
             Text(error.localizedDescription)
        }
    }

    // Restore the handler function
    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read first
        Task {
            await viewModel.markAsRead(notificationID: notification.id ?? "")
        }

        // TODO: Implement navigation based on notification type and relatedID
        print("Tapped notification: \(notification.type) - Related ID: \(notification.relatedID)")
        switch notification.type {
        case .friendRequest:
            print("Navigate to Friend Request: \(notification.relatedID)")
            // Example: Post notification for MainContainerView to handle
            // NotificationCenter.default.post(name: .navigateToFriendRequests, object: nil)
            break
        case .newChatMessage:
            print("Navigate to Chat: \(notification.relatedID)") // chatID
            // Example: Post notification with chatID or senderID
            // NotificationCenter.default.post(name: .navigateToChat, object: nil, userInfo: ["chatID": notification.relatedID])
             break
        case .playdateInvitation:
            print("Navigate to Playdate Invitation/Detail: Invitation ID = \(notification.relatedID)")
            // Fetch the invitation to get the actual playdateID
            fetchPlaydateIdFromInvitation(invitationId: notification.relatedID) { correctPlaydateId in
                if let correctPlaydateId = correctPlaydateId {
                    print("   Found correct playdateID: \(correctPlaydateId)")
                    // Post notification with the CORRECT playdateID
                    NotificationCenter.default.post(name: .navigateToPlaydateDetail, object: nil, userInfo: ["playdateID": correctPlaydateId])
                } else {
                    print("   ❌ Could not fetch correct playdateID from invitation \(notification.relatedID)")
                    // Handle error - maybe show an alert or just don't navigate
                }
            }
             break
        }
    }

    // Helper function to fetch the actual playdateID from the invitation document
    private func fetchPlaydateIdFromInvitation(invitationId: String, completion: @escaping (String?) -> Void) {
        db.collection("playdateInvitations").document(invitationId).getDocument { snapshot, error in
            if let error = error {
                print("   ❌ Error fetching invitation document \(invitationId): \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("   ❌ Invitation document \(invitationId) not found.")
                completion(nil)
                return
            }

            // Extract the playdateID field
            let playdateID = snapshot.data()?["playdateID"] as? String
            completion(playdateID)
        }
    }
}

// NotificationRow remains the same
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: notification.type))
                .font(.title2)
                .foregroundColor(iconColor(for: notification.type))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title(for: notification))
                    .font(.headline)
                    .lineLimit(1)
                if let message = notification.message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Text(notification.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .cornerRadius(5)
    }

    private func iconName(for type: AppNotification.NotificationType) -> String {
        switch type {
        case .friendRequest: return "person.crop.circle.badge.plus"
        case .newChatMessage: return "message.fill"
        case .playdateInvitation: return "calendar.badge.plus"
        }
    }

    private func iconColor(for type: AppNotification.NotificationType) -> Color {
        switch type {
        case .friendRequest: return .orange
        case .newChatMessage: return .green
        case .playdateInvitation: return .purple
        }
    }

    private func title(for notification: AppNotification) -> String {
        let sender = notification.senderName ?? "Someone"
        switch notification.type {
        case .friendRequest: return "\(sender) sent you a friend request"
        case .newChatMessage: return "New message from \(sender)"
        case .playdateInvitation: return "\(sender) invited you to a playdate"
        }
    }
}

// Preview Provider remains commented out
/*
struct NotificationCenterView_Previews: PreviewProvider {
    static var previews: some View {
        // ... preview code ...
    }
}
*/
