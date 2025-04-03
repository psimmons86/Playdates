import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift // Required for @DocumentID

struct CheckIn: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    let activityID: String      // ID of the Activity checked into
    let activityName: String    // Name of the activity (for display)
    let userID: String          // ID of the user who checked in
    let userName: String        // Name of the user (for display)
    let userProfileImageURL: String? // Profile image URL of the user (for display)
    let timestamp: Timestamp    // Time of the check-in
    var comment: String?        // Optional user comment
    var photoURLs: [String]?    // Optional URLs of uploaded photos (in Firebase Storage)
    var taggedUserIDs: [String]? // Optional IDs of users tagged in this check-in

    // CodingKeys for mapping Firestore field names if needed (optional for exact matches)
    enum CodingKeys: String, CodingKey {
        case id
        case activityID
        case activityName
        case userID
        case userName
        case userProfileImageURL
        case timestamp
        case comment
        case photoURLs
        case taggedUserIDs
    }
}
