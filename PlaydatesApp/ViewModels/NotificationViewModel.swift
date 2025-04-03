import Foundation
import Firebase
import FirebaseFirestore
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var unreadCount: Int = 0

    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var authViewModel: AuthViewModel? // Store the injected AuthViewModel
    private var authSubscription: AnyCancellable? // Store subscription separately

    // Default initializer
    init() {
        print("🔔 NotificationViewModel initialized (default init). Call setup() next.")
    }

    // Call this method from the View's onAppear
    func setup(authViewModel: AuthViewModel) {
        // Prevent duplicate setup
        guard self.authViewModel == nil else {
            print("🔔 NotificationViewModel setup already called.")
            return
        }

        self.authViewModel = authViewModel
        print("🔔 NotificationViewModel: AuthViewModel injected via setup(). Setting up user observation.")

        // Observe user changes from the injected AuthViewModel
        authSubscription?.cancel() // Cancel previous subscription if any

        authSubscription = authViewModel.$user
            .sink { [weak self] user in
                guard let self = self else { return }
                if let user = user, let userId = user.id {
                    print("🔔 NotificationViewModel: User logged in (\(userId)). Setting up listener.")
                    self.setupNotificationListener(for: userId)
                } else {
                    print("🔔 NotificationViewModel: User logged out. Removing listener.")
                    self.removeListener()
                    self.notifications = [] // Clear notifications on logout
                    self.unreadCount = 0
                }
            }
            // Store the new subscription separately
            // .store(in: &cancellables) // Avoid storing here if setup can be recalled
    }


    deinit {
        // Ensure listener removal happens on the main actor
        Task { @MainActor [weak self] in
             self?.removeListener()
        }
        authSubscription?.cancel() // Cancel the auth observation
        print("🗑️ NotificationViewModel deinitialized.")
    }

    func setupNotificationListener(for userID: String) {
        removeListener() // Ensure no duplicate listeners

        isLoading = true
        error = nil

        let query = db.collection("users").document(userID).collection("notifications")
            .order(by: "timestamp", descending: true) // Show newest first
            .limit(to: 50) // Limit the number of notifications fetched initially

        listenerRegistration = query.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            // Use Task @MainActor for safety, though addSnapshotListener often calls back on main
            Task { @MainActor in
                self.isLoading = false

                if let error = error {
                    print("❌ Error fetching notifications: \(error.localizedDescription)")
                    self.error = error
                    self.notifications = []
                    self.unreadCount = 0
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Notification snapshot documents are nil.")
                    self.notifications = []
                    self.unreadCount = 0
                    return
                }

                print("✅ Notification listener received \(documents.count) documents.")
                self.notifications = documents.compactMap { doc -> AppNotification? in
                    do {
                        // Decode the notification, Firestore automatically maps @DocumentID
                        return try doc.data(as: AppNotification.self)
                    } catch {
                        print("❌ Failed to decode notification \(doc.documentID): \(error)")
                        return nil
                    }
                }
                // Calculate unread count after updating notifications
                self.calculateUnreadCount()
                print("📊 Unread notification count: \(self.unreadCount)")
            }
        }
    }

    func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        print("👂 Notification listener removed.")
    }

    // MARK: - Actions

    func markAsRead(notificationID: String) async {
        // Use the stored authViewModel
        guard let userID = self.authViewModel?.user?.id else {
            print("❌ Cannot mark notification as read: User not logged in or AuthViewModel not set.")
            return
        }
        guard !notificationID.isEmpty else {
             print("❌ Cannot mark notification as read: Invalid notification ID.")
             return
         }

        let docRef = db.collection("users").document(userID).collection("notifications").document(notificationID)

        do {
            try await docRef.updateData(["isRead": true])
            print("✅ Marked notification \(notificationID) as read.")
            // The listener will automatically update the local array and unread count
        } catch {
            print("❌ Error marking notification \(notificationID) as read: \(error.localizedDescription)")
            // Optionally set an error state for the UI
            self.error = error
        }
    }

    func markAllAsRead() async {
         // Use the stored authViewModel
         guard let userID = self.authViewModel?.user?.id else {
             print("❌ Cannot mark all notifications as read: User not logged in or AuthViewModel not set.")
             return
         }

         // Fetch only unread notifications to update
         let unreadQuery = db.collection("users").document(userID).collection("notifications")
             .whereField("isRead", isEqualTo: false)

         do {
             let snapshot = try await unreadQuery.getDocuments()
             if snapshot.isEmpty {
                 print("ℹ️ No unread notifications to mark as read.")
                 return
             }

             let batch = db.batch()
             snapshot.documents.forEach { doc in
                 batch.updateData(["isRead": true], forDocument: doc.reference) // Add forDocument label
             }
             try await batch.commit()
             print("✅ Marked \(snapshot.count) notifications as read.")
             // Listener will update UI and count
         } catch {
             print("❌ Error marking all notifications as read: \(error.localizedDescription)")
             self.error = error
         }
     }

    // MARK: - Helpers

    private func calculateUnreadCount() {
        // Calculate unread count based on the current notifications array
        self.unreadCount = notifications.filter { !$0.isRead }.count
    }
}
