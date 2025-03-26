import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import CoreLocation

struct Playdate: Identifiable, Codable {
    @DocumentID var id: String?
    var hostID: String
    var title: String
    var description: String?
    var activityType: String?
    @StoredOnHeap var location: Location?
    var address: String?
    var startDate: Date
    var endDate: Date
    var minAge: Int?
    var maxAge: Int?
    @StoredOnHeap var attendeeIDs: [String]
    var isPublic: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case hostID
        case title
        case description
        case activityType
        case location
        case address
        case startDate
        case endDate
        case minAge
        case maxAge
        case attendeeIDs
        case isPublic
        case createdAt
    }

    // Minimal initializer for when we only have basic info
    init(id: String? = nil, hostID: String, title: String) {
        self.id = id
        self.hostID = hostID
        self.title = title
        self.description = nil
        self.activityType = nil
        self._location = StoredOnHeap(wrappedValue: nil)
        self.address = nil
        self.startDate = Date()
        self.endDate = Date(timeIntervalSinceNow: 3600) // 1 hour later
        self.minAge = nil
        self.maxAge = nil
        self._attendeeIDs = StoredOnHeap(wrappedValue: [])
        self.isPublic = false
        self.createdAt = Date()
    }

    // Full initializer with all parameters
    init(id: String? = nil, hostID: String, title: String, description: String? = nil,
         activityType: String? = nil, location: Location? = nil, address: String? = nil,
         startDate: Date = Date(), endDate: Date = Date(timeIntervalSinceNow: 3600),
         minAge: Int? = nil, maxAge: Int? = nil, attendeeIDs: [String] = [],
         isPublic: Bool = false, createdAt: Date = Date()) {

        self.id = id
        self.hostID = hostID
        self.title = title
        self.description = description
        self.activityType = activityType
        self._location = StoredOnHeap(wrappedValue: location)
        self.address = address
        self.startDate = startDate
        self.endDate = endDate
        self.minAge = minAge
        self.maxAge = maxAge
        self._attendeeIDs = StoredOnHeap(wrappedValue: attendeeIDs)
        self.isPublic = isPublic
        self.createdAt = createdAt
    }

    // Custom decoder implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID
        id = try container.decodeIfPresent(String.self, forKey: .id)

        // Decode hostID safely
        if let hostIDString = try? container.decode(String.self, forKey: .hostID) {
            hostID = hostIDString
        } else if let hostIDNumber = try? container.decode(Int.self, forKey: .hostID) {
            hostID = String(hostIDNumber)
        } else {
            hostID = "unknown"
        }

        // Decode title safely
        if let titleString = try? container.decode(String.self, forKey: .title) {
            title = titleString
        } else if let titleNumber = try? container.decode(Int.self, forKey: .title) {
            title = String(titleNumber)
        } else {
            title = "Untitled Playdate"
        }

        // Decode optional string fields
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        activityType = try? container.decodeIfPresent(String.self, forKey: .activityType)
        address = try? container.decodeIfPresent(String.self, forKey: .address)

        // Decode location - Use try-catch to handle potential decoding errors
        do {
            let decodedLocation = try container.decodeIfPresent(Location.self, forKey: .location)
            _location = StoredOnHeap(wrappedValue: decodedLocation)
        } catch {
            // If there's an error decoding the location set it to nil
            _location = StoredOnHeap(wrappedValue: nil)
        }

        // Decode dates with fallbacks
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) ?? Date(timeIntervalSinceNow: 3600)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()

        // Decode arrays safely
        let decodedAttendeeIDs = try Self.decodeStringArray(from: container, forKey: .attendeeIDs) ?? []
        _attendeeIDs = StoredOnHeap(wrappedValue: decodedAttendeeIDs)

        // Decode optional int fields
        minAge = try? container.decodeIfPresent(Int.self, forKey: .minAge)
        maxAge = try? container.decodeIfPresent(Int.self, forKey: .maxAge)

        // Decode boolean fields safely
        if let publicBool = try? container.decode(Bool.self, forKey: .isPublic) {
            isPublic = publicBool
        } else if let publicInt = try? container.decode(Int.self, forKey: .isPublic) {
            isPublic = publicInt != 0
        } else {
            isPublic = false // Default
        }
    }

    // Explicit encoder implementation to ensure proper Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode ID if present
        try container.encodeIfPresent(id, forKey: .id)

        // Encode required fields
        try container.encode(hostID, forKey: .hostID)
        try container.encode(title, forKey: .title)

        // Encode optional fields
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(activityType, forKey: .activityType)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(address, forKey: .address)

        // Encode dates
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(createdAt, forKey: .createdAt)

        // Encode optional numeric fields
        try container.encodeIfPresent(minAge, forKey: .minAge)
        try container.encodeIfPresent(maxAge, forKey: .maxAge)

        // Encode arrays and boolean
        try container.encode(attendeeIDs, forKey: .attendeeIDs)
        try container.encode(isPublic, forKey: .isPublic)
    }

    // Helper method to safely decode string arrays
    private static func decodeStringArray(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> [String]? {
        // Try decoding as [String] first
        if let values = try? container.decodeIfPresent([String].self, forKey: key) {
            return values
        }

        // Try decoding as [Int] and converting
        if let values = try? container.decodeIfPresent([Int].self, forKey: key) {
            return values.map { String($0) }
        }

        // Return empty array if key doesn't exist or has null value
        return []
    }
}
