import SwiftUI
import CoreLocation
import Combine

// Weather view for playdate details
struct PlaydateWeatherView: View {
    let playdate: Playdate
    @StateObject private var weatherService = WeatherService.shared
    @State private var weather: Weather?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingWeatherDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Weather Forecast")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                } else if weather != nil {
                    Button(action: {
                        showingWeatherDetails = true
                    }) {
                        Text("See Details")
                            .font(.caption)
                            .foregroundColor(ColorTheme.primary)
                    }
                }
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
            } else if let weather = weather {
                // Weather summary
                HStack(spacing: 16) {
                    // Weather icon
                    AsyncImage(url: weather.iconURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } else if phase.error != nil {
                            // Error state
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .frame(width: 60, height: 60)
                        } else {
                            // Loading state
                            ProgressView()
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    // Weather details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(weather.formattedTemperature)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Text(weather.description)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                        
                        // Activity recommendation
                        HStack {
                            Image(systemName: weather.isGoodForOutdoor ? "checkmark.circle" : "exclamationmark.triangle")
                                .foregroundColor(weather.isGoodForOutdoor ? .green : .orange)
                            
                            Text(weather.isGoodForOutdoor ? "Good for outdoor activities" : "Consider indoor alternatives")
                                .font(.caption)
                                .foregroundColor(weather.isGoodForOutdoor ? .green : .orange)
                        }
                    }
                }
                
                // Activity suggestions
                if !weatherService.getActivitySuggestions(for: weather).isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Suggested Activities:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text(weatherService.getActivitySuggestions(for: weather).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                // Weather not loaded yet
                Button(action: loadWeather) {
                    HStack {
                        Image(systemName: "cloud.sun")
                        Text("Load Weather Forecast")
                    }
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .sheet(isPresented: $showingWeatherDetails) {
            if let weather = weather {
                WeatherDetailView(weather: weather, date: playdate.startDate)
            }
        }
        .onAppear {
            loadWeather()
        }
    }
    
    private func loadWeather() {
        guard let location = playdate.location else {
            error = "Location not available"
            return
        }
        
        isLoading = true
        error = nil
        
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        
        weatherService.fetchWeatherForDate(location: coordinate, date: playdate.startDate)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isLoading = false
                
                if case .failure(let error) = completion {
                    self.error = error.localizedDescription
                }
            }, receiveValue: { weather in
                isLoading = false
                self.weather = weather
            })
            .cancel()
    }
}

// Detailed weather view
struct WeatherDetailView: View {
    let weather: Weather
    let date: Date
    @StateObject private var weatherService = WeatherService.shared
    @State private var forecast: [Weather] = []
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current weather section
                    VStack(spacing: 16) {
                        Text(dateFormatter.string(from: date))
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        // Weather icon and temperature
                        HStack(spacing: 20) {
                            AsyncImage(url: weather.iconURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else if phase.error != nil {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                        .frame(width: 100, height: 100)
                                } else {
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(weather.formattedTemperature)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(ColorTheme.darkPurple)
                                
                                Text(weather.description)
                                    .font(.title3)
                                    .foregroundColor(ColorTheme.lightText)
                            }
                        }
                        
                        // Weather details grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            WeatherDetailItem(
                                icon: "thermometer",
                                label: "Feels Like",
                                value: String(format: "%.0f°F", weather.feelsLike)
                            )
                            
                            WeatherDetailItem(
                                icon: "wind",
                                label: "Wind",
                                value: String(format: "%.1f mph", weather.windSpeed)
                            )
                            
                            WeatherDetailItem(
                                icon: "humidity",
                                label: "Humidity",
                                value: "\(weather.humidity)%"
                            )
                            
                            WeatherDetailItem(
                                icon: "cloud.rain",
                                label: "Precipitation",
                                value: weather.precipitation != nil ? String(format: "%.1f mm", weather.precipitation!) : "0 mm"
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Activity recommendation section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Recommendations")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        HStack {
                            Image(systemName: weather.isGoodForOutdoor ? "checkmark.circle" : "exclamationmark.triangle")
                                .foregroundColor(weather.isGoodForOutdoor ? .green : .orange)
                                .font(.system(size: 24))
                            
                            Text(weather.isGoodForOutdoor ? "Good weather for outdoor activities" : "Consider indoor alternatives")
                                .font(.subheadline)
                                .foregroundColor(weather.isGoodForOutdoor ? .green : .orange)
                        }
                        .padding(.bottom, 8)
                        
                        Text("Suggested Activities:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        ForEach(weatherService.getActivitySuggestions(for: weather), id: \.self) { activity in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(ColorTheme.primary)
                                
                                Text(activity)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // 5-day forecast
                    if !forecast.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("5-Day Forecast")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)
                                .padding(.bottom, 4)
                            
                            ForEach(forecast) { dailyWeather in
                                DailyForecastRow(weather: dailyWeather)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Weather Details")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadForecast()
            }
        }
    }
    
    private func loadForecast() {
        guard let location = extractLocationFromWeather() else {
            return
        }
        
        isLoading = true
        
        weatherService.fetchForecast(for: location)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                isLoading = false
            }, receiveValue: { forecast in
                self.forecast = forecast
                isLoading = false
            })
            .cancel()
    }
    
    private func extractLocationFromWeather() -> CLLocationCoordinate2D? {
        // In a real app, you'd have the location stored in the Weather object
        // Here we'll simulate it with a default location
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
}

// Supporting views
struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(ColorTheme.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.darkPurple)
            }
        }
    }
}

struct DailyForecastRow: View {
    let weather: Weather
    
    var body: some View {
        HStack {
            // Day
            Text(formatDay(weather.date))
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            // Icon
            AsyncImage(url: weather.iconURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "cloud")
                        .foregroundColor(ColorTheme.lightText)
                        .frame(width: 40, height: 40)
                }
            }
            
            // Description
            Text(weather.description)
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Temperature
            Text(weather.formattedTemperature)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.darkPurple)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
