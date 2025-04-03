import SwiftUI
import Combine

struct EnhancedChatView: View {
    let recipientUser: User
    @State private var messageText = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    // Removed redundant local @State messages; view should use viewModel.messages
    @State private var imageUploadProgress: Double?
    @State private var scrollToBottom = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
            
            // Message list
            messageList
            
            // Message input
            messageInput
        }
        .onAppear {
            // Use setupListener from the correct ViewModel
            guard let recipientId = recipientUser.id else { return }
            viewModel.setupListener(for: recipientId)
        }
        .onDisappear {
            // Use removeListener from the correct ViewModel
            viewModel.removeListener()
        }
        .navigationBarHidden(true)
        .background(ColorTheme.background.edgesIgnoringSafeArea(.all))
    }
    
    private var chatHeader: some View {
        HStack {
            // Reverted Back Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            if #available(iOS 17.0, *) {
                ProfileImageView(imageURL: recipientUser.profileImageURL, size: 36)
            } else {
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recipientUser.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                // Removed Text view for online status as viewModel.isUserOnline is not available.
            }

            Spacer()
            
            // Reverted Info Button
            Button(action: {
                // Show profile
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(ColorTheme.primary)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var messageList: some View {
        ScrollViewReader { scrollView in
            // Handle loading state outside ScrollView
            if viewModel.isLoading {
                 loadingView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Handle error state
                        if let error = viewModel.error {
                            errorView(error)
                        }
                        // Handle empty state
                        else if viewModel.messages.isEmpty {
                            emptyMessagesView()
                        }
                        // Display messages
                        else {
                            messageListView()
                        }
                    }
                    .padding()
                }
                .background(ColorTheme.background) // Apply background to ScrollView content area
                .onChange(of: viewModel.messages) { _ in // Use the correct published property
                    scrollToLastMessage(scrollView: scrollView)
                }
                .onAppear {
                    scrollToLastMessage(scrollView: scrollView)
                }
            }
        }
        .background(ColorTheme.background) // Ensure background covers loading state too
    }

    // Helper view for loading state
    @ViewBuilder
    private func loadingView() -> some View {
        ProgressView("Loading messages...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorTheme.background) // Ensure background consistency
    }

    // Helper view for error state
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        Text("Error loading messages: \(error.localizedDescription)")
            .foregroundColor(.red)
            .padding()
    }

    // Helper view for empty state
    @ViewBuilder
    private func emptyMessagesView() -> some View {
        Text("No messages yet. Start the conversation!")
            .foregroundColor(.secondary)
            .padding()
    }

    // Helper view for the list of messages
    @ViewBuilder
    private func messageListView() -> some View {
        // Use the correct published property from the ViewModel
        ForEach(viewModel.messages) { message in
            let isFromCurrentUser = message.senderID == authViewModel.user?.id
            MessageBubble(message: message, isFromCurrentUser: isFromCurrentUser)
                .id(message.id) // Ensure ChatMessage has an id
        }
    }

    // Helper function for scrolling
    private func scrollToLastMessage(scrollView: ScrollViewProxy) {
        // Use the correct published property
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private var messageInput: some View {
        VStack(spacing: 0) {
            // Image preview if selected
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    // Progress indicator (if uploading)
                    if let progress = imageUploadProgress {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    // Reverted Remove Image Button
                    Button(action: {
                        selectedImage = nil
                        imageUploadProgress = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            HStack(spacing: 12) {
                // Reverted Media Attachment Button
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ColorTheme.primary)
                }
                
                // Text input
                TextField("Type a message...", text: $messageText)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(20)
                
                // Reverted Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty && selectedImage == nil ? 
                                        ColorTheme.lightText : ColorTheme.primary)
                }
                .disabled(messageText.isEmpty && selectedImage == nil)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }

    // setupChat() function is removed as its logic is handled in .onAppear

    private func sendMessage() {
        // No need for currentUserId and recipientId here, ViewModel handles it
        guard authViewModel.user?.id != nil else {
            return
        }
        
        // If there's an image, upload it first
        if let image = selectedImage {
            uploadImage(image) { imageUrl in
                // Call the async sendMessage from the correct ViewModel
                Task {
                    do {
                        try await viewModel.sendMessage(text: messageText, imageURL: imageUrl)
                        // Reset state on success
                        messageText = ""
                        selectedImage = nil
                        imageUploadProgress = nil
                    } catch {
                        // Handle error (e.g., show an alert)
                        print("❌ Error sending message with image: \(error.localizedDescription)")
                    }
                }
            }
        } else if !messageText.isEmpty {
            // Call the async sendMessage from the correct ViewModel
            Task {
                do {
                    try await viewModel.sendMessage(text: messageText)
                    // Reset message text on success
                    messageText = ""
                } catch {
                    // Handle error (e.g., show an alert)
                    print("❌ Error sending text message: \(error.localizedDescription)")
                }
            }
        }
    }

    // Note: This uploadImage function is a placeholder simulation.
    // In a real app, integrate with FirebaseStorageService.
    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        // Set initial progress
        imageUploadProgress = 0.0

        // Simulate upload progress (in a real app, you'd use Firebase Storage)
        var progress: Double = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.05
            imageUploadProgress = min(progress, 0.95)
            
            if progress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    imageUploadProgress = 1.0
                    let mockImageUrl = "https://example.com/images/\(UUID().uuidString).jpg"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completion(mockImageUrl)
                    }
                }
            }
        }
        timer.fire()
    }
}

// Supporting Views
struct DateDivider: View {
    let date: Date
    
    var body: some View {
        HStack {
            VStack { Divider() }
            
            Text(formatDate(date))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            
            VStack { Divider() }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool // Passed in from the ForEach loop

    // Access AuthViewModel to determine if message is from current user if needed elsewhere
    // @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()

                // Current user's message (right-aligned)
                VStack(alignment: .trailing, spacing: 4) {
                    // Message content
                    messageContent
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ColorTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    // Time
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .padding(.leading, 60)
            } else {
                // Other user's message (left-aligned)
                VStack(alignment: .leading, spacing: 4) {
                    // Message content
                    messageContent
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    
                    // Time
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                .padding(.trailing, 60)
                
                Spacer()
            }
        }
    }

    private var messageContent: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 8) {
            // Image if present
            if let imageURL = message.imageURL, !imageURL.isEmpty { // Check if URL is not empty
                // In a real app, you'd use an AsyncImage or similar
                Color.gray
                    .frame(width: 200, height: 150)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                    )
            }
            
            // Text
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.body)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
