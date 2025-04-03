import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

// Add Equatable conformance
public struct User: Identifiable, Codable, Equatable {
    @DocumentID public var id: String?
    public var name: String
    public var email: String
    public var profileImageURL: String? // Corrected property name casing
    public var bio: String?
    // Search-optimized fields
    public var name_lowercase: String?
    // Removed StoredOnHeap wrapper
    public var children: [PlaydateChild]? // Assuming PlaydateChild is defined elsewhere and is Codable/Equatable if needed
    public var friendIDs: [String]?
    public var friendRequestIDs: [String]?
    public var favoriteActivityIDs: [String]? // Added for favorite activities
    public var wantToDoActivityIDs: [String]? // Added for "want to do" activities
    public var createdAt: Date? // Make optional for flexibility
    public var lastActive: Date? // Make optional for flexibility

    // Custom initializer to ensure all properties are properly initialized
    // Keep this initializer for creating User objects manually in code
    public init(id: String? = nil, name: String, email: String, profileImageURL: String? = nil, bio: String? = nil,
         children: [PlaydateChild]? = nil, friendIDs: [String]? = nil, friendRequestIDs: [String]? = nil,
         favoriteActivityIDs: [String]? = nil, wantToDoActivityIDs: [String]? = nil, // Added to initializer
         createdAt: Date? = nil, lastActive: Date? = nil) { // Accept optional dates
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL // Corrected casing
        self.bio = bio
        self.children = children
        self.friendIDs = friendIDs
        self.friendRequestIDs = friendRequestIDs
        self.favoriteActivityIDs = favoriteActivityIDs // Initialize new property
        self.wantToDoActivityIDs = wantToDoActivityIDs // Initialize new property
        self.createdAt = createdAt
        self.lastActive = lastActive

        // Set search-optimized fields
        self.name_lowercase = name.lowercased()
    }

    // REMOVED custom CodingKeys, init(from decoder:), and encode(to encoder:)
    // Rely on synthesized Codable conformance provided by Swift and FirebaseFirestoreSwift
    // This allows @DocumentID to work correctly.

    // Equatable conformance: Compare based on ID
    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id && lhs.id != nil // Ensure IDs are non-nil for equality
    }
}

// Removed placeholder PlaydateChild struct definition as it likely exists elsewhere (e.g., Child.swift)
// Ensure the actual PlaydateChild struct conforms to Codable and Equatable if required by User's conformance.
