import Foundation
import Firebase
import FirebaseFirestoreSwift

public struct PlaydateChild: Identifiable, Codable, Equatable {
    @DocumentID public var id: String?
    public var name: String
    public var age: Int
    public var gender: String?
    public var interests: [String]
    public var parentID: String
    public var createdAt: Date? // Made optional
    public var updatedAt: Date? // Made optional
    
    // Removed explicit CodingKeys to rely on synthesized Codable
    
    public init(id: String? = nil, 
         name: String, 
         age: Int, 
         gender: String? = nil, 
         interests: [String] = [], 
         parentID: String,
         createdAt: Date? = nil, // Accept optional Date, default to nil
         updatedAt: Date? = nil) { // Accept optional Date, default to nil
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.interests = interests
        self.parentID = parentID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static func == (lhs: PlaydateChild, rhs: PlaydateChild) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Mock data for previews and testing
    public static var mockChildren: [PlaydateChild] = [
        PlaydateChild(id: "child1", name: "Emma", age: 5, gender: "female", interests: ["Drawing", "Swimming"], parentID: "user1"),
        PlaydateChild(id: "child2", name: "Noah", age: 7, gender: "male", interests: ["Soccer", "Dinosaurs"], parentID: "user1"),
        PlaydateChild(id: "child3", name: "Olivia", age: 4, gender: "female", interests: ["Dancing", "Puzzles"], parentID: "user2")
    ]
}

// Removed typealias Child = PlaydateChild to resolve ambiguity.
// Use PlaydateChild directly throughout the project.
