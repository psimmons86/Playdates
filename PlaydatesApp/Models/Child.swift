import Foundation
import FirebaseFirestore

// This is a duplicate of the Child struct in User.swift
// It's kept here for reference, but the implementation in User.swift should be used
// to avoid conflicts.

/*
struct Child: Identifiable, Codable {
    var id = UUID().uuidString
    var name: String
    var age: Int
    @StoredOnHeap var interests: [String]?
    var parentID: String
    var allergies: [String]?
    var createdAt: Date

    // Custom initializer
    init(id: String = UUID().uuidString, name: String, age: Int, interests: [String]? = nil, 
         parentID: String, allergies: [String]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.age = age
        self._interests = StoredOnHeap(wrappedValue: interests)
        self.parentID = parentID
        self.allergies = allergies
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case interests
        case parentID
        case allergies
        case createdAt
    }

    // Custom decoder implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode id with fallback
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

        // Decode name
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
        } else if let nameNumber = try? container.decode(Int.self, forKey: .name) {
            name = String(nameNumber)
        } else {
            name = "Unknown"
        }

        // Decode age
        if let ageInt = try? container.decode(Int.self, forKey: .age) {
            age = ageInt
        } else if let ageString = try? container.decode(String.self, forKey: .age), let ageValue = Int(ageString) {
            age = ageValue
        } else if let ageDouble = try? container.decode(Double.self, forKey: .age) {
            age = Int(ageDouble)
        } else {
            age = 0
        }

        // Decode interests
        let rawInterests = try? container.decodeIfPresent([String].self, forKey: .interests)
        _interests = StoredOnHeap(wrappedValue: rawInterests)
        
        // Decode parentID
        if let parentIDString = try? container.decode(String.self, forKey: .parentID) {
            parentID = parentIDString
        } else {
            parentID = ""
        }
        
        // Decode allergies
        allergies = try container.decodeIfPresent([String].self, forKey: .allergies)
        
        // Decode createdAt
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
    }
    
    // Custom encoder implementation to handle property wrappers
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
        try container.encodeIfPresent(interests, forKey: .interests)
        try container.encode(parentID, forKey: .parentID)
        try container.encodeIfPresent(allergies, forKey: .allergies)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
*/

// Use the Child struct from User.swift to avoid conflicts
