import Foundation
import FirebaseFirestore

import FirebaseFirestoreSwift // Add this import for @DocumentID

/// Model for playdate invitations between users
struct PlaydateInvitation: Identifiable, Codable {
    @DocumentID var id: String? // Reverted to optional String?
    let playdateID: String
    let senderID: String
    let recipientID: String
    let status: InvitationStatus
    let message: String?
    // Use @ServerTimestamp for automatic handling by Firestore
    @ServerTimestamp var createdAt: Timestamp? // Use Timestamp? with @ServerTimestamp
    @ServerTimestamp var updatedAt: Timestamp? // Use Timestamp? with @ServerTimestamp

    // Remove ALL custom initializers and Codable methods.
    // Rely *entirely* on synthesized Codable conformance with the property wrappers.
}

/// Status of a playdate invitation
enum InvitationStatus: String, Codable {
    case pending
    case accepted
    case declined
}
