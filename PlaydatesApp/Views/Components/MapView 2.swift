import SwiftUI
import MapKit

@available(iOS 17.0, *)
public struct MapView: View {
    let location: Location
    @State private var region: MKCoordinateRegion
    
    public init(location: Location) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    public var body: some View {
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
                Button(action: openInMaps) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open in Maps")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
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

// MARK: - Location Conformance to Identifiable
extension Location: Identifiable {
    public var id: String { "\(latitude),\(longitude)" }
}
