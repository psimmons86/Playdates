import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

// View model for conversations list
@MainActor
class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var error: Error?

    private var db = Firestore.firestore()
    private var conversationsListener: ListenerRegistration?
    private var currentUserId: String?

    // Conversation data model - Added optional lastMessage for cases where it might be missing
    struct Conversation: Identifiable {
        let id: String // Chat ID
        let otherParticipant: User // The user the current user is chatting with
        let lastMessagePreview: String? // Optional preview
        let lastMessageTime: Date? // Optional time
        // isUserOnline might require presence management (complex, omitted for now)
        // let isUserOnline: Bool
        var hasUnreadMessages: Bool // Calculated locally or stored
        var unreadCount: Int // Calculated locally or stored
    }

    // Setup listener when user ID is available
    func setup(userId: String) {
        guard !userId.isEmpty else {
            print("❌ ConversationsViewModel: Cannot setup with empty userId.")
            return
        }
        // Avoid duplicate setup if userId hasn't changed
        if self.currentUserId == userId, conversationsListener != nil {
            print("👂 ConversationsViewModel: Listener already active for user \(userId).")
            return
        }

        self.currentUserId = userId
        print("👂 ConversationsViewModel: Setting up listener for user \(userId).")
        loadConversations(for: userId)
    }

    func loadConversations(for userId: String) {
        isLoading = true
        error = nil
        conversationsListener?.remove() // Remove previous listener

        let query = db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true) // Order by most recent message

        conversationsListener = query.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching conversations: \(error.localizedDescription)")
                self.isLoading = false
                self.error = error
                self.conversations = []
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No conversation documents found.")
                self.isLoading = false
                self.conversations = []
                return
            }

            print("🔍 Conversations listener received \(documents.count) chat documents.")
            // Process documents to create Conversation objects
            self.processConversationDocuments(documents, currentUserId: userId)
        }
    }

    private func processConversationDocuments(_ documents: [QueryDocumentSnapshot], currentUserId: String) {
        // Use a TaskGroup to fetch participant details concurrently
        Task {
            var loadedConversations: [Conversation] = []

            await withTaskGroup(of: Conversation?.self) { group in
                for document in documents {
                    group.addTask {
                        let data = document.data()
                        let chatID = document.documentID

                        guard let participants = data["participants"] as? [String],
                              let otherParticipantId = participants.first(where: { $0 != currentUserId }) else {
                            print("⚠️ Skipping chat document \(chatID): Invalid participants.")
                            return nil
                        }

                        // Fetch the other participant's user data
                        do {
                            let userDoc = try await self.db.collection("users").document(otherParticipantId).getDocument()
                            // Use optional binding for safer decoding
                            guard var otherUser = try? userDoc.data(as: User.self) else {
                                print("⚠️ Skipping chat document \(chatID): Could not decode user \(otherParticipantId). User document exists: \(userDoc.exists)")
                                return nil
                            }
                            // Ensure user ID is set, as @DocumentID might not work if fetched directly by ID sometimes
                            if otherUser.id == nil {
                                otherUser.id = userDoc.documentID
                            }
                            // Final check if ID is still nil
                             guard otherUser.id != nil else {
                                 print("⚠️ Skipping chat document \(chatID): User ID is nil even after manual assignment for \(otherParticipantId).")
                                 return nil
                             }


                            let lastMessage = data["lastMessage"] as? String
                            let lastMessageTime = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue()

                            // TODO: Implement unread count fetching/calculation if needed
                            // For now, placeholder values
                            let unreadCount = 0 // Placeholder - Requires querying messages subcollection
                            let hasUnread = unreadCount > 0 // Placeholder

                            return Conversation(
                                id: chatID,
                                otherParticipant: otherUser,
                                lastMessagePreview: lastMessage,
                                lastMessageTime: lastMessageTime,
                                hasUnreadMessages: hasUnread,
                                unreadCount: unreadCount
                            )
                        } catch {
                            print("❌ Skipping chat document \(chatID): Error fetching user \(otherParticipantId): \(error)")
                            return nil
                        }
                    }
                }

                // Collect results from the group
                for await conversation in group {
                    if let conv = conversation {
                        loadedConversations.append(conv)
                    }
                }
            } // End TaskGroup

            // Update the UI on the main thread after all async operations complete
            self.conversations = loadedConversations.sorted { ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast) }
            self.isLoading = false
            self.error = nil // Clear error on success
            print("✅ Conversations loaded: \(self.conversations.count)")
        } // End Task
    }

    // Removed generateMockConversations()

    deinit {
        conversationsListener?.remove()
        print("🗑️ ConversationsViewModel deinitialized.")
    }
}

