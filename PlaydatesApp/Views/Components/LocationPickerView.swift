import SwiftUI
import CoreLocation
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLocation: Location?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a location", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty && newValue.count > 2 {
                                searchLocations()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No locations found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // Results list
                    List {
                        // Current location option
                        if let userLocation = locationManager.location {
                            Button(action: {
                                // Get address for current location
                                let geocoder = CLGeocoder()
                                let clLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
                                
                                geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
                                    if let error = error {
                                        errorMessage = "Error getting address: \(error.localizedDescription)"
                                        return
                                    }
                                    
                                    if let placemark = placemarks?.first {
                                        let name = placemark.name ?? "Current Location"
                                        
                                        // Format address
                                        var addressComponents: [String] = []
                                        if let thoroughfare = placemark.thoroughfare {
                                            addressComponents.append(thoroughfare)
                                        }
                                        if let locality = placemark.locality {
                                            addressComponents.append(locality)
                                        }
                                        if let administrativeArea = placemark.administrativeArea {
                                            addressComponents.append(administrativeArea)
                                        }
                                        if let postalCode = placemark.postalCode {
                                            addressComponents.append(postalCode)
                                        }
                                        
                                        let address = addressComponents.joined(separator: ", ")
                                        
                                        // Create location
                                        let location = Location(
                                            name: name,
                                            address: address,
                                            latitude: userLocation.coordinate.latitude,
                                            longitude: userLocation.coordinate.longitude
                                        )
                                        
                                        selectedLocation = location
                                        isPresented = false
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    
                                    Text("Current Location")
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        // Search results
                        ForEach(searchResults, id: \.id) { location in
                            Button(action: {
                                selectedLocation = location
                                isPresented = false
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(location.name)
                                        .foregroundColor(.primary)
                                    
                                    Text(location.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    private func searchLocations() {
        isSearching = true
        errorMessage = nil
        
        // Use Google Places API to search for locations
        GooglePlacesService.shared.searchPlaces(query: searchText) { result in
            isSearching = false
            
            switch result {
            case .success(let places):
                // Convert places to locations
                self.searchResults = places.map { place in
                    Location(
                        id: place.id,
                        name: place.name,
                        address: place.formattedAddress ?? place.vicinity ?? "",
                        latitude: place.geometry.location.lat,
                        longitude: place.geometry.location.lng
                    )
                }
                
            case .failure(let error):
                self.errorMessage = "Error searching for locations: \(error.localizedDescription)"
            }
        }
    }
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPickerView(
            selectedLocation: .constant(nil),
            isPresented: .constant(true)
        )
    }
}
