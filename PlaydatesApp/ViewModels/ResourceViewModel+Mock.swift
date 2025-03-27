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

        // Create mock locations (needed for some resources)
        let downtownLocation = Location(
            name: "Downtown",
            address: "123 Main St, Downtown",
            latitude: 37.7749,
            longitude: -122.4194
        )
        let aquaticCenterLocation = Location(
            name: "Aquatic Center",
            address: "500 Pool Ave, Lakeside",
            latitude: 37.7833,
            longitude: -122.4167
        )
        let parksideLocation = Location(
            name: "Parkside",
            address: "789 Park Blvd, Parkside",
            latitude: 37.7695,
            longitude: -122.4529
        )
        let marinaLocation = Location(
            name: "Marina District",
            address: "Marina District, San Francisco",
            latitude: 37.8030,
            longitude: -122.4378
        )
        let universityLocation = Location(
            name: "University Area",
            address: "University District",
            latitude: 37.7749,
            longitude: -122.4194
        )
        let richmondLocation = Location(
            name: "Richmond District",
            address: "Richmond District, San Francisco",
            latitude: 37.7749,
            longitude: -122.4194
        )

        // Create mock resources with corrected parameter order
        let mockResources = [
            SharedResource(
                id: "resource1",
                title: "Double Stroller - Free to Borrow",
                description: "City Mini GT2 double stroller available to borrow for up to 2 weeks. Perfect for travel or if you have visitors with kids. Good condition, easy to fold.",
                resourceType: .physicalItem,
                ownerID: userIDs[0],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                condition: "Good", // Example condition
                availabilityStatus: .available,
                // reservationHistory: nil, (omitted)
                location: downtownLocation,
                // address: nil, (omitted, derived from location)
                // contactInfo: nil, (omitted)
                // website: nil, (omitted)
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: nil,
                isFree: true,
                isNegotiable: false,
                // carpool/educational fields omitted
                tags: ["stroller", "baby gear", "double stroller"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 5) // 5 days ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource2",
                title: "Swim Instructor Recommendation",
                description: "We've been taking lessons with Ms. Sarah at Aquatic Center for 6 months and she's amazing with anxious kids. Our 4-year-old went from terrified to swimming independently. Highly recommend!",
                resourceType: .recommendation,
                ownerID: userIDs[1],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                // condition: nil, (omitted)
                availabilityStatus: .available, // Recommendations are always 'available' conceptually
                // reservationHistory: nil, (omitted)
                location: aquaticCenterLocation,
                // address: nil, (omitted)
                contactInfo: "Ms. Sarah - 555-1234", // Example contact
                website: "www.aquaticcenter.com", // Example website
                rating: 5.0, // Example rating
                // reviews: nil, (omitted)
                price: nil, // Recommendations are free
                isFree: true,
                isNegotiable: false,
                // carpool/educational fields omitted
                tags: ["swimming", "lessons", "instructor", "water safety"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 10) // 10 days ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource3",
                title: "Kids' Books Bundle - Ages 3-5",
                description: "Selling a bundle of 15 picture books in excellent condition. Titles include several Dr. Seuss, Eric Carle, and popular characters. Great for preschoolers.",
                resourceType: .physicalItem, // Changed to physicalItem as it's being sold
                ownerID: userIDs[2],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                condition: "Excellent", // Example condition
                availabilityStatus: .available,
                // reservationHistory: nil, (omitted)
                location: parksideLocation,
                // address: nil, (omitted)
                // contactInfo: nil, (omitted)
                // website: nil, (omitted)
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: 25.00,
                isFree: false,
                isNegotiable: true,
                // carpool/educational fields omitted
                tags: ["books", "children's books", "picture books", "preschool"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 3) // 3 days ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource4",
                title: "Free Educational Printables Website",
                description: "Just discovered this amazing website with free printable worksheets, activities, and learning materials for ages 2-10. They have everything from letter tracing to science experiments. www.learningprintables.com",
                resourceType: .educationalResource,
                ownerID: userIDs[3],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                // condition: nil, (omitted)
                availabilityStatus: .available, // Educational resources are typically always available
                // reservationHistory: nil, (omitted)
                location: nil, // No physical location
                // address: nil, (omitted)
                // contactInfo: nil, (omitted)
                website: "www.learningprintables.com", // Website is relevant here
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: nil,
                isFree: true,
                isNegotiable: false,
                // carpool fields omitted
                // fileURL: "www.learningprintables.com", // Can be same as website or specific file
                // fileType: "website", // Example
                ageRangeMin: 2,
                ageRangeMax: 10,
                tags: ["education", "printables", "worksheets", "homeschool", "activities"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 7) // 7 days ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource5",
                title: "Looking for Carpool Partner - Lake School",
                description: "We live in the Marina district and are looking for another family to share school drop-off/pick-up duties for Lake School (kindergarten). We can drive Mon/Wed, looking for Tue/Thu coverage.",
                resourceType: .carpoolOffer,
                ownerID: userIDs[4],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                // condition: nil, (omitted)
                availabilityStatus: .available, // Carpool offer is available until filled/expired
                // reservationHistory: nil, (omitted)
                // location: nil, (omitted - use start/end)
                // address: nil, (omitted)
                // contactInfo: nil, (omitted)
                // website: nil, (omitted)
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: nil,
                isFree: true, // Assuming carpool is a share, not paid
                isNegotiable: false,
                startLocation: marinaLocation, // Use specific start location
                // endLocation: lakeSchoolLocation, // Need location for Lake School
                startAddress: "Marina District, San Francisco",
                // endAddress: "Lake School Address", // Need address
                // departureTime: nil, (omitted - details in description)
                // returnTime: nil, (omitted)
                // recurrencePattern: .weekly, // Example
                availableSeats: 1, // Example
                // educational fields omitted
                tags: ["carpool", "Lake School", "kindergarten", "Marina district"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 2) // 2 days ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource6",
                title: "Experienced Babysitter Available",
                description: "College student with 5+ years of childcare experience available for babysitting. CPR certified, experience with all ages from infants to pre-teens. Available evenings and weekends. References available.",
                resourceType: .serviceProvider,
                ownerID: userIDs[5],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                // condition: nil, (omitted)
                availabilityStatus: .available, // Service provider is available
                // reservationHistory: nil, (omitted)
                location: universityLocation, // General area
                // address: nil, (omitted)
                contactInfo: "Contact via app message", // Example
                // website: nil, (omitted)
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: 20.00, // Assuming per hour
                isFree: false,
                isNegotiable: false, // Assuming fixed rate
                // carpool/educational fields omitted
                tags: ["babysitter", "childcare", "evening care", "weekend care"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 1) // 1 day ago
                // updatedAt: nil (omitted)
            ),
            SharedResource(
                id: "resource7",
                title: "Kids' Bike - 16 inch - Good Condition",
                description: "16-inch children's bike in good condition. Suitable for 4-6 year olds. Training wheels included but removable. Blue color with dinosaur design.",
                resourceType: .classifiedAd, // Changed to classifiedAd
                ownerID: userIDs[6],
                // ownerName: nil, (omitted)
                coverImageURL: nil,
                // additionalImageURLs: nil, (omitted)
                condition: "Good", // Example condition
                availabilityStatus: .available,
                // reservationHistory: nil, (omitted)
                location: richmondLocation,
                // address: nil, (omitted)
                // contactInfo: nil, (omitted)
                // website: nil, (omitted)
                // rating: nil, (omitted)
                // reviews: nil, (omitted)
                price: 45.00,
                isFree: false,
                isNegotiable: true,
                // carpool/educational fields omitted
                tags: ["bike", "bicycle", "kids bike", "16 inch", "training wheels"],
                // expirationDate: nil, (omitted)
                createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 4) // 4 days ago
                // updatedAt: nil (omitted)
            )
        ]

        // Add mock data to view model
        self.availableResources = mockResources
        self.filteredResources = mockResources
        self.userResources = [mockResources[0], mockResources[2], mockResources[4]] // Some resources owned by the current user
        self.isLoading = false
    }
}
