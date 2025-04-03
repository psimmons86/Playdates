import Foundation
import Combine
import CoreLocation

@MainActor
class WeatherSuggestionViewModel: ObservableObject {
    
    @Published var currentWeather: WeatherData?
    @Published var suggestedActivities: [Activity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Dependencies
    private let weatherService = WeatherService.shared // Use the shared instance
    private let activityViewModel = ActivityViewModel.shared // Access shared activity data
    private let locationManager = LocationManager.shared // Access shared location data
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("🌦️ WeatherSuggestionViewModel initialized.")
        // Observe location changes to trigger weather/suggestion updates
        locationManager.$location
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main) // Avoid rapid updates
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                print("🌦️ Location updated, fetching weather and suggestions...")
                self.fetchWeatherAndSuggestActivities(location: location)
            }
            .store(in: &cancellables)
            
        // Also observe changes in user's activity lists
        activityViewModel.$favoriteActivityIDs
            .combineLatest(activityViewModel.$wantToDoActivityIDs)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                 guard let self = self, let location = self.locationManager.location else { return }
                 print("🌦️ Activity lists updated, re-evaluating suggestions...")
                 // Re-suggest based on current weather and new lists
                 self.suggestActivitiesBasedOnWeather()
            }
            .store(in: &cancellables)
    }
    
    func fetchWeatherAndSuggestActivities(location: CLLocation) {
        isLoading = true
        errorMessage = nil
        suggestedActivities = [] // Clear previous suggestions
        
        // Use the existing completion handler based fetchWeather for now
        weatherService.fetchWeather { [weak self] success in
            guard let self = self else { return }
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                if success, let weather = self.weatherService.currentWeather {
                    self.currentWeather = weather
                    print("🌦️ Weather fetched: \(weather.condition), Temp: \(weather.temperature)")
                    self.suggestActivitiesBasedOnWeather()
                } else {
                     print("❌ Error fetching weather via completion handler.")
                     self.errorMessage = self.weatherService.error ?? "Could not fetch weather data."
                }
                 self.isLoading = false
            }
        }
    }
    
    private func suggestActivitiesBasedOnWeather() {
        guard let weather = currentWeather else {
            print("🌦️ Cannot suggest activities without weather data.")
            self.suggestedActivities = []
            return
        }
        
        // Combine favorite and want-to-do IDs
        let combinedIDs = activityViewModel.favoriteActivityIDs.union(activityViewModel.wantToDoActivityIDs)
        
        // Get the full Activity objects for these IDs
        // Simplify creation - type inference should handle this
        let allKnownActivities = activityViewModel.activities + activityViewModel.nearbyActivities + activityViewModel.popularActivities
        
        // Filter the allKnownActivities array directly based on combinedIDs
        // This avoids creating the intermediate dictionary that caused issues.
        let potentialActivities: [Activity] = allKnownActivities.filter { activity in
            guard let id = activity.id else { return false }
            return combinedIDs.contains(id)
        }

        print("🌦️ Potential activities for suggestion: \(potentialActivities.map { $0.name })")

        // Filter based on weather using weather.condition
        let isBadWeather = weather.condition.lowercased().contains("rain") ||
                           weather.condition.lowercased().contains("snow") ||
                           weather.condition.lowercased().contains("storm") ||
                           weather.temperature < 5 ||
                           weather.temperature > 30

        var currentSuggestions: [Activity] = []
        if isBadWeather {
            print("🌦️ Bad weather detected. Suggesting indoor activities.")
            currentSuggestions = potentialActivities.filter { $0.type.isIndoor }
        } else {
            print("🌦️ Good weather detected. Suggesting outdoor activities primarily.")
            let outdoor: [Activity] = potentialActivities.filter { !$0.type.isIndoor }
            let indoor: [Activity] = potentialActivities.filter { $0.type.isIndoor }
            currentSuggestions = Array(outdoor.prefix(3) + indoor.prefix(2))
        }

        // Assign to @Published property
        self.suggestedActivities = Array(currentSuggestions.prefix(5))

        print("🌦️ Final suggested activities (\(suggestedActivities.count)): \(suggestedActivities.map { $0.name })")

        // Update error message based on results
        if suggestedActivities.isEmpty && !potentialActivities.isEmpty {
             self.errorMessage = "No suitable activities found in your lists for the current weather."
        } else if potentialActivities.isEmpty {
             self.errorMessage = "Add some activities to your Favorites or Want to Do lists first!"
        } else {
            self.errorMessage = nil
        }
    }
}

// Helper extension for ActivityType
extension ActivityType {
    var isIndoor: Bool {
        switch self {
        case .museum, .library, .swimmingPool, .indoorPlayArea, .movieTheater, .aquarium:
            return true
        case .park, .playground, .hikingTrail, .sportingEvent, .zoo, .beach, .themePark, .summerCamp, .other:
            return false
        }
    }
}
