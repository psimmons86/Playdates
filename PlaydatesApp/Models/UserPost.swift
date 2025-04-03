import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct UserPost: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let userID: String          // ID of the user who created the post
    var text: String            // Content of the post
    var imageURL: String?       // Optional image URL associated with the post
    let createdAt: Date         // Timestamp when the post was created
    var likes: [String] = []    // Array of user IDs who liked the post
    // Add other relevant fields like comments count, etc. if needed

    // Default initializer
    init(id: String? = nil, userID: String, text: String, imageURL: String? = nil, createdAt: Date = Date(), likes: [String] = []) {
        self.id = id
        self.userID = userID
        self.text = text
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.likes = likes
    }

    // Equatable conformance based on ID
    static func == (lhs: UserPost, rhs: UserPost) -> Bool {
        lhs.id == rhs.id && lhs.id != nil
    }

    // CodingKeys if needed (especially if Firestore field names differ)
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case text
        case imageURL
        case createdAt
        case likes
    }
}
