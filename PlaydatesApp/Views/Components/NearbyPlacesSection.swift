import SwiftUI

struct NearbyPlacesSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    // Removed ActivityViewModel EnvironmentObject as it's not used in this version
    @StateObject private var viewModel = NearbyPlacesViewModel()
    @State private var checkInData: CheckInData? = nil

    // Helper struct for the sheet item state (must be Identifiable)
    struct CheckInData: Identifiable {
        let id: String // Use place id for identification
        let place: ActivityPlace
        let user: User // Store the user object directly
    }
    
    // Optional action for tapping a place card (e.g., show details or map)
    var onPlaceTap: ((ActivityPlace) -> Void)? = nil

    // Computed property for the places array
    private var places: [ActivityPlace] {
        viewModel.nearbyPlaces
    }

    var body: some View {
        // Removed SectionBox wrapper. RoundedCard is applied in HomeView.
        VStack(alignment: .leading, spacing: 12) { // Main VStack for the section content
            // Add the title directly here
            Text("Nearby Parks & Playgrounds")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.darkPurple)
                .padding(.leading) // Add some leading padding for the title

            // Existing content starts here
            if viewModel.isLoading && viewModel.nearbyPlaces.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100) // Use maxWidth and minHeight
            } else if let errorMessage = viewModel.errorMessage, viewModel.nearbyPlaces.isEmpty {
                // Display error message if loading failed and list is empty
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100) // Use maxWidth and minHeight
            } else if viewModel.nearbyPlaces.isEmpty {
                // Display empty state if no places were found (but no error)
                 Text("No nearby parks found. Try expanding your search area.")
                     .font(.caption)
                     .foregroundColor(.gray)
                     .padding()
                     .frame(maxWidth: .infinity, minHeight: 100) // Use maxWidth and minHeight
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Iterate directly over Identifiable items
                        ForEach(places) { place in
                            // Revert to using NearbyPlaceCard and separate Check In button
                            VStack(alignment: .leading, spacing: 8) {
                                // Button for navigating to details (original functionality)
                                Button {
                                    onPlaceTap?(place)
                                } label: {
                                    NearbyPlaceCard(place: place) // Use NearbyPlaceCard
                                }
                                .buttonStyle(PlainButtonStyle())

                                // Check In Button (Restored)
                                Button {
                                    guard let currentUser = authViewModel.user else { return }
                                    checkInData = CheckInData(id: place.id, place: place, user: currentUser)
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "mappin.and.ellipse")
                                        Text("Check In")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1)) // Subtle background
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(authViewModel.user == nil)
                            }
                            .frame(width: 180) // Give the VStack a width
                        }
                    }
                    .padding(.horizontal) // Add padding inside the scroll view again
                }
                .frame(height: 160) // Adjust height for card + button
            }
        } // End of main VStack
        .sheet(item: $checkInData) { data in
            // 'data' contains both the place and the user, guaranteed non-nil here
            let placeToCheckIn = data.place
            let currentUser = data.user // Use the user stored at tap time

            // Create an Activity from ActivityPlace
            let activityForCheckIn = Activity(
                id: placeToCheckIn.id, // Use place ID as activity ID
                name: placeToCheckIn.name,
                // Attempt to map the first type, default to .other
                type: ActivityType(rawValue: placeToCheckIn.types.first ?? "") ?? .other,
                location: placeToCheckIn.location
                // Add other relevant fields if needed/available
            )

            // Present CheckInView, passing the created activity and the *current* authViewModel instance
            CheckInView(activity: activityForCheckIn, authViewModel: authViewModel)
                 .environmentObject(authViewModel)
        }
        .onAppear {
            // Fetch places when the section appears if they haven't been loaded
            if viewModel.nearbyPlaces.isEmpty && !viewModel.isLoading {
                viewModel.fetchNearbyPlaces()
            }
        }
    }
}

// Preview Provider
struct NearbyPlacesSection_Previews: PreviewProvider {
    static var previews: some View {
        // Mock AuthViewModel
        let mockAuthViewModel = AuthViewModel()
        mockAuthViewModel.user = User(id: "previewUser", name: "Preview User", email: "preview@test.com")
        // ActivityViewModel not needed for this preview version
        let mockActivityViewModel = ActivityViewModel.shared


        // Mock NearbyPlacesViewModel for preview
        let mockViewModel = NearbyPlacesViewModel()
        mockViewModel.nearbyPlaces = [
            ActivityPlace(
                id: "preview_1",
                name: "Central Park Playground",
                location: Location(id: "loc1", name: "Central Park Playground", address: "123 Park Ave", latitude: 40.785091, longitude: -73.968285),
                types: ["park", "playground"],
                rating: 4.5,
                userRatingsTotal: 150,
                photoReference: nil
            ),
            ActivityPlace(
                id: "preview_2",
                name: "Riverside Park",
                location: Location(id: "loc2", name: "Riverside Park", address: "456 River Rd", latitude: 40.8007, longitude: -73.9754),
                types: ["park"],
                rating: 4.7,
                userRatingsTotal: 200,
                photoReference: nil
            ),
            ActivityPlace(
                id: "preview_3",
                name: "Green Valley Park",
                location: Location(id: "loc3", name: "Green Valley Park", address: "789 Valley View", latitude: 34.0522, longitude: -118.2437),
                types: ["park", "playground"],
                rating: 4.2,
                userRatingsTotal: 80,
                photoReference: nil
            )
        ]

        let errorViewModel = NearbyPlacesViewModel()
        errorViewModel.errorMessage = "Could not fetch places."
        
        let loadingViewModel = NearbyPlacesViewModel()
        loadingViewModel.isLoading = true

        return VStack {
            Text("Logged In State:").font(.headline)
            NearbyPlacesSection()
                .environmentObject(mockViewModel)
                .environmentObject(mockAuthViewModel)
                .environmentObject(mockActivityViewModel) // Keep for potential future use

            Text("Error State:").font(.headline)
            NearbyPlacesSection()
                .environmentObject(errorViewModel)
                .environmentObject(mockAuthViewModel)
                .environmentObject(mockActivityViewModel)

            Text("Loading State:").font(.headline)
            NearbyPlacesSection()
                .environmentObject(loadingViewModel)
                .environmentObject(mockAuthViewModel)
                .environmentObject(mockActivityViewModel)

            Text("Logged Out State:").font(.headline)
             NearbyPlacesSection()
                 .environmentObject(mockViewModel)
                 .environmentObject(AuthViewModel()) // Logged-out user
                 .environmentObject(mockActivityViewModel)

        }
        .padding()
        .background(ColorTheme.background)
    }
}
