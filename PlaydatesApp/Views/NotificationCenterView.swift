import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Notification Data Models

/// Represents a single notification in the app
struct UserNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let recipientID: String
    let senderID: String?
    let type: NotificationType
    let message: String
    let relatedItemID: String?
    let relatedItemType: RelatedItemType?
    let createdAt: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipientID
        case senderID
        case type
        case message
        case relatedItemID
        case relatedItemType
        case createdAt
        case isRead
    }
}

/// Types of notifications in the system
enum NotificationType: String, Codable {
    case friendRequest
    case friendAccepted
    case playdateInvitation
    case playdateJoined
    case playdateReminder
    case playdateMessage
    case systemMessage
    
    var icon: String {
        switch self {
        case .friendRequest:
            return "person.badge.plus"
        case .friendAccepted:
            return "person.2.fill"
        case .playdateInvitation:
            return "calendar.badge.plus"
        case .playdateJoined:
            return "person.2.wave.2"
        case .playdateReminder:
            return "bell.fill"
        case .playdateMessage:
            return "message.fill"
        case .systemMessage:
            return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .friendRequest, .friendAccepted:
            return ColorTheme.primary
        case .playdateInvitation, .playdateJoined:
            return ColorTheme.highlight
        case .playdateReminder:
            return ColorTheme.accent
        case .playdateMessage:
            return ColorTheme.primary.opacity(0.8)
        case .systemMessage:
            return .gray
        }
    }
}

/// Types of related items in notifications
enum RelatedItemType: String, Codable {
    case friend
    case friendRequest
    case playdate
    case playdateInvitation
    case message
}

// MARK: - Notification View Model

/// View model for handling notifications
class NotificationViewModel: ObservableObject {
    @Published var notifications: [UserNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var notificationsListener: ListenerRegistration?
    
    deinit {
        notificationsListener?.remove()
    }
    
    // MARK: - Notification Fetching
    
    /// Set up a real-time listener for user notifications
    func setupNotificationsListener(userID: String) {
        isLoading = true
        
        // Remove any existing listener
        notificationsListener?.remove()
        
        // Set up a new listener
        notificationsListener = db.collection("notifications")
            .whereField("recipientID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .limit(to: 50) // Limit to avoid too many notifications
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.notifications = []
                    self.unreadCount = 0
                    return
                }
                
                // Parse notifications
                self.notifications = documents.compactMap { document -> UserNotification? in
                    try? document.data(as: UserNotification.self)
                }
                
                // Count unread notifications
                self.unreadCount = self.notifications.filter { !$0.isRead }.count
            }
    }
    
