import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct MapView: View {
    let location: Location
    @State private var region: MKCoordinateRegion
    
    init(location: Location) {
        self.location = location
        
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region, annotationItems: [location]) { location in
                MapMarker(coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ), tint: ColorTheme.primary)
            }
            .edgesIgnoringSafeArea(.top)
            
            // Location details
            VStack(alignment: .leading, spacing: 8) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                
                // Open in Maps button
                Button { // Use trailing closure syntax
                    openInMaps()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open in Maps")
                        // Font/color handled by primaryStyle
                    }
                    // Styling handled by primaryStyle
                }
                .primaryStyle() // Apply primary style
                .padding(.top, 8)
            }
            .padding()
            .background(Color.white)
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = location.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
