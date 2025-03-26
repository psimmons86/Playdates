import Foundation
import CoreLocation
import Combine

// Weather data model
struct Weather: Identifiable {
    let id: String
    let date: Date
    let temperature: Double
    let feelsLike: Double
    let description: String
    let iconCode: String
    let conditionCode: Int
    let windSpeed: Double
    let humidity: Int
    let precipitation: Double?
    let isGoodForOutdoor: Bool
    
    var iconURL: URL {
        URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png")!
    }
    
    var formattedTemperature: String {
        String(format: "%.0f°F", temperature)
    }
}

// Response models for API parsing
struct WeatherResponse: Decodable {
    let weather: [WeatherCondition]
    let main: WeatherMain
    let wind: WeatherWind
    let rain: WeatherRain?
    let dt: TimeInterval
    
    struct WeatherCondition: Decodable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct WeatherMain: Decodable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
    }
    
    struct WeatherWind: Decodable {
        let speed: Double
    }
    
    struct WeatherRain: Decodable {
        let h1: Double?
        
        enum CodingKeys: String, CodingKey {
            case h1 = "1h"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            h1 = try container.decodeIfPresent(Double.self, forKey: .h1)
        }
    }
}

struct ForecastResponse: Decodable {
    let list: [ForecastItem]
    
    struct ForecastItem: Decodable {
        let dt: TimeInterval
        let main: WeatherResponse.WeatherMain
        let weather: [WeatherResponse.WeatherCondition]
        let wind: WeatherResponse.WeatherWind
        let rain: WeatherResponse.WeatherRain?
    }
}

class WeatherService: ObservableObject {
    static let shared = WeatherService()
    
