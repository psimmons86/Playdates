import SwiftUI
import Combine

// View model for conversations list
class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private var messagingService = MessagingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Conversation data model
    struct Conversation: Identifiable {
        let id: String
        let user: User
        let lastMessagePreview: String
        let lastMessageTime: Date
        let isUserOnline: Bool
        let hasUnreadMessages: Bool
        let unreadCount: Int
    }
    
    func loadConversations(for userId: String) {
        isLoading = true
        
        // In a real app, you'd fetch conversations from Firestore
        // For now, we'll simulate with a delay and mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.conversations = self.generateMockConversations()
            self.isLoading = false
        }
    }
    
    private func generateMockConversations() -> [Conversation] {
        // Create some mock conversations
        return [
            Conversation(
                id: "conv1",
                user: User(
                    id: "user1",
                    name: "Emma Johnson",
                    email: "emma@example.com",
                    profileImageURL: nil,
                    createdAt: Date(),
                    lastActive: Date()
                ),
                lastMessagePreview: "What time should we meet at the park?",
                lastMessageTime: Date().addingTimeInterval(-3600), // 1 hour ago
                isUserOnline: true,
                hasUnreadMessages: true,
                unreadCount: 2
            ),
            Conversation(
                id: "conv2",
                user: User(
                    id: "user2",
                    name: "Michael Smith",
                    email: "michael@example.com",
                    profileImageURL: nil,
                    createdAt: Date(),
                    lastActive: Date()
                ),
                lastMessagePreview: "The kids had a great time yesterday!",
                lastMessageTime: Date().addingTimeInterval(-86400), // 1 day ago
                isUserOnline: false,
                hasUnreadMessages: false,
                unreadCount: 0
            ),
            Conversation(
                id: "conv3",
                user: User(
                    id: "user3",
                    name: "Sophia Rodriguez",
                    email: "sophia@example.com",
                    profileImageURL: nil,
                    createdAt: Date(),
                    lastActive: Date()
                ),
                lastMessagePreview: "Thanks for organizing the playdate",
                lastMessageTime: Date().addingTimeInterval(-172800), // 2 days ago
                isUserOnline: true,
                hasUnreadMessages: false,
                unreadCount: 0
            )
        ]
    }
}

struct ConversationsListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ConversationsViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search conversations", text: $searchText)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
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
                emptyStateView
            } else {
                // Conversations list
                List {
                    ForEach(filteredConversations) { conversation in
                        NavigationLink(
                            destination: EnhancedChatView(recipientUser: conversation.user)
                                .environmentObject(authViewModel)
                        ) {
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
        .navigationTitle("Messages")
        .onAppear {
            if let userId = authViewModel.user?.id {
                viewModel.loadConversations(for: userId)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "message.fill")
                .font(.system(size: 70))
                .foregroundColor(ColorTheme.lightText.opacity(0.5))
            
            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.darkPurple)
            
            Text("Start a conversation with other parents by inviting them to a playdate or sending a message from their profile")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: FriendsView()) {
                Text("Find Friends")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    // Helper function to format time
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            // If today, show time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            // If yesterday, show "Yesterday"
            return "Yesterday"
        } else {
            // Otherwise show date
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }
    
    private var filteredConversations: [ConversationsViewModel.Conversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter { conversation in
                conversation.user.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: ConversationsViewModel.Conversation
    
    var body: some View {
        HStack(spacing: 16) {
            // User avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                if #available(iOS 17.0, *) {
                    ProfileImageView(imageURL: conversation.user.profileImageURL, size: 56)
                } else {
                    Circle()
                        .fill(ColorTheme.primary.opacity(0.7))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
                
                if conversation.isUserOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 14, height: 14)
                        )
                }
            }
            
            // Message preview
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.user.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Spacer()
                    
                    Text(formatTime(conversation.lastMessageTime))
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
                
                HStack {
                    Text(conversation.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundColor(conversation.hasUnreadMessages ? ColorTheme.darkPurple : ColorTheme.lightText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.hasUnreadMessages {
                        // Unread indicator
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
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
    
    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            // If today, show time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            // If yesterday, show "Yesterday"
            return "Yesterday"
        } else {
            // Otherwise show date
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }
}
