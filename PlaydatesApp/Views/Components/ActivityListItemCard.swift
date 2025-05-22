import SwiftUI

struct ActivityListItemCard: View {
    let activity: Activity
    let onTap: () -> Void // Keep for consistency, even if ExploreView handles navigation differently
    
    private let googlePlacesService = GooglePlacesService.shared
    @State private var imageUrl: URL?
    private let cardHeight: CGFloat = 200 // Consistent height with PlaydateListItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image View - serves as the background
            if let photoUrl = imageUrl {
                AsyncImage(url: photoUrl) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(ColorTheme.secondary.opacity(0.3))
                            .frame(height: cardHeight)
                            .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.primary)))
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: cardHeight)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(ColorTheme.secondary.opacity(0.3))
                            .frame(height: cardHeight)
                            .overlay(Image(systemName: "photo.fill.on.rectangle.fill").foregroundColor(ColorTheme.primary.opacity(0.5)).font(.largeTitle))
                    @unknown default:
                        EmptyView()
                            .frame(height: cardHeight)
                    }
                }
            } else {
                // Fallback to Activity icon if no image
                Rectangle()
                    .fill(activityTypeColor(for: activity.type).opacity(0.3)) // Use activity type color
                    .frame(height: cardHeight)
                    .overlay(
                        VStack {
                            Image(systemName: activity.type.iconName) // Use ActivityType's iconName
                                .font(.system(size: 50))
                                .foregroundColor(activityTypeColor(for: activity.type).opacity(0.8))
                            Text("No Image")
                                .font(.caption)
                                .foregroundColor(activityTypeColor(for: activity.type).opacity(0.8))
                                .padding(.top, 2)
                        }
                    )
            }

            // Scrim Gradient for text readability
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: cardHeight)

            // Details section overlaid on the image
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)

                // Display Activity Type instead of Date
                Label {
                    Text(activity.type.title)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.95))
                } icon: {
                    Image(systemName: activity.type.iconName) // Use ActivityType's iconName
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.95))
                }
                .shadow(radius: 1)

                if !activity.location.name.isEmpty {
                    Label {
                        Text(activity.location.name)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.95))
                    }
                    .shadow(radius: 1)
                }
                
                Spacer() // Pushes the rating/chevron to the bottom of text area

                HStack {
                    if let rating = activity.rating, rating > 0 {
                        Label {
                            Text(String(format: "%.1f", rating))
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.95))
                        } icon: {
                            Image(systemName: "star.fill")
                                .font(.footnote)
                                .foregroundColor(Color.yellow) // Star color
                        }
                        .shadow(radius: 1)
                    }
                    Spacer()
                    // Keep chevron for navigational affordance, similar to PlaydateListItem
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(radius: 1)
                }
            }
            .padding()
        }
        .frame(height: cardHeight)
        .background(activityTypeColor(for: activity.type).opacity(0.5)) // Background based on activity type
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        if let photos = activity.photos, let firstPhotoUrlString = photos.first, let url = URL(string: firstPhotoUrlString) {
            self.imageUrl = url
        } else if let photoRef = activity.photoReference {
            self.imageUrl = googlePlacesService.getPhotoURL(photoReference: photoRef, maxWidth: 400) // Increased maxWidth for better quality
        }
        // No fallback to placeID details for photos here as Activity model is more direct with photoReference or photos array
    }
    
    // Helper to get color based on activity type (simplified, can be expanded)
    private func activityTypeColor(for activityType: ActivityType) -> Color {
        // This could be mapped to specific colors like in ExploreView's CategoryCard
        // For now, a generic approach:
        switch activityType {
        case .park, .hikingTrail: return ColorTheme.green // Example
        case .museum, .library: return ColorTheme.blue // Example
        case .playground, .indoorPlayArea: return ColorTheme.yellow // Example
        default: return ColorTheme.primary // Default
        }
    }
}

struct ActivityListItemCard_Previews: PreviewProvider {
    static var previews: some View {
        // Sample Activity for preview
        let sampleActivity = Activity(
            id: "activity1",
            name: "City Park Exploration",
            type: .park,
            location: Location(name: "Downtown City Park", address: "123 Main St", latitude: 34.0522, longitude: -118.2437),
            description: "A beautiful park in the heart of the city.",
            photoReference: nil, // Add a photo reference for testing image loading
            photos: ["https://images.unsplash.com/photo-1580502247987-032368900014?q=80&w=2070&auto=format&fit=crop"], // Example direct URL
            rating: 4.5,
            reviewCount: 120,
            openingHours: nil, // Add sample opening hours if needed
            website: nil, // Add website if needed
            phoneNumber: nil, // Add phone number if needed
            googlePlaceID: "ChIJN1t_tDeuEmsRUsoyG83frY4" // Example Google Place ID
        )
        
        let sampleActivityNoImage = Activity(
            id: "activity2",
            name: "Local Library Story Time",
            type: .library,
            location: Location(name: "Community Library", address: "456 Book Rd", latitude: 34.0522, longitude: -118.2437),
            description: "Weekly story time for kids.",
            photoReference: nil,
            photos: [],
            rating: 4.2,
            reviewCount: 80,
            openingHours: nil,
            website: nil,
            phoneNumber: nil,
            googlePlaceID: "ChIJN1t_tDeuEmsRUsoyG83frY5"
        )

        ScrollView {
            VStack(spacing: 20) {
                ActivityListItemCard(activity: sampleActivity, onTap: {})
                ActivityListItemCard(activity: sampleActivityNoImage, onTap: {})
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}
