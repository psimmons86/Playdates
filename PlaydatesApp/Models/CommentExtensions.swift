import Foundation
import FirebaseFirestore

// MARK: - Helper Functions

public extension Comment {
    /// Creates a system comment
    static func system(message: String) -> Comment {
        return Comment(
            id: UUID().uuidString,
            userID: "system",
            text: message,
            createdAt: Date(),
            isSystem: true
        )
    }
    
    /// Creates a dictionary representation suitable for Firestore
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userID": userID,
            "text": text,
            "createdAt": Timestamp(date: createdAt),
            "isSystem": isSystem
        ]
    }
}
