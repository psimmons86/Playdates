import Foundation
import SwiftUI

extension ResourceViewModel {
    /// Add mock data to the view model for testing and development
    func addMockData() {
        // Create mock user IDs
        let userIDs = [
            "user1", "user2", "user3", "user4", "user5",
            "user6", "user7", "user8", "user9", "user10"
        ]
        
        // Create mock resources
        let mockResources = [
            SharedResource(
                id: "resource1",
                title: "Double Stroller - Free to Borrow",
                description: "City Mini GT2 double stroller available to borrow for up to 2 weeks. Perfect for travel or if you have visitors with kids. Good condition, easy to fold.",
                resourceType: .physicalItem,
                ownerID: userIDs[0],
                tags: ["stroller", "baby gear", "double stroller"],
                isFree: true,
                price: nil,
                isNegotiable: false,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "Downtown",
                    address: "123 Main St, Downtown",
                    latitude: 37.7749,
                    longitude: -122.4194
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 5) // 5 days ago
            ),
            SharedResource(
                id: "resource2",
                title: "Swim Instructor Recommendation",
                description: "We've been taking lessons with Ms. Sarah at Aquatic Center for 6 months and she's amazing with anxious kids. Our 4-year-old went from terrified to swimming independently. Highly recommend!",
                resourceType: .recommendation,
                ownerID: userIDs[1],
                tags: ["swimming", "lessons", "instructor", "water safety"],
                isFree: true,
                price: nil,
                isNegotiable: false,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "Aquatic Center",
                    address: "500 Pool Ave, Lakeside",
                    latitude: 37.7833,
                    longitude: -122.4167
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 10) // 10 days ago
            ),
            SharedResource(
                id: "resource3",
                title: "Kids' Books Bundle - Ages 3-5",
                description: "Selling a bundle of 15 picture books in excellent condition. Titles include several Dr. Seuss, Eric Carle, and popular characters. Great for preschoolers.",
                resourceType: .physicalItem,
                ownerID: userIDs[2],
                tags: ["books", "children's books", "picture books", "preschool"],
                isFree: false,
                price: 25.00,
                isNegotiable: true,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "Parkside",
                    address: "789 Park Blvd, Parkside",
                    latitude: 37.7695,
                    longitude: -122.4529
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3) // 3 days ago
            ),
            SharedResource(
                id: "resource4",
                title: "Free Educational Printables Website",
                description: "Just discovered this amazing website with free printable worksheets, activities, and learning materials for ages 2-10. They have everything from letter tracing to science experiments. www.learningprintables.com",
                resourceType: .educationalResource,
                ownerID: userIDs[3],
                tags: ["education", "printables", "worksheets", "homeschool", "activities"],
                isFree: true,
                price: nil,
                isNegotiable: false,
                availabilityStatus: .available,
                isAvailable: true,
                location: nil,
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
            ),
            SharedResource(
                id: "resource5",
                title: "Looking for Carpool Partner - Lake School",
                description: "We live in the Marina district and are looking for another family to share school drop-off/pick-up duties for Lake School (kindergarten). We can drive Mon/Wed, looking for Tue/Thu coverage.",
                resourceType: .carpoolOffer,
                ownerID: userIDs[4],
                tags: ["carpool", "Lake School", "kindergarten", "Marina district"],
                isFree: true,
                price: nil,
                isNegotiable: false,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "Marina District",
                    address: "Marina District, San Francisco",
                    latitude: 37.8030,
                    longitude: -122.4378
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 2) // 2 days ago
            ),
            SharedResource(
                id: "resource6",
                title: "Experienced Babysitter Available",
                description: "College student with 5+ years of childcare experience available for babysitting. CPR certified, experience with all ages from infants to pre-teens. Available evenings and weekends. References available.",
                resourceType: .serviceProvider,
                ownerID: userIDs[5],
                tags: ["babysitter", "childcare", "evening care", "weekend care"],
                isFree: false,
                price: 20.00,
                isNegotiable: false,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "University Area",
                    address: "University District",
                    latitude: 37.7749,
                    longitude: -122.4194
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 1) // 1 day ago
            ),
            SharedResource(
                id: "resource7",
                title: "Kids' Bike - 16 inch - Good Condition",
                description: "16-inch children's bike in good condition. Suitable for 4-6 year olds. Training wheels included but removable. Blue color with dinosaur design.",
                resourceType: .classifiedAd,
                ownerID: userIDs[6],
                tags: ["bike", "bicycle", "kids bike", "16 inch", "training wheels"],
                isFree: false,
                price: 45.00,
                isNegotiable: true,
                availabilityStatus: .available,
                isAvailable: true,
                location: Location(
                    name: "Richmond District",
                    address: "Richmond District, San Francisco",
                    latitude: 37.7749,
                    longitude: -122.4194
                ),
                coverImageURL: nil,
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 4) // 4 days ago
            )
        ]
        
        // Add mock data to view model
        self.availableResources = mockResources
        self.filteredResources = mockResources
        self.userResources = [mockResources[0], mockResources[2], mockResources[4]] // Some resources owned by the current user
        self.isLoading = false
    }
}
