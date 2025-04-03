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
    var location: Location? // Removed @StoredOnHeap
    var address: String?
    var startDate: Date
    var endDate: Date
    var minAge: Int?
    var maxAge: Int?
    var attendeeIDs: [String] // Removed @StoredOnHeap
    var isPublic: Bool = false // Provide default
    @ServerTimestamp var createdAt: Timestamp? // Use @ServerTimestamp for consistency
    var photoURLs: [String]? // Added for storing photo URLs
    var taggedFriendIDs: [String]? // Added for tagging friends

    // Remove CodingKeys enum and custom Codable implementation
    // Rely on synthesized Codable + @DocumentID + @ServerTimestamp

    // Minimal initializer (remove createdAt)
    init(id: String? = nil, hostID: String, title: String) {
        self.id = id
        self.hostID = hostID
        self.title = title
        self.description = nil
        self.activityType = nil
        self.location = nil
        self.address = nil
        self.startDate = Date()
        self.endDate = Date(timeIntervalSinceNow: 3600) // 1 hour later
        self.minAge = nil
        self.maxAge = nil
        self.attendeeIDs = []
        self.isPublic = false
        // createdAt is handled by @ServerTimestamp
    }

    // Full initializer (remove createdAt)
    init(id: String? = nil, hostID: String, title: String, description: String? = nil,
         activityType: String? = nil, location: Location? = nil, address: String? = nil,
         startDate: Date = Date(), endDate: Date = Date(timeIntervalSinceNow: 3600),
         minAge: Int? = nil, maxAge: Int? = nil, attendeeIDs: [String] = [],
         isPublic: Bool = false, /* Remove createdAt */
         photoURLs: [String]? = nil, taggedFriendIDs: [String]? = nil) {

        self.id = id
        self.hostID = hostID
        self.title = title
        self.description = description
        self.activityType = activityType
        self.location = location
        self.address = address
        self.startDate = startDate
        self.endDate = endDate
        self.minAge = minAge
        self.maxAge = maxAge
        self.attendeeIDs = attendeeIDs
        self.isPublic = isPublic
        // createdAt is handled by @ServerTimestamp
        self.photoURLs = photoURLs
        self.taggedFriendIDs = taggedFriendIDs
    }
}
