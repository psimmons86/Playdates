import Foundation
import SwiftUI

extension CommunityEventViewModel {
    /// Add mock data to the view model for testing and development
    func addMockData() {
        // Create mock user IDs
        let userIDs = [
            "user1", "user2", "user3", "user4", "user5",
            "user6", "user7", "user8", "user9", "user10"
        ]
        
        // Create mock locations
        let locations = [
            Location(
                name: "Central Park Playground",
                address: "100 Central Park Dr, San Francisco, CA",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            Location(
                name: "Community Center",
                address: "250 Main St, San Francisco, CA",
                latitude: 37.7833,
                longitude: -122.4167
            ),
            Location(
                name: "Lakeside Library",
                address: "500 Lake Ave, San Francisco, CA",
                latitude: 37.7695,
                longitude: -122.4529
            ),
            Location(
                name: "Children's Museum",
                address: "300 Museum Way, San Francisco, CA",
                latitude: 37.8030,
                longitude: -122.4378
            ),
            Location(
                name: "Sunshine Park",
                address: "123 Sunny Lane, San Francisco, CA",
                latitude: 37.7749,
                longitude: -122.4194
            )
        ]
        
        // Create mock events
        let mockEvents = [
            CommunityEvent(
                id: "event1",
                title: "Family Picnic Day",
                description: "Join us for a community picnic at Central Park! Bring your own food and blankets. We'll have games and activities for kids of all ages.",
                category: .playdate,
                location: locations[0],
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())?.addingTimeInterval(3 * 60 * 60) ?? Date(),
                organizerID: userIDs[0],
                attendeeIDs: [userIDs[0], userIDs[1], userIDs[2], userIDs[3], userIDs[4]],
                waitlistIDs: [userIDs[5], userIDs[6], userIDs[7]],
                maxAttendees: 50,
                isPublic: true,
                tags: ["picnic", "outdoor", "family", "games"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 10) // 10 days ago
            ),
            CommunityEvent(
                id: "event2",
                title: "Parent-Child Art Workshop",
                description: "A fun art workshop for parents and children to create together. All materials provided. Suitable for ages 3-8. Limited spots available!",
                category: .workshop,
                location: locations[1],
                startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                organizerID: userIDs[1],
                attendeeIDs: [userIDs[1], userIDs[3], userIDs[5], userIDs[7], userIDs[9]],
                waitlistIDs: [userIDs[0], userIDs[2]],
                maxAttendees: 20,
                isPublic: true,
                tags: ["art", "workshop", "creative", "parent-child"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 5) // 5 days ago
            ),
            CommunityEvent(
                id: "event3",
                title: "Storytime at Lakeside Library",
                description: "Weekly storytime session for preschoolers. Join us for stories, songs, and simple crafts. Free event, no registration required.",
                category: .education,
                location: locations[2],
                startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())?.addingTimeInterval(1 * 60 * 60) ?? Date(),
                organizerID: userIDs[2],
                attendeeIDs: [userIDs[2], userIDs[4], userIDs[6], userIDs[8]],
                waitlistIDs: [userIDs[1], userIDs[3], userIDs[5]],
                maxAttendees: 30,
                isPublic: true,
                tags: ["storytime", "library", "preschool", "reading"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 14) // 14 days ago
            ),
            CommunityEvent(
                id: "event4",
                title: "Museum Family Day",
                description: "Special family day at the Children's Museum with reduced admission for community members. Extra activities and demonstrations throughout the day.",
                category: .education,
                location: locations[3],
                startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())?.addingTimeInterval(8 * 60 * 60) ?? Date(),
                organizerID: userIDs[3],
                attendeeIDs: [userIDs[3], userIDs[0], userIDs[5], userIDs[8]],
                waitlistIDs: [userIDs[1], userIDs[2], userIDs[4], userIDs[6], userIDs[7], userIDs[9]],
                maxAttendees: 100,
                isPublic: true,
                tags: ["museum", "family day", "educational", "discount"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
            ),
            CommunityEvent(
                id: "event5",
                title: "Toddler Playgroup",
                description: "Weekly playgroup for toddlers ages 1-3. Unstructured play time for little ones to socialize while parents connect. Bring a snack to share!",
                category: .playdate,
                location: locations[4],
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                organizerID: userIDs[4],
                attendeeIDs: [userIDs[4], userIDs[1], userIDs[6], userIDs[9]],
                waitlistIDs: [userIDs[2], userIDs[7]],
                maxAttendees: 15,
                isPublic: true,
                tags: ["toddler", "playgroup", "1-3 years", "socialization"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 21) // 21 days ago
            ),
            CommunityEvent(
                id: "event6",
                title: "Parent Support Group",
                description: "Monthly meeting for parents to discuss challenges, share advice, and support each other. This month's topic: Managing Screen Time.",
                category: .other,
                location: locations[1],
                startDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())?.addingTimeInterval(1.5 * 60 * 60) ?? Date(),
                organizerID: userIDs[5],
                attendeeIDs: [userIDs[5], userIDs[0], userIDs[2], userIDs[7]],
                waitlistIDs: [userIDs[1], userIDs[3], userIDs[8]],
                maxAttendees: 20,
                isPublic: true,
                tags: ["support group", "parents", "discussion", "screen time"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3) // 3 days ago
            ),
            CommunityEvent(
                id: "event7",
                title: "Family Nature Walk",
                description: "Guided nature walk for families with children of all ages. Learn about local plants and wildlife. Easy walking pace suitable for young children.",
                category: .outdoors,
                location: locations[0],
                startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                organizerID: userIDs[6],
                attendeeIDs: [userIDs[6], userIDs[2], userIDs[4], userIDs[8]],
                waitlistIDs: [userIDs[0], userIDs[3], userIDs[5], userIDs[9]],
                maxAttendees: 25,
                isPublic: true,
                tags: ["nature", "outdoor", "walking", "family activity"],
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 6) // 6 days ago
            )
        ]
        
        // Add mock data to view model
        self.upcomingEvents = mockEvents
        self.userEvents = [mockEvents[0], mockEvents[2], mockEvents[4]] // Events the user is attending
        self.filteredEvents = mockEvents // Set filtered events to all events initially
        self.isLoading = false
    }
}
