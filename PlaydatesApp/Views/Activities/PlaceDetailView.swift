import SwiftUI
import MapKit // Import MapKit for map display

// Define the PlaceDetailView
struct PlaceDetailView: View {
    let place: ActivityPlace // Input: The place to display details for

    // State for the map region
    @State private var region: MKCoordinateRegion

    init(place: ActivityPlace) {
        self.place = place
        // Initialize the map region centered on the place's coordinates
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: place.location.latitude, longitude: place.location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Zoom level
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Place Name
                Text(place.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)

                // Address
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(ColorTheme.primary)
                    Text(place.location.address ?? "Address not available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                // Rating and User Ratings Count
                if let rating = place.rating {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .fontWeight(.semibold)
                        if let totalRatings = place.userRatingsTotal {
                            Text("(\(totalRatings) reviews)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 8)
                }

                // Map View
                Map(coordinateRegion: $region, annotationItems: [place.location]) { location in
                    MapMarker(coordinate: location.coordinate, tint: ColorTheme.primary)
                }
                .frame(height: 250) // Set a fixed height for the map
                .cornerRadius(12)
                .padding(.bottom, 16)

                // TODO: Add more details like photos, opening hours, etc. if available
                // TODO: Add buttons for actions like "Get Directions", "Start Playdate Here"

                Spacer() // Push content to the top
            }
            .padding() // Add padding around the content
        }
        .navigationTitle(place.name) // Set navigation bar title
        .navigationBarTitleDisplayMode(.inline) // Keep title inline
    }
}

// Preview Provider
struct PlaceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock ActivityPlace for the preview
        let mockPlace = ActivityPlace(
            id: "preview_1",
            name: "Central Park Playground",
            location: Location(id: "loc1", name: "Central Park Playground", address: "123 Park Ave, New York, NY", latitude: 40.785091, longitude: -73.968285),
            types: ["park", "playground"],
            rating: 4.5,
            userRatingsTotal: 150,
            photoReference: nil
        )

        // Embed in NavigationView for previewing navigation bar
        NavigationView {
            PlaceDetailView(place: mockPlace)
        }
    }
}
