import Foundation
import Combine
import CoreLocation

@MainActor
class NearbyPlacesViewModel: ObservableObject {
    @Published var nearbyPlaces: [ActivityPlace] = [] // Changed to store ActivityPlace
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let locationManager = LocationManager.shared
    private let placesService = GooglePlacesService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe location changes to potentially refresh places
        locationManager.$location
            .debounce(for: .seconds(1), scheduler: RunLoop.main) // Wait for location to settle
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                // Only fetch if places are empty or location changed significantly (optional)
                if self.nearbyPlaces.isEmpty {
                    self.fetchNearbyPlaces(location: location.coordinate)
                }
            }
            .store(in: &cancellables)
    }

    func fetchNearbyPlaces(location: CLLocationCoordinate2D? = nil) {
        guard !isLoading else { return }

        let coordinateToUse: CLLocationCoordinate2D
        if let location = location {
            coordinateToUse = location
        } else if let currentLocation = locationManager.location?.coordinate {
            coordinateToUse = currentLocation
        } else {
            errorMessage = "Could not determine your current location."
            // Optionally trigger location permission request if needed
            // locationManager.requestLocationPermission()
            return
        }

        isLoading = true
        errorMessage = nil
        print("Fetching nearby places around: \(coordinateToUse.latitude), \(coordinateToUse.longitude)")

        // Search for parks nearby using the correct method
        let searchLocation = CLLocation(latitude: coordinateToUse.latitude, longitude: coordinateToUse.longitude)
        placesService.searchNearbyActivities(
            location: searchLocation,
            radius: 5000, // Search within 5km
            activityType: "park" // Focus on parks for playdates
        ) { [weak self] (result: Result<[ActivityPlace], Error>) in // Explicitly type the result
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let activityPlaces): 
                print("Found \(activityPlaces.count) nearby parks.")
                // Store the full ActivityPlace objects
                self.nearbyPlaces = activityPlaces 
                
                if self.nearbyPlaces.isEmpty {
                    self.errorMessage = "No parks found nearby."
                }
            case .failure(let error):
                print("Error fetching nearby places: \(error)")
                self.errorMessage = "Failed to find nearby places. Please try again later."
                self.nearbyPlaces = [] // Clear previous results on error
            }
        }
    }
}
