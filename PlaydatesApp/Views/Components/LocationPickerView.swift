import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase

// Location Picker Content View
struct LocationPickerContent: View {
    @Binding var selectedLocation: Location?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var locationManager = LocationManager.shared
    
    // Add optional action parameters
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
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
                    Button(action: { // Original Clear Search Button
                        searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle()) // Keep plain style for this icon button
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
                        Button(action: { // Original Current Location Button
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
                        .buttonStyle(PlainButtonStyle()) // Add plain style for list interaction
                    }
                    
                    // Search results
                    ForEach(searchResults, id: \.id) { location in
                        Button(action: { // Original Search Result Button
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
                        .buttonStyle(PlainButtonStyle()) // Add plain style for list interaction
                    }
                }
            }
            
            // Optional action button (if provided) - Reverted to original
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationTitle("Select Location")
        .navigationBarItems(trailing: Button("Cancel") { // Original Cancel Button
            isPresented = false
        })
        // Removed potentially problematic comment/modifier placeholder
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
                if places.isEmpty {
                    self.errorMessage = "No locations found for '\(self.searchText)'"
                } else {
                    print("Debug: Found \(places.count) places")
                    self.searchResults = places.map { place in
                        // Get the address from vicinity, formattedAddress, or fallback to name
                        let address = place.vicinity ?? place.formattedAddress ?? place.name
                        
                        let location = Location(
                            id: place.placeId,
                            name: place.name,
                            address: address,
                            latitude: place.geometry.location.lat,
                            longitude: place.geometry.location.lng
                        )
                        print("Debug: Mapped location: \(location.name), \(location.address)")
                        return location
                    }
                }
                
            case .failure(let error):
                self.errorMessage = "Error searching for locations: \(error.localizedDescription)"
                print("Debug: Search error: \(error.localizedDescription)")
            }
        }
    }
}
