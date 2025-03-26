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
    public var createdAt: Date
    public var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case gender
        case interests
        case parentID
        case createdAt
        case updatedAt
    }
    
    public init(id: String? = nil, 
         name: String, 
         age: Int, 
         gender: String? = nil, 
         interests: [String] = [], 
         parentID: String,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
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

// For backward compatibility
public typealias Child = PlaydateChild
