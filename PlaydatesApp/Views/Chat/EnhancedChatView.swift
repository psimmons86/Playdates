import SwiftUI
import Combine

struct EnhancedChatView: View {
    let recipientUser: User
    @State private var messageText = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var messages: [ChatMessage] = []
    @State private var imageUploadProgress: Double?
    @State private var scrollToBottom = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChatViewModel()
    
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
            setupChat()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .navigationBarHidden(true)
        .background(ColorTheme.background.edgesIgnoringSafeArea(.all))
    }
    
    private var chatHeader: some View {
        HStack {
            Button(action: {
                // Go back
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
                
                Text(viewModel.isUserOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(viewModel.isUserOnline ? .green : .gray)
            }
            
            Spacer()
            
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
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Date divider
                    ForEach(viewModel.messageSections.keys.sorted(), id: \.self) { date in
                        if let sectionMessages = viewModel.messageSections[date] {
                            DateDivider(date: date)
                                .padding(.vertical, 8)
                            
                            ForEach(sectionMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastMessage = viewModel.messages.last {
                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
        .background(ColorTheme.background)
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
                // Media attachment button
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
                
                // Send button
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
    
    private func setupChat() {
        guard let currentUserId = authViewModel.user?.id,
              let recipientId = recipientUser.id else {
            return
        }
        
        viewModel.setupChat(currentUserId: currentUserId, recipientId: recipientId)
    }
    
    private func sendMessage() {
        guard let currentUserId = authViewModel.user?.id,
              let recipientId = recipientUser.id else {
            return
        }
        
        // If there's an image, upload it first
        if let image = selectedImage {
            uploadImage(image) { imageUrl in
                viewModel.sendMessage(
                    from: currentUserId,
                    to: recipientId,
                    text: messageText,
                    imageURL: imageUrl
                )
                
                // Reset state
                messageText = ""
                selectedImage = nil
                imageUploadProgress = nil
            }
        } else if !messageText.isEmpty {
            viewModel.sendMessage(
                from: currentUserId,
                to: recipientId,
                text: messageText
            )
            
            // Reset message text
            messageText = ""
        }
    }
    
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

// Supporting view model
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isUserOnline: Bool = false
    @Published var messageSections: [Date: [ChatMessage]] = [:]
    
    private var messagingService = MessagingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var currentUserId: String?
    private var recipientId: String?
    private var chatId: String?
    
    func setupChat(currentUserId: String, recipientId: String) {
        self.currentUserId = currentUserId
        self.recipientId = recipientId
        
        // Create chat ID
        chatId = getChatID(userID1: currentUserId, userID2: recipientId)
        
        // Start listening for messages
        messagingService.listenToConversation(between: currentUserId, and: recipientId)
        
        // Subscribe to message updates
        if let chatId = chatId {
            messagingService.$conversations
                .map { $0[chatId] ?? [] }
                .assign(to: &$messages)
            
            // Check if user is online (simulated)
            checkUserOnlineStatus(userId: recipientId)
        }
        
        // Subscribe to messages and create date sections
        $messages
            .map { messages -> [Date: [ChatMessage]] in
                let calendar = Calendar.current
                
                return Dictionary(grouping: messages) { message in
                    let components = calendar.dateComponents([.year, .month, .day], from: message.timestamp)
                    return calendar.date(from: components) ?? message.timestamp
                }
            }
            .assign(to: &$messageSections)
    }
    
    func sendMessage(from senderID: String, to recipientID: String, text: String, imageURL: String? = nil) {
        messagingService.sendMessage(from: senderID, to: recipientID, text: text, imageURL: imageURL)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error sending message: \(error.localizedDescription)")
                }
            }, receiveValue: { _ in
                // Message sent successfully
            })
            .store(in: &cancellables)
    }
    
    func stopListening() {
        if let chatId = chatId {
            messagingService.stopListening(to: chatId)
        }
    }
    
    private func getChatID(userID1: String, userID2: String) -> String {
        // Sort IDs to ensure the same chat ID regardless of who initiates
        let sortedIDs = [userID1, userID2].sorted()
        return "\(sortedIDs[0])_\(sortedIDs[1])"
    }
    
    private func checkUserOnlineStatus(userId: String) {
        // In a real app, you'd check a user's online status in Firebase
        // Here we'll just simulate it with a random value
        isUserOnline = Bool.random()
    }
}

// Helper for image picking
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
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
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
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
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 8) {
            // Image if present
            if let imageURL = message.imageURL {
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
