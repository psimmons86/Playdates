import SwiftUI
import Foundation

struct NearbyPlaceCard: View {
    let place: ActivityPlace
    @EnvironmentObject var activityViewModel: ActivityViewModel // Inject ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section with Overlay Button
            ZStack(alignment: .topTrailing) { // Use ZStack for overlay
                AsyncImage(url: GooglePlacesService.shared.getPhotoURL(photoReference: place.photoReference ?? "", maxWidth: 400)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    // Placeholder with icon if no photo reference or during loading
                    ZStack {
                        Color(.systemGray5)
                        Image(systemName: "photo.fill")
                            .foregroundColor(.gray)
                            .font(.title)
                    }
                }
                
                // Wishlist Button Overlay
                Button {
                    // Create minimal Activity for toggling
                    let activityForToggle = Activity(
                        id: place.id,
                        name: place.name,
                        type: ActivityType(rawValue: place.types.first ?? "") ?? .other,
                        location: place.location
                    )
                    Task {
                        await activityViewModel.toggleWantToDo(activity: activityForToggle)
                    }
                } label: {
                    // Use the new isWantToDo(activityID:) function
                    let isWishlisted = activityViewModel.isWantToDo(activityID: place.id)
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .foregroundColor(isWishlisted ? .red : .white)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(5) // Padding around the button
            }
            .frame(height: 80)
            .clipped()

            // Text Content Section
            VStack(alignment: .leading, spacing: 4) { // Inner VStack for text
                Text(place.name)
                    .font(.caption) // Slightly smaller font for card
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.text)
                    .lineLimit(1)
                
                HStack(alignment: .top, spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(ColorTheme.primary)
                        .font(.caption2)
                        .padding(.top, 1)
                    
                    Text(place.location.address) // Access address via location property
                        .font(.caption2) // Smaller font for address
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(2)
                } // End HStack for location
            } // End Inner VStack for text
            .padding(.horizontal, 8)
            .padding(.vertical, 6) // Reduced vertical padding
            .frame(height: 50, alignment: .top) // Fixed height for text content
            
        } // End Outer VStack (main body container)
        .frame(width: 160, height: 130) // Adjusted card size
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Preview Provider (Updated to use ActivityPlace and inject ViewModel)
struct NearbyPlaceCard_Previews: PreviewProvider {
    static var previews: some View {
        // Mock ActivityViewModel and add item to wishlist for preview state
        let mockActivityVM = ActivityViewModel.shared
        let mockLocation = Location(
            id: "mock_place_id",
            name: "Example Park",
            address: "123 Fun Street, Playville, CA 90210",
            latitude: 34.0522,
            longitude: -118.2437
        )
        let mockPlace = ActivityPlace(
            id: "mock_place_id",
            name: "Example Park",
            location: mockLocation,
            types: ["park", "playground"],
            rating: 4.5,
            userRatingsTotal: 120,
            photoReference: nil
        )
        let mockPlaceWishlisted = ActivityPlace(
            id: "wishlisted_id",
            name: "Wishlisted Park",
            location: mockLocation,
            types: ["park"], rating: 4.8, userRatingsTotal: 99, photoReference: nil
        )
        // Add one item to the wishlist for preview
        mockActivityVM.wantToDoActivityIDs = ["wishlisted_id"]
        
        return HStack {
            NearbyPlaceCard(place: mockPlace)
            NearbyPlaceCard(place: mockPlaceWishlisted)
        }
        .environmentObject(mockActivityVM) // Inject ViewModel
        .padding()
        .background(ColorTheme.background)
    }
}

// NOTE: Removed the conflicting Activity extension that was previously here.
