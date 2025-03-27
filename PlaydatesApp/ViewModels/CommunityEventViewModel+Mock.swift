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

        // Create mock events with corrected parameters and order
        let mockEvents = [
            CommunityEvent(
                id: "event1",
                title: "Family Picnic Day",
                description: "Join us for a community picnic at Central Park! Bring your own food and blankets. We'll have games and activities for kids of all ages.",
                category: .playdate,
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())?.addingTimeInterval(3 * 60 * 60) ?? Date(),
                location: locations[0],
                address: locations[0].address, // Use address from location
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 50,
                attendeeIDs: [userIDs[0], userIDs[1], userIDs[2], userIDs[3], userIDs[4]],
                waitlistIDs: [userIDs[5], userIDs[6], userIDs[7]],
                organizerID: userIDs[0],
                // organizerName: nil, (omitted)
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                // recurrencePattern: .none, (omitted - default)
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: nil, // Free event
                isFree: true,
                // ageMin: nil, (omitted)
                // ageMax: nil, (omitted)
                tags: ["picnic", "outdoor", "family", "games"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 10) // 10 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event2",
                title: "Parent-Child Art Workshop",
                description: "A fun art workshop for parents and children to create together. All materials provided. Suitable for ages 3-8. Limited spots available!",
                category: .workshop,
                startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                location: locations[1],
                address: locations[1].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 20,
                attendeeIDs: [userIDs[1], userIDs[3], userIDs[5], userIDs[7], userIDs[9]],
                waitlistIDs: [userIDs[0], userIDs[2]],
                organizerID: userIDs[1],
                // organizerName: nil, (omitted)
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                // recurrencePattern: .none, (omitted - default)
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: 10.00, // Example cost
                isFree: false,
                ageMin: 3,
                ageMax: 8,
                tags: ["art", "workshop", "creative", "parent-child"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 5) // 5 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event3",
                title: "Storytime at Lakeside Library",
                description: "Weekly storytime session for preschoolers. Join us for stories, songs, and simple crafts. Free event, no registration required.",
                category: .education,
                startDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())?.addingTimeInterval(1 * 60 * 60) ?? Date(),
                location: locations[2],
                address: locations[2].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 30,
                attendeeIDs: [userIDs[2], userIDs[4], userIDs[6], userIDs[8]],
                waitlistIDs: [userIDs[1], userIDs[3], userIDs[5]],
                organizerID: userIDs[2], // Assuming library staff user ID
                organizerName: "Lakeside Library", // Example name
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                recurrencePattern: .weekly, // Example recurrence
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: nil,
                isFree: true,
                ageMin: 2, // Example age
                ageMax: 5, // Example age
                tags: ["storytime", "library", "preschool", "reading"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 14) // 14 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event4",
                title: "Museum Family Day",
                description: "Special family day at the Children's Museum with reduced admission for community members. Extra activities and demonstrations throughout the day.",
                category: .education,
                startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())?.addingTimeInterval(8 * 60 * 60) ?? Date(),
                location: locations[3],
                address: locations[3].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 100,
                attendeeIDs: [userIDs[3], userIDs[0], userIDs[5], userIDs[8]],
                waitlistIDs: [userIDs[1], userIDs[2], userIDs[4], userIDs[6], userIDs[7], userIDs[9]],
                organizerID: userIDs[3], // Assuming museum staff user ID
                organizerName: "Children's Museum", // Example name
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                // recurrencePattern: .none, (omitted - default)
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: 5.00, // Reduced admission
                isFree: false,
                // ageMin: nil, (omitted)
                // ageMax: nil, (omitted)
                tags: ["museum", "family day", "educational", "discount"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event5",
                title: "Toddler Playgroup",
                description: "Weekly playgroup for toddlers ages 1-3. Unstructured play time for little ones to socialize while parents connect. Bring a snack to share!",
                category: .playdate,
                startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                location: locations[4],
                address: locations[4].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 15,
                attendeeIDs: [userIDs[4], userIDs[1], userIDs[6], userIDs[9]],
                waitlistIDs: [userIDs[2], userIDs[7]],
                organizerID: userIDs[4],
                // organizerName: nil, (omitted)
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                recurrencePattern: .weekly, // Example recurrence
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: nil,
                isFree: true,
                ageMin: 1,
                ageMax: 3,
                tags: ["toddler", "playgroup", "1-3 years", "socialization"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 21) // 21 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event6",
                title: "Parent Support Group",
                description: "Monthly meeting for parents to discuss challenges, share advice, and support each other. This month's topic: Managing Screen Time.",
                category: .other,
                startDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())?.addingTimeInterval(1.5 * 60 * 60) ?? Date(),
                location: locations[1],
                address: locations[1].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 20,
                attendeeIDs: [userIDs[5], userIDs[0], userIDs[2], userIDs[7]],
                waitlistIDs: [userIDs[1], userIDs[3], userIDs[8]],
                organizerID: userIDs[5],
                // organizerName: nil, (omitted)
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                recurrencePattern: .monthly, // Example recurrence
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: nil,
                isFree: true,
                // ageMin: nil, (omitted)
                // ageMax: nil, (omitted)
                tags: ["support group", "parents", "discussion", "screen time"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3) // 3 days ago
                // updatedAt: nil (omitted - default)
            ),
            CommunityEvent(
                id: "event7",
                title: "Family Nature Walk",
                description: "Guided nature walk for families with children of all ages. Learn about local plants and wildlife. Easy walking pace suitable for young children.",
                category: .outdoors,
                startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())?.addingTimeInterval(2 * 60 * 60) ?? Date(),
                location: locations[0],
                address: locations[0].address,
                isVirtual: false,
                // virtualMeetingURL: nil, (omitted)
                coverImageURL: nil,
                maxCapacity: 25,
                attendeeIDs: [userIDs[6], userIDs[2], userIDs[4], userIDs[8]],
                waitlistIDs: [userIDs[0], userIDs[3], userIDs[5], userIDs[9]],
                organizerID: userIDs[6],
                // organizerName: nil, (omitted)
                // sponsoringOrganization: nil, (omitted)
                isPublic: true,
                // invitedGroupIDs: [], (omitted - default)
                // recurrencePattern: .none, (omitted - default)
                // recurrenceEndDate: nil, (omitted)
                // parentEventID: nil, (omitted)
                cost: nil,
                isFree: true,
                // ageMin: nil, (omitted)
                // ageMax: nil, (omitted)
                tags: ["nature", "outdoor", "walking", "family activity"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 6) // 6 days ago
                // updatedAt: nil (omitted - default)
            )
        ]

        // Add mock data to view model
        self.upcomingEvents = mockEvents
        self.userEvents = [mockEvents[0], mockEvents[2], mockEvents[4]] // Events the user is attending
        self.filteredEvents = mockEvents // Set filtered events to all events initially
        self.isLoading = false
    }
}
