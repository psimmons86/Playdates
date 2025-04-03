import Foundation
import Combine
import CoreLocation

// MARK: - Weather Data Models

struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
    let location: String
}

// MARK: - Weather Service

class WeatherService: ObservableObject {
    // Singleton instance
    static let shared = WeatherService()
    
    // Published properties
    @Published var currentWeather: WeatherData?
    @Published var lastUpdated: Date?
    @Published var error: String?
    @Published var isLoading = false
    
    // Settings
    @Published var useCurrentLocation = true
    @Published var customLocation: String?
    @Published var temperatureUnit = "celsius" // celsius or fahrenheit
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    
    // Initialize
    private init() {
        // Load saved settings
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Fetch weather data
    func fetchWeather(completion: @escaping (Bool) -> Void) {
        isLoading = true
        error = nil
        
        // In a real app, this would make an API call to a weather service
        // For this demo, we'll simulate a network request with sample data
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Generate sample weather data
            if let weather = self.generateSampleWeather() {
                self.currentWeather = weather
                self.lastUpdated = Date()
                self.isLoading = false
                self.saveSettings()
                completion(true)
            } else {
                self.error = "Failed to fetch weather data"
                self.isLoading = false
                completion(false)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate sample weather data
    private func generateSampleWeather() -> WeatherData? {
        // Determine location string based on settings
        var locationString: String
        if useCurrentLocation {
            // TODO: Implement actual location fetching and reverse geocoding
            // For now, use a placeholder indicating current location is intended
            // let currentCoords = locationManager.location?.coordinate 
            // Perform reverse geocode on currentCoords...
            locationString = "Current Location (Simulated)" 
        } else {
            locationString = customLocation ?? "Default City, ST" // Use custom or a generic default
        }
        
        // Generate random weather conditions
        let conditions = ["Clear", "Partly Cloudy", "Cloudy", "Light Rain", "Rain", "Thunderstorm", "Sunny"]
        let condition = conditions.randomElement() ?? "Clear"
        
        // Generate random temperature (50-85°F or 10-30°C)
        let tempCelsius = Double.random(in: 10...30)
        let temperature = temperatureUnit == "celsius" ? tempCelsius : celsiusToFahrenheit(tempCelsius)
        
        // Generate random humidity (30-90%)
        let humidity = Int.random(in: 30...90)
        
        // Generate random wind speed (0-20 mph)
        let windSpeed = Double.random(in: 0...20)
        
        return WeatherData(
            temperature: temperature,
            condition: condition,
            humidity: humidity,
            windSpeed: windSpeed,
            location: locationString // Use the determined location string
        )
    }
    
    /// Convert Celsius to Fahrenheit
    private func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9/5) + 32
    }
    
    /// Convert Fahrenheit to Celsius
    private func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32) * 5/9
    }
    
    // MARK: - Settings Management
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        useCurrentLocation = defaults.bool(forKey: "WeatherUseCurrentLocation")
        customLocation = defaults.string(forKey: "WeatherCustomLocation")
        temperatureUnit = defaults.string(forKey: "WeatherTemperatureUnit") ?? "celsius"
    }
    
    /// Save settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(useCurrentLocation, forKey: "WeatherUseCurrentLocation")
        defaults.set(customLocation, forKey: "WeatherCustomLocation")
        defaults.set(temperatureUnit, forKey: "WeatherTemperatureUnit")
    }
}
