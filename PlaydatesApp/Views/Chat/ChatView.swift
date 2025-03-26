import SwiftUI
import FirebaseFirestore
import Combine

// MARK: - Chat System

struct ChatView: View {
    let recipient: User
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat history
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Date divider
                            DateDivider(date: Date())
                                .padding(.vertical, 8)
                            
                            // Messages
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    .background(ColorTheme.background)
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input
                HStack(spacing: 12) {
                    Button(action: {
                        // Open photo picker
                    }) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ColorTheme.primary)
                    }
                    
                    TextField("Type a message...", text: $messageText)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(20)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? ColorTheme.lightText : ColorTheme.primary)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle(recipient.name)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadChatHistory()
            }
        }
    }
    
    private func loadChatHistory() {
        // In a real app, you would fetch messages from a database
        // For now, we'll add some mock messages with a delay to simulate loading
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages = [
                ChatMessage(id: "1", text: "Hi there! Would you like to arrange a playdate?", isFromCurrentUser: false, timestamp: Date(timeIntervalSinceNow: -86400)),
                ChatMessage(id: "2", text: "That sounds great! When would work for you?", isFromCurrentUser: true, timestamp: Date(timeIntervalSinceNow: -86000)),
                ChatMessage(id: "3", text: "How about this weekend at the park?", isFromCurrentUser: false, timestamp: Date(timeIntervalSinceNow: -85000)),
                ChatMessage(id: "4", text: "Perfect! We're free on Saturday afternoon.", isFromCurrentUser: true, timestamp: Date(timeIntervalSinceNow: -84000))
            ]
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create a new message
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            text: messageText,
            isFromCurrentUser: true,
            timestamp: Date()
        )
        
        // Add to messages array
        messages.append(newMessage)
        
        // Clear the input field
        messageText = ""
        
        // In a real app, you would also save this message to a database
        
        // Simulate response from recipient
        simulateReply()
    }
    
    private func simulateReply() {
        // In a real app, you would not have this
        // This is just to demonstrate the UI with a fake reply
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let replies = [
                "Sounds good!",
                "I'll check my calendar and get back to you.",
                "The kids would love that!",
                "Great idea!",
                "Let me know what time works for you."
            ]
            
            let randomReply = replies.randomElement() ?? "Ok"
            
            let replyMessage = ChatMessage(
                id: UUID().uuidString,
                text: randomReply,
                isFromCurrentUser: false,
                timestamp: Date()
            )
            
            messages.append(replyMessage)
        }
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let isFromCurrentUser: Bool
    let timestamp: Date
    var imageURL: String? = nil // Optional image attachment
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                if let imageURL = message.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 150)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 150)
                                .cornerRadius(16)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .frame(width: 200, height: 150)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                Text(message.text)
                    .padding(12)
                    .background(message.isFromCurrentUser ? ColorTheme.primary : Color.white)
                    .foregroundColor(message.isFromCurrentUser ? .white : ColorTheme.darkPurple)
                    .cornerRadius(16)
                
                // Time
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(ColorTheme.lightText)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .id(message.id) // For scroll position
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DateDivider: View {
    let date: Date
    
    var body: some View {
        HStack {
            Line()
            
            Text(formatDate(date))
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
                .padding(.horizontal, 8)
            
            Line()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    struct Line: View {
        var body: some View {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}
