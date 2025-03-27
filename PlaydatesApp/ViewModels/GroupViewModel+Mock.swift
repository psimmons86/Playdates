import Foundation
import SwiftUI

extension GroupViewModel {
    /// Add mock data to the view model for testing and development
    func addMockData() {
        // Create mock user IDs
        let userIDs = [
            "user1", "user2", "user3", "user4", "user5",
            "user6", "user7", "user8", "user9", "user10"
        ]
        
        // Create mock groups
        let mockGroups = [
            Group(
                id: "group1",
                name: "Lake School Parents",
                description: "Play dates for Lake School Friends & Families. Share resources, organize events, and connect with other parents.",
                groupType: .school,
                privacyType: .public,
                location: nil,
                coverImageURL: nil,
                memberIDs: Array(userIDs.prefix(8)),
                adminIDs: [userIDs[0], userIDs[1]],
                moderatorIDs: [userIDs[2]],
                pendingMemberIDs: [],
                tags: ["elementary school", "lake district", "parents"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 30), // 30 days ago
                createdBy: userIDs[0],
                allowMemberPosts: true,
                requirePostApproval: false,
                allowEvents: true,
                allowResourceSharing: true
            ),
            Group(
                id: "group2",
                name: "Downtown Neighborhood",
                description: "Connect with families in the downtown area. Organize playdates, share local events, and build community.",
                groupType: .neighborhood,
                privacyType: .public,
                location: nil,
                coverImageURL: nil,
                memberIDs: Array(userIDs.prefix(6)),
                adminIDs: [userIDs[1]],
                moderatorIDs: [],
                pendingMemberIDs: [],
                tags: ["downtown", "urban families", "city center"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 45), // 45 days ago
                createdBy: userIDs[1],
                allowMemberPosts: true,
                requirePostApproval: false,
                allowEvents: true,
                allowResourceSharing: true
            ),
            Group(
                id: "group3",
                name: "Toddler Activities",
                description: "Share and discover activities for toddlers aged 1-3. Exchange ideas, recommendations, and organize group activities.",
                groupType: .ageBased,
                privacyType: .public,
                location: nil,
                coverImageURL: nil,
                memberIDs: Array(userIDs.prefix(10)),
                adminIDs: [userIDs[2]],
                moderatorIDs: [userIDs[3], userIDs[4]],
                pendingMemberIDs: [],
                tags: ["toddlers", "1-3 years", "activities"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 15), // 15 days ago
                createdBy: userIDs[2],
                allowMemberPosts: true,
                requirePostApproval: true,
                allowEvents: true,
                allowResourceSharing: true
            ),
            Group(
                id: "group4",
                name: "Outdoor Adventures",
                description: "For families who love outdoor activities. Hiking, camping, nature walks, and more. Share your experiences and plan group outings.",
                groupType: .interestBased,
                privacyType: .public,
                location: nil,
                coverImageURL: nil,
                memberIDs: [userIDs[0], userIDs[2], userIDs[4], userIDs[6], userIDs[8]],
                adminIDs: [userIDs[0]],
                moderatorIDs: [],
                pendingMemberIDs: [],
                tags: ["outdoors", "hiking", "camping", "nature"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 60), // 60 days ago
                createdBy: userIDs[0],
                allowMemberPosts: true,
                requirePostApproval: false,
                allowEvents: true,
                allowResourceSharing: true
            ),
            Group(
                id: "group5",
                name: "Arts & Crafts Club",
                description: "Share creative projects, art supplies, and organize craft sessions for kids. All ages welcome!",
                groupType: .interestBased,
                privacyType: .public,
                location: nil,
                coverImageURL: nil,
                memberIDs: [userIDs[1], userIDs[3], userIDs[5], userIDs[7], userIDs[9]],
                adminIDs: [userIDs[1]],
                moderatorIDs: [userIDs[3]],
                pendingMemberIDs: [],
                tags: ["arts", "crafts", "creativity", "kids activities"],
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 20), // 20 days ago
                createdBy: userIDs[1],
                allowMemberPosts: true,
                requirePostApproval: false,
                allowEvents: true,
                allowResourceSharing: true
            )
        ]
        
        // Create mock posts
        let mockPosts = [
            GroupPost(
                id: "post1",
                groupID: "group1",
                authorID: userIDs[0],
                content: "Welcome to our Lake School Parents group! This is a space for us to connect, share resources, and organize playdates for our kids. Feel free to introduce yourselves!",
                mediaURLs: [],
                status: .published,
                isPinned: true,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 29), // 29 days ago
                likedByIDs: [userIDs[1], userIDs[2], userIDs[3]],
                commentIDs: ["comment1", "comment2"]
            ),
            GroupPost(
                id: "post2",
                groupID: "group1",
                authorID: userIDs[1],
                content: "We're organizing a playdate at Central Park this Saturday at 2pm. Who's interested in joining?",
                mediaURLs: [],
                status: .published,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 5), // 5 days ago
                isPoll: true,
                likedByIDs: [userIDs[0], userIDs[2], userIDs[4], userIDs[5]],
                commentIDs: ["comment3", "comment4", "comment5"],
                pollOptions: [
                    PollOption(id: "option1", text: "We'll be there!", votedByIDs: [userIDs[0], userIDs[4]]),
                    PollOption(id: "option2", text: "Can't make it this time", votedByIDs: [userIDs[2]]),
                    PollOption(id: "option3", text: "Maybe, will confirm later", votedByIDs: [userIDs[5]])
                ]
            ),
            GroupPost(
                id: "post3",
                groupID: "group2",
                authorID: userIDs[1],
                content: "Has anyone tried the new playground on Main Street? Is it suitable for toddlers?",
                mediaURLs: [],
                status: .published,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3), // 3 days ago
                likedByIDs: [userIDs[3], userIDs[5]],
                commentIDs: ["comment6"]
            ),
            GroupPost(
                id: "post4",
                groupID: "group3",
                authorID: userIDs[2],
                content: "Sharing a great activity for developing fine motor skills: Fill a container with dried beans or rice and hide small toys in it. Let your toddler use a spoon or their hands to find the toys!",
                mediaURLs: [],
                status: .published,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 10), // 10 days ago
                likedByIDs: [userIDs[0], userIDs[1], userIDs[3], userIDs[4], userIDs[5], userIDs[6]],
                commentIDs: ["comment7", "comment8"]
            ),
            GroupPost(
                id: "post5",
                groupID: "group4",
                authorID: userIDs[0],
                content: "We had an amazing hike at Eagle Mountain last weekend. The trail was easy enough for our 5-year-old to manage. Highly recommend for families with young kids!",
                mediaURLs: [],
                status: .published,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 7), // 7 days ago
                likedByIDs: [userIDs[2], userIDs[4], userIDs[6], userIDs[8]],
                commentIDs: ["comment9", "comment10"]
            )
        ]
        
        // Add mock data to view model
        self.userGroups = mockGroups
        self.nearbyGroups = [mockGroups[1], mockGroups[3]] // Downtown and Outdoor groups
        self.recommendedGroups = [mockGroups[2], mockGroups[4]] // Toddler and Arts groups
        self.groupPosts = mockPosts
        self.isLoading = false
    }
}