struct ConversationsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ConversationsViewModel()
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar (keep as is)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search conversations", text: $searchText)
                    .foregroundColor(.primary)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            } else if viewModel.conversations.isEmpty {
                emptyStateView // Keep empty state
            } else {
                // Conversations list
                List {
                    ForEach(filteredConversations) { conversation in
                        // Use conversation.otherParticipant for navigation
                        NavigationLink(destination: EnhancedChatView(recipientUser: conversation.otherParticipant)
                                        .environmentObject(authViewModel)) {
                            ConversationRow(conversation: conversation)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        // Removed .navigationTitle("Messages") - Title likely handled by parent (SocialTabView)
        .onAppear {
            if let userId = authViewModel.user?.id {
                // Call setup instead of loadConversations directly
                viewModel.setup(userId: userId)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { error in
             Button("OK") { viewModel.error = nil }
        } message: { error in
             Text(error.localizedDescription)
        }
    }

    // emptyStateView remains the same
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "message.fill")
                .font(.system(size: 70))
                .foregroundColor(ColorTheme.lightText.opacity(0.5))
            Text("No Conversations Yet")
                .font(.title2).fontWeight(.semibold).foregroundColor(ColorTheme.darkPurple)
            Text("Start a conversation with other parents by inviting them to a playdate or sending a message from their profile")
                .multilineTextAlignment(.center).font(.subheadline).foregroundColor(ColorTheme.lightText).padding(.horizontal, 40)
            // Consider removing this button or changing its destination
            // NavigationLink(destination: FriendsView()) { ... }
            Spacer()
        }
    }

    // filteredConversations remains the same
    private var filteredConversations: [ConversationsViewModel.Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.otherParticipant.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

// ConversationRow remains largely the same, but uses conversation.otherParticipant
struct ConversationRow: View {
    let conversation: ConversationsViewModel.Conversation

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if #available(iOS 17.0, *) {
                    ProfileImageView(imageURL: conversation.otherParticipant.profileImageURL, size: 56)
                } else {
                    Circle().fill(ColorTheme.primary.opacity(0.7)).frame(width: 56, height: 56)
                        .overlay(Image(systemName: "person.fill").font(.system(size: 24)).foregroundColor(.white))
                }
                // Online indicator logic removed for simplicity
                // if conversation.isUserOnline { ... }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherParticipant.name) // Use otherParticipant
                        .font(.headline).foregroundColor(ColorTheme.darkPurple)
                    Spacer()
                    if let time = conversation.lastMessageTime { // Handle optional time
                        Text(formatTime(time))
                            .font(.caption).foregroundColor(ColorTheme.lightText)
                    }
                }

                HStack {
                    Text(conversation.lastMessagePreview ?? "No messages yet") // Handle optional preview
                        .font(.subheadline)
                        .foregroundColor(conversation.hasUnreadMessages ? ColorTheme.darkPurple : ColorTheme.lightText)
                        .lineLimit(1)
                    Spacer()
                    if conversation.hasUnreadMessages {
                        Text("\(conversation.unreadCount)")
                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                            .frame(minWidth: 24, maxHeight: 24) // Use minWidth
                            .padding(4) // Add padding inside circle
                            .background(ColorTheme.highlight)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // formatTime helper remains the same
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter(); formatter.dateFormat = "h:mm a"; return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter(); formatter.dateFormat = "M/d/yy"; return formatter.string(from: date)
        }
    }
}
