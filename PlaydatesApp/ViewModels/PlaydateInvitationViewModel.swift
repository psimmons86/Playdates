import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI // Import SwiftUI if needed

// MARK: - Support Models (Ensure PlaydateInvitation is defined, likely in Models)

// Assuming PlaydateInvitation exists in Models/PlaydateInvitation.swift
// struct PlaydateInvitation: Identifiable, Codable { ... }
// Assuming InvitationStatus enum exists (likely in PlaydateInvitation.swift)
// enum InvitationStatus: String, Codable { ... }

// Custom Error enum for PlaydateInvitationViewModel specific errors
enum InvitationError: Error, LocalizedError {
    case firestoreError(Error)
    case userNotLoggedIn
    case invitationHasNoID
    case playdateNotFound // Error when playdate document doesn't exist during accept
    case failedToAddUserToPlaydate(Error) // Error during transaction
    case failedToSendInvitation
    case failedToFetchInvitations
    case failedToRespond // Generic response failure
    case unknown

    var errorDescription: String? {
        switch self {
        case .firestoreError(let error):
            return String(format: NSLocalizedString("invitation.error.firestore", comment: "Generic Firestore error for invitations"), error.localizedDescription)
        case .userNotLoggedIn:
            return NSLocalizedString("invitation.error.userNotLoggedIn", comment: "Error when user is not authenticated for invitations")
        case .invitationHasNoID:
            return NSLocalizedString("invitation.error.invitationHasNoID", comment: "Error when invitation object lacks an ID")
        case .playdateNotFound:
            return NSLocalizedString("invitation.error.playdateNotFound", comment: "Error when the associated playdate is not found")
        case .failedToAddUserToPlaydate(let error):
            return String(format: NSLocalizedString("invitation.error.failedToAddUserToPlaydate", comment: "Error adding user to playdate attendees"), error.localizedDescription)
        case .failedToSendInvitation:
             return NSLocalizedString("invitation.error.failedToSendInvitation", comment: "Error sending a playdate invitation")
        case .failedToFetchInvitations:
             return NSLocalizedString("invitation.error.failedToFetchInvitations", comment: "Error fetching playdate invitations")
        case .failedToRespond:
             return NSLocalizedString("invitation.error.failedToRespond", comment: "Error responding to a playdate invitation")
        case .unknown:
            return NSLocalizedString("invitation.error.unknown", comment: "Generic unknown invitation error")
        }
    }

    // Define simple integer codes for NSError creation if needed
    var errorCode: Int {
        switch self {
        case .firestoreError: return 1001
        case .userNotLoggedIn: return 1002
        case .invitationHasNoID: return 1003
        case .playdateNotFound: return 1004
        case .failedToAddUserToPlaydate: return 1005
        case .failedToSendInvitation: return 1006
        case .failedToFetchInvitations: return 1007
        case .failedToRespond: return 1008
        case .unknown: return 1000
        }
    }
}


// MARK: - PlaydateInvitationViewModel Class Definition

@MainActor // Ensure UI updates happen on the main thread
class PlaydateInvitationViewModel: ObservableObject {

    @Published var pendingInvitations: [PlaydateInvitation] = []
    @Published var isLoading: Bool = false
    @Published var error: InvitationError?

    // Use service singletons
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private let authService = FirebaseAuthService.shared

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    private var invitationsListener: ListenerRegistration?
    private var currentUserID: String?

    init() {
        guard let uid = authService.currentUser?.uid else { // Use authService
            print("❌ PlaydateInvitationViewModel initialized without a logged-in user.")
            self.error = .userNotLoggedIn
            // Handle appropriately
            return
        }
        self.currentUserID = uid
        print("💌 PlaydateInvitationViewModel initialized for user: \(uid)")
        setupInvitationsListener(for: uid) // Start listening immediately
    }

    deinit {
        // Directly remove the listener from deinit (safe)
        invitationsListener?.remove()
        print("🗑️ PlaydateInvitationViewModel deinitialized and listener removed.")
    }

    // MARK: - Listener Management

