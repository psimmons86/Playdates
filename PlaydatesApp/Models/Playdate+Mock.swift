import Foundation
import FirebaseFirestore

extension Playdate {
    static var mock: Playdate {
        Playdate(
            id: "mock-playdate-id",
            hostID: "mock-host-id",
            title: "Playground Fun",
            description: "Let's meet at the playground for some fun outdoor activities!",
            activityType: "outdoor",
            location: Location(
                id: "mock-location-id",
                name: "Central Park Playground",
                address: "123 Park Avenue, New York, NY",
                latitude: 40.7812,
                longitude: -73.9665
            ),
            address: "123 Park Avenue, New York, NY",
            startDate: Date().addingTimeInterval(3600), // 1 hour from now
            endDate: Date().addingTimeInterval(7200),   // 2 hours from now
            attendeeIDs: ["mock-host-id", "mock-attendee-1", "mock-attendee-2"],
            isPublic: true,
            createdAt: Date().addingTimeInterval(-86400) // 1 day ago
        )
    }
}

extension User {
    static var mockHost: User {
        User(
            id: "mock-host-id",
            name: "Jane Smith",
            email: "jane@example.com",
            profileImageURL: "https://example.com/profile.jpg",
            bio: "Parent of two lovely kids who enjoy outdoor activities",
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            lastActive: Date()
        )
    }
    
    static var mockAttendee: User {
        User(
            id: "mock-attendee-1",
            name: "John Doe",
            email: "john@example.com",
            profileImageURL: nil,
            bio: "Father of a 5-year-old boy",
            createdAt: Date().addingTimeInterval(-86400 * 20), // 20 days ago
            lastActive: Date().addingTimeInterval(-3600) // 1 hour ago
        )
    }
}

extension Comment {
    static var mockComment: Comment {
        Comment(
            id: "mock-comment-id",
            userID: "mock-attendee-1",
            text: "Looking forward to this playdate!",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            isSystem: false
        )
    }
    
    static var mockSystemComment: Comment {
        Comment(
            id: "mock-system-comment-id",
            userID: "system",
            text: "John Doe joined the playdate",
            createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
            isSystem: true
        )
    }
}

extension CommentWithUser {
    static var mockCommentWithUser: CommentWithUser {
        CommentWithUser(
            comment: .mockComment,
            user: .mockAttendee
        )
    }
    
    static var mockSystemCommentWithUser: CommentWithUser {
        CommentWithUser(
            comment: .mockSystemComment,
            user: User(
                id: "system",
                name: "System",
                email: "",
                profileImageURL: nil,
                createdAt: Date(),
                lastActive: Date()
            )
        )
    }
}