    private let apiKey = "YOUR_OPENWEATHERMAP_API_KEY" // Replace with a real API key
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    @Published var currentWeather: Weather?
    @Published var forecast: [Weather] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // Fetch current weather for a location
    func fetchCurrentWeather(for location: CLLocationCoordinate2D) -> AnyPublisher<Weather, Error> {
        isLoading = true
        error = nil
        
        let urlString = "\(baseURL)/weather?lat=\(location.latitude)&lon=\(location.longitude)&units=imperial&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "WeatherService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .map { response -> Weather in
                let weather = Weather(
                    id: UUID().uuidString,
                    date: Date(timeIntervalSince1970: response.dt),
                    temperature: response.main.temp,
                    feelsLike: response.main.feels_like,
                    description: response.weather.first?.description.capitalized ?? "Unknown",
                    iconCode: response.weather.first?.icon ?? "01d",
                    conditionCode: response.weather.first?.id ?? 800,
                    windSpeed: response.wind.speed,
                    humidity: response.main.humidity,
                    precipitation: response.rain?.h1,
                    isGoodForOutdoor: self.isGoodForOutdoorActivity(response: response)
                )
                
                DispatchQueue.main.async {
                    self.currentWeather = weather
                    self.isLoading = false
                }
                
                return weather
            }
            .mapError { error -> Error in
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    // Fetch 5-day forecast for a location
    func fetchForecast(for location: CLLocationCoordinate2D) -> AnyPublisher<[Weather], Error> {
        isLoading = true
        error = nil
        
        let urlString = "\(baseURL)/forecast?lat=\(location.latitude)&lon=\(location.longitude)&units=imperial&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "WeatherService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: ForecastResponse.self, decoder: JSONDecoder())
            .map { response -> [Weather] in
                // Group forecasts by day (one forecast per day)
                let calendar = Calendar.current
                let groupedForecasts = Dictionary(grouping: response.list) { item in
                    let date = Date(timeIntervalSince1970: item.dt)
                    return calendar.startOfDay(for: date)
                }
                
                // Get the mid-day forecast for each day
                let dayForecasts = groupedForecasts.compactMap { (date, forecasts) -> Weather? in
                    // Find forecast closest to noon
                    let sortedByTimeOfDay = forecasts.sorted { item1, item2 in
                        let date1 = Date(timeIntervalSince1970: item1.dt)
                        let date2 = Date(timeIntervalSince1970: item2.dt)
                        
                        let components1 = calendar.dateComponents([.hour], from: date1)
                        let components2 = calendar.dateComponents([.hour], from: date2)
                        
                        let hourDiff1 = abs((components1.hour ?? 0) - 12)
                        let hourDiff2 = abs((components2.hour ?? 0) - 12)
                        
                        return hourDiff1 < hourDiff2
                    }
                    
                    guard let bestForecast = sortedByTimeOfDay.first else { return nil }
                    
                    return Weather(
                        id: UUID().uuidString,
                        date: Date(timeIntervalSince1970: bestForecast.dt),
                        temperature: bestForecast.main.temp,
                        feelsLike: bestForecast.main.feels_like,
                        description: bestForecast.weather.first?.description.capitalized ?? "Unknown",
                        iconCode: bestForecast.weather.first?.icon ?? "01d",
                        conditionCode: bestForecast.weather.first?.id ?? 800,
                        windSpeed: bestForecast.wind.speed,
                        humidity: bestForecast.main.humidity,
                        precipitation: bestForecast.rain?.h1,
                        isGoodForOutdoor: self.isGoodForOutdoorActivity(wind: bestForecast.wind.speed,
                                                            conditionCode: bestForecast.weather.first?.id ?? 800,
                                                            precipitation: bestForecast.rain?.h1,
                                                            temperature: bestForecast.main.temp)
                    )
                }
                .sorted { $0.date < $1.date }
                
                DispatchQueue.main.async {
                    self.forecast = dayForecasts
                    self.isLoading = false
                }
                
                return dayForecasts
            }
            .mapError { error -> Error in
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    // Weather forecast for a specific date
    func fetchWeatherForDate(location: CLLocationCoordinate2D, date: Date) -> AnyPublisher<Weather?, Error> {
        // For dates within 5 days, use the forecast API
        let now = Date()
        let fiveDaysLater = Calendar.current.date(byAdding: .day, value: 5, to: now)!
        
        if date <= fiveDaysLater {
            return fetchForecast(for: location)
                .map { forecasts -> Weather? in
                    // Find forecast for the given date
                    let calendar = Calendar.current
                    return forecasts.first { forecast in
                        calendar.isDate(forecast.date, inSameDayAs: date)
                    }
                }
                .eraseToAnyPublisher()
        } else {
            // For dates beyond 5 days, use historical weather as prediction (or a climate API in a real app)
            // This is a simplified approach - in a real app, you'd use a long-range forecast API
            // For this example, we'll just return a simulated weather
            return Future<Weather?, Error> { promise in
                let simulatedWeather = Weather(
                    id: UUID().uuidString,
                    date: date,
                    temperature: 75.0, // Average temperature
                    feelsLike: 77.0,
                    description: "Partly Cloudy",
                    iconCode: "02d",
                    conditionCode: 801,
                    windSpeed: 5.0,
                    humidity: 65,
                    precipitation: 0.0,
                    isGoodForOutdoor: true
                )
                
                promise(.success(simulatedWeather))
            }
            .eraseToAnyPublisher()
        }
    }
    
    // Determine if weather is good for outdoor activities
    private func isGoodForOutdoorActivity(response: WeatherResponse) -> Bool {
        return isGoodForOutdoorActivity(
            wind: response.wind.speed,
            conditionCode: response.weather.first?.id ?? 800,
            precipitation: response.rain?.h1,
            temperature: response.main.temp
        )
    }
    
    private func isGoodForOutdoorActivity(wind: Double, conditionCode: Int, precipitation: Double?, temperature: Double) -> Bool {
        // Wind speed less than 20 mph
        guard wind < 20.0 else { return false }
        
        // No heavy precipitation
        guard precipitation ?? 0.0 < 0.1 else { return false }
        
        // Temperature between 50°F and 95°F
        guard temperature >= 50.0 && temperature <= 95.0 else { return false }
        
        // Weather conditions: avoid severe weather
        // Condition codes:
        // 2xx: Thunderstorm
        // 3xx: Drizzle
        // 5xx: Rain
        // 6xx: Snow
        // 7xx: Atmosphere (fog, dust, etc.)
        // 800: Clear
        // 80x: Clouds
        
        if conditionCode < 300 { // Thunderstorms
            return false
        }
        
        if conditionCode >= 500 && conditionCode < 600 && conditionCode != 500 && conditionCode != 501 {
            // Moderate to heavy rain (light rain is okay)
            return false
        }
        
        if conditionCode >= 600 && conditionCode < 700 {
            // Snow
            return false
        }
        
        if conditionCode == 781 { // Tornado
            return false
        }
        
        return true
    }
    
    // Get activity suggestions based on weather
    func getActivitySuggestions(for weather: Weather) -> [String] {
        if weather.isGoodForOutdoor {
            if weather.temperature > 80 {
                return ["Swimming", "Water park", "Splash pad", "Park with shade", "Morning or evening outdoor activities"]
            } else if weather.temperature > 65 {
                return ["Playground", "Park", "Hiking", "Biking", "Outdoor sports", "Zoo", "Botanical garden"]
            } else {
                return ["Playground (bring jackets)", "Nature walks", "Outdoor museums", "Mini golf"]
            }
        } else {
            // Indoor activities
            return ["Indoor playground", "Children's museum", "Library", "Movie theater", "Aquarium", "Science center", "Arts and crafts", "Cooking class"]
        }
    }
}