    /// Sets up the listener for pending invitations received by the user.
    func setupInvitationsListener(for userID: String) {
        // Remove existing listener first
        invitationsListener?.remove()
        invitationsListener = nil

        self.currentUserID = userID // Update current user ID if needed

        print("👂 Setting up invitations listener for user: \(userID)")
        isLoading = true
        error = nil

        let invitationsQuery = db.collection("playdateInvitations")
            .whereField("recipientID", isEqualTo: userID)
            // Use top-level InvitationStatus defined in PlaydateInvitation.swift
            .whereField("status", isEqualTo: InvitationStatus.pending.rawValue)
            .order(by: "createdAt", descending: true) // Show newest first

        // Add explicit types to the listener closure
        invitationsListener = invitationsQuery.addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
            // Ensure UI updates are on the main thread
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("👂 Invitations listener update received.")

                // Stop loading indicator once data (or error) is received
                self.isLoading = false

                if let error = error {
                    print("❌ Error in invitations listener: \(error.localizedDescription)")
                    self.error = .firestoreError(error)
                    self.pendingInvitations = [] // Clear data on error
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ Invitations listener snapshot documents nil.")
                    self.pendingInvitations = [] // Clear data if snapshot is nil
                    return
                }

                print("🔍 Invitations listener received \(documents.count) pending invitation documents.")
                // Revert listener logic to use custom decoder and fallback ID assignment
                self.pendingInvitations = documents.compactMap { doc -> PlaydateInvitation? in
                    do {
                        // Decode the invitation object using the restored custom decoder
                        var invitation = try doc.data(as: PlaydateInvitation.self)
                        // Manually assign ID if @DocumentID failed during decoding
                        if invitation.id == nil {
                            invitation.id = doc.documentID
                            print("   Manually assigned ID \(doc.documentID) to invitation for playdate \(invitation.playdateID)")
                        }
                        // Ensure ID is not nil before returning
                        guard invitation.id != nil else {
                             print("   ⚠️ Skipping invitation document \(doc.documentID) because ID is nil after manual assignment attempt.")
                             return nil
                        }
                        return invitation
                    } catch {
                        print("   ❌ Failed to decode invitation document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                self.error = nil // Clear error on success
            } // End DispatchQueue.main.async
        }
    }

    /// Removes the active Firestore listener. Call this from appropriate view lifecycle methods (e.g., onDisappear).
    func removeListener() {
        invitationsListener?.remove()
        invitationsListener = nil
        print("👂 Invitations listener removed.")
    }


    // MARK: - Invitation Actions

    /// Send a playdate invitation to another user.
    func sendInvitation(playdateID: String, recipientID: String, message: String? = nil) async throws {
        guard let senderID = self.currentUserID else {
            throw InvitationError.userNotLoggedIn
        }
         // Prevent inviting self
         guard senderID != recipientID else {
             print("⚠️ Attempted to invite self to playdate.")
             return
         }

        // Update isLoading on main thread before async operation
        self.isLoading = true

        // Create a dictionary for the new invitation data
        // We don't create a PlaydateInvitation object directly because
        // @ServerTimestamp fields (createdAt, updatedAt) are handled by Firestore.
        var invitationData: [String: Any] = [
            "playdateID": playdateID,
            "senderID": senderID,
            "recipientID": recipientID,
            "status": InvitationStatus.pending.rawValue
            // createdAt and updatedAt will be added by Firestore via @ServerTimestamp
        ]
        // Add message only if it's not nil or empty
        if let message = message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            invitationData["message"] = message
        }

        do {
            // Use addDocument(data:) which allows Firestore to handle @ServerTimestamp
            let _ = try await db.collection("playdateInvitations").addDocument(data: invitationData)

            // Update state on main thread after await
            self.isLoading = false
            print("✅ Playdate invitation sent successfully to \(recipientID) for playdate \(playdateID)")
            self.error = nil
        } catch {
            // Update state on main thread after await
            self.isLoading = false
            print("❌ Error sending playdate invitation: \(error.localizedDescription)")
            let specificError = InvitationError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }

    /// Respond to a received playdate invitation (accept or decline).
    // Revert signature to accept the full object
    func respondToInvitation(invitation: PlaydateInvitation, accept: Bool) async throws {
        // Revert to checking the optional ID from the passed object
        guard let invitationID = invitation.id else {
            print("❌ Invitation ID is nil when trying to respond.")
            throw InvitationError.invitationHasNoID
        }

        guard let recipientID = self.currentUserID, recipientID == invitation.recipientID else {
             print("❌ Attempted to respond to an invitation not addressed to the current user or user not logged in.")
             throw InvitationError.userNotLoggedIn
        }

         guard invitation.status == .pending else {
             print("⚠️ Attempted to respond to a non-pending invitation: \(invitationID)")
             return // Just return if already responded to, not necessarily an error
         }

        // Update isLoading on main thread
        self.isLoading = true

        // Use top-level InvitationStatus
        let newStatus = accept ? InvitationStatus.accepted : InvitationStatus.declined
        let invitationRef = db.collection("playdateInvitations").document(invitationID) // Use the unwrapped ID

        do {
            let batch = db.batch()

            // 1. Update the invitation status
            batch.updateData([
                "status": newStatus.rawValue,
                "updatedAt": FieldValue.serverTimestamp() // Use server timestamp for update
            ], forDocument: invitationRef)

            // 2. If accepting, add the user to the playdate's attendees list
            if accept {
                let playdateRef = db.collection("playdates").document(invitation.playdateID) // Use playdateID from invitation object
                batch.updateData([
                    "attendeeIDs": FieldValue.arrayUnion([recipientID]) // Use recipientID (which is currentUserID)
                ], forDocument: playdateRef)
            }

            // 3. Commit the batch
            try await batch.commit()

            // Update state on main thread after await
            self.isLoading = false
            print("✅ Successfully responded to invitation \(invitationID) with status: \(newStatus.rawValue)")
            if accept {
                 print("✅ User \(recipientID) added to attendees for playdate \(invitation.playdateID)")
            }
            self.error = nil

        } catch {
            // Update state on main thread after await
            self.isLoading = false
            print("❌ Error responding to invitation \(invitationID): \(error.localizedDescription)")
            let specificError = InvitationError.firestoreError(error)
            self.error = specificError
            throw specificError
        }
    }

    // MARK: - Helper Methods (Example: Add User to Playdate with Transaction)

    /// Add a user to playdate attendees using a transaction (safer for read-modify-write).
    private func addUserToPlaydateTransactional(
        userID: String,
        playdateID: String
    ) async throws {
        let playdateRef = db.collection("playdates").document(playdateID)

        // No direct UI updates here, but errors might be surfaced later.
        // The transaction itself handles background work.
        do {
            try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                let playdateDocument: DocumentSnapshot
                do {
                    try playdateDocument = transaction.getDocument(playdateRef)
                } catch let fetchError as NSError {
                    print("❌ Transaction error fetching playdate \(playdateID): \(fetchError)")
                    errorPointer?.pointee = fetchError
                    return nil
                }

                guard playdateDocument.exists else {
                    print("❌ Playdate \(playdateID) not found during transaction.")
                    // Use the defined errorCode
                    let notFoundError = NSError(
                        domain: "PlaydateInvitationViewModel",
                        code: InvitationError.playdateNotFound.errorCode, // Corrected: Use errorCode
                        userInfo: [NSLocalizedDescriptionKey: InvitationError.playdateNotFound.localizedDescription ?? "Playdate not found"]
                    )
                    errorPointer?.pointee = notFoundError
                    return nil
                }

                var attendeeIDs = playdateDocument.data()?["attendeeIDs"] as? [String] ?? []

                if !attendeeIDs.contains(userID) {
                    attendeeIDs.append(userID)
                    transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: playdateRef)
                    print("➕ User \(userID) added to attendees via transaction for playdate \(playdateID)")
                } else {
                     print("ℹ️ User \(userID) already in attendees for playdate \(playdateID)")
                }

                return nil
            })
             print("✅ Transaction to add user \(userID) to playdate \(playdateID) completed successfully.")
        } catch {
             // If an error needs to update UI state (like self.error), dispatch it.
             // Here, we just rethrow, assuming the caller handles UI updates.
             print("❌ Transaction failed to add user \(userID) to playdate \(playdateID): \(error.localizedDescription)")
             throw InvitationError.failedToAddUserToPlaydate(error)
        }
    }

} // Closes PlaydateInvitationViewModel class