    /// Mark a notification as read
    func markAsRead(notification: UserNotification) {
        guard let id = notification.id else { return }
        
        db.collection("notifications").document(id).updateData([
            "isRead": true
        ]) { [weak self] error in
            if let error = error {
                self?.error = error.localizedDescription
            }
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead(userID: String) {
        // Get IDs of all unread notifications
        let unreadIDs = notifications.filter { !$0.isRead }.compactMap { $0.id }
        
        // Create a batch to update them all at once
        let batch = db.batch()
        
        for id in unreadIDs {
            let docRef = db.collection("notifications").document(id)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        // Commit the batch
        batch.commit { [weak self] error in
            if let error = error {
                self?.error = error.localizedDescription
            }
        }
    }
    
    // MARK: - Notification Creation
    
    /// Create a friend request notification
    func createFriendRequestNotification(
        recipientID: String,
        senderID: String,
        senderName: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: senderID,
            type: .friendRequest,
            message: "\(senderName) sent you a friend request",
            relatedItemID: senderID,
            relatedItemType: .friendRequest,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a friend accepted notification
    func createFriendAcceptedNotification(
        recipientID: String,
        senderID: String,
        senderName: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: senderID,
            type: .friendAccepted,
            message: "\(senderName) accepted your friend request",
            relatedItemID: senderID,
            relatedItemType: .friend,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a playdate invitation notification
    func createPlaydateInvitationNotification(
        recipientID: String,
        senderID: String,
        senderName: String,
        playdateID: String,
        playdateTitle: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: senderID,
            type: .playdateInvitation,
            message: "\(senderName) invited you to \(playdateTitle)",
            relatedItemID: playdateID,
            relatedItemType: .playdateInvitation,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a playdate joined notification
    func createPlaydateJoinedNotification(
        recipientID: String,
        senderID: String,
        senderName: String,
        playdateID: String,
        playdateTitle: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: senderID,
            type: .playdateJoined,
            message: "\(senderName) joined your playdate \(playdateTitle)",
            relatedItemID: playdateID,
            relatedItemType: .playdate,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a playdate reminder notification
    func createPlaydateReminderNotification(
        recipientID: String,
        playdateID: String,
        playdateTitle: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: nil,
            type: .playdateReminder,
            message: "Reminder: \(playdateTitle) is coming up soon",
            relatedItemID: playdateID,
            relatedItemType: .playdate,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a new message notification
    func createMessageNotification(
        recipientID: String,
        senderID: String,
        senderName: String,
        message: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: senderID,
            type: .playdateMessage,
            message: "\(senderName): \(message)",
            relatedItemID: senderID, // Using senderID to open chat with this person
            relatedItemType: .message,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Create a system message notification
    func createSystemNotification(
        recipientID: String,
        message: String
    ) {
        let notification = UserNotification(
            recipientID: recipientID,
            senderID: nil,
            type: .systemMessage,
            message: message,
            relatedItemID: nil,
            relatedItemType: nil,
            createdAt: Date(),
            isRead: false
        )
        
        saveNotification(notification)
    }
    
    /// Save a notification to Firestore
    private func saveNotification(_ notification: UserNotification) {
        do {
            _ = try db.collection("notifications").addDocument(from: notification)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Notification Center View

/// View for displaying all user notifications
struct NotificationCenterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(ColorTheme.lightText)
                        
                        Text("No Notifications")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Text("When you receive notifications, they will appear here")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Filter tabs (All, Unread)
                        // Would be implemented in a full app
                        
                        // Notifications list
                        List {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    .padding(.horizontal)
                                    .onAppear {
                                        if !notification.isRead {
                                            viewModel.markAsRead(notification: notification)
                                        }
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                if !viewModel.notifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Mark All Read") {
                            if let userId = authViewModel.user?.id {
                                viewModel.markAllAsRead(userID: userId)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if let userId = authViewModel.user?.id {
                    viewModel.setupNotificationsListener(userID: userId)
                }
            }
        }
    }
}

/// Row for a single notification
struct NotificationRow: View {
    let notification: UserNotification
    @State private var senderUser: User?
    
    var body: some View {
        HStack(spacing: 16) {
            // Notification icon
            ZStack {
                Circle()
                    .fill(notification.type.color)
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .foregroundColor(.white)
            }
            
            // Notification content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(notification.isRead ? ColorTheme.lightText : ColorTheme.darkPurple)
                    .lineLimit(2)
                
                Text(timeAgo(date: notification.createdAt))
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(ColorTheme.highlight)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            if let senderId = notification.senderID {
                loadSenderDetails(senderId)
            }
        }
    }
    
    private func loadSenderDetails(_ senderId: String) {
        // In a real app, you would fetch the user details from Firestore
        // For this demo, we'll use a placeholder
        // FirebaseFirestore.firestore().collection("users").document(senderId).getDocument { ... }
    }
    
    private func timeAgo(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Notification Badge

/// Badge to show on tab bar for unread notifications
struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(ColorTheme.highlight)
                
                if count < 10 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("9+")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 20, height: 20)
        } else {
            // Empty view when no notifications
            EmptyView()
        }
    }
}

// MARK: - Modified Tab View with Notification Badge

/// Updated MainTabView with notification badges
struct MainTabViewWithNotifications: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Explore Tab
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "map.fill")
                }
                .tag(1)
            
            // Create Tab
            CreatePlaydateView(onComplete: { _ in })
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // Friends Tab with notification badge
            ZStack(alignment: .topTrailing) {
                FriendsView()
                    .environmentObject(authViewModel)
                
                NotificationBadge(count: friendRequestCount)
                    .offset(x: -10, y: 10)
            }
            .tabItem {
                Label("Friends", systemImage: "person.2.fill")
            }
            .tag(3)
            
            // Notifications Tab with badge
            ZStack(alignment: .topTrailing) {
                NotificationCenterView()
                    .environmentObject(authViewModel)
                
                NotificationBadge(count: notificationViewModel.unreadCount)
                    .offset(x: -10, y: 10)
            }
            .tabItem {
                Label("Notifications", systemImage: "bell.fill")
            }
            .tag(4)
        }
        .accentColor(ColorTheme.primary)
        .onAppear {
            if let userId = authViewModel.user?.id {
                notificationViewModel.setupNotificationsListener(userID: userId)
            }
        }
    }
    
    // This would be set by the FriendshipViewModel in a real app
    private var friendRequestCount: Int {
        // For demo purposes, we'll return a fixed number
        return 2
    }
}
