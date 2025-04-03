import SwiftUI
import Foundation

struct WeatherView: View {
    @ObservedObject private var weatherService = WeatherService.shared
    @State private var isLoading = true
    @State private var showingSettings = false
    
    var body: some View {
        // Use VStack as the main container instead of Group
        VStack {
            if isLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ColorTheme.primary)) // Changed tint
                    
                    Text("Loading weather...")
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText) // Changed color
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, minHeight: 80) // Ensure minimum height for loading state
            } else if let weather = weatherService.currentWeather {
                // Weather content
                HStack(spacing: 20) {
                    // Weather icon and temperature
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: weatherIconName)
                            .font(.system(size: 40))
                            .foregroundColor(ColorTheme.primary) // Changed color
                        
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(ColorTheme.text) // Changed color
                        
                        Text(weather.condition)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText) // Changed color
                    }
                    .frame(width: 100)
                    
                    // Weather details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(weather.location)
                            .font(.headline)
                            .foregroundColor(ColorTheme.text) // Changed color
                        
                        HStack {
                            WeatherDetailItem(
                                icon: "humidity",
                                value: "\(weather.humidity)%",
                                label: "Humidity"
                            )
                            
                            Spacer()
                            
                            WeatherDetailItem(
                                icon: "wind",
                                value: "\(Int(weather.windSpeed)) mph",
                                label: "Wind"
                            )
                        }
                        
                        Text("Updated: \(formattedUpdateTime)")
                            .font(.caption2)
                            .foregroundColor(ColorTheme.lightText) // Changed color
                    }
                    .padding(.trailing)
                }
                // .padding() // Padding is handled by RoundedCard in HomeView
            } else {
                // Error or no data state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 30))
                        .foregroundColor(ColorTheme.warning) // Changed color
                    
                    Text("Weather data unavailable")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text) // Changed color
                    
                    Button(action: {
                        refreshWeather()
                    }) {
                        Text("Refresh")
                            .font(.caption)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ColorTheme.primaryLight.opacity(0.3)) // Changed background
                            .foregroundColor(ColorTheme.primary) // Changed color
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background
                }
                .frame(maxWidth: .infinity, minHeight: 80) // Ensure minimum height for error state
            }
        } // End of conditional content VStack/HStack
        // Apply modifiers to the outer VStack
        .onAppear {
            refreshWeather()
        }
        .onTapGesture {
            showingSettings = true
        }
        .sheet(isPresented: $showingSettings) {
            WeatherSettingsView()
        }
    }
    
    // MARK: - Helper Properties
    
    private var weatherIconName: String {
        guard let weather = weatherService.currentWeather else {
            return "cloud.fill"
        }
        
        let condition = weather.condition.lowercased()
        let isDay = true // In a real app, determine based on time
        
        if condition.contains("clear") || condition.contains("sunny") {
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        } else if condition.contains("cloud") {
            if condition.contains("partly") {
                return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
            } else {
                return "cloud.fill"
            }
        } else if condition.contains("rain") {
            if condition.contains("light") {
                return "cloud.drizzle.fill"
            } else if condition.contains("heavy") {
                return "cloud.heavyrain.fill"
            } else {
                return "cloud.rain.fill"
            }
        } else if condition.contains("snow") {
            return "cloud.snow.fill"
        } else if condition.contains("thunder") || condition.contains("lightning") {
            return "cloud.bolt.fill"
        } else if condition.contains("fog") || condition.contains("mist") {
            return "cloud.fog.fill"
        } else if condition.contains("wind") {
            return "wind"
        } else {
            return "cloud.fill"
        }
    }
    
    // Removed weatherGradientColors computed property
    
    private var formattedUpdateTime: String {
        guard let lastUpdated = weatherService.lastUpdated else {
            return "Unknown"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: lastUpdated)
    }
    
    // MARK: - Helper Methods
    
    private func refreshWeather() {
        isLoading = true
        weatherService.fetchWeather { success in
            isLoading = false
        }
    }
}

// MARK: - Weather Detail Item
struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ColorTheme.lightText) // Changed color
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ColorTheme.text) // Changed color
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(ColorTheme.lightText) // Changed color
        }
    }
}

// MARK: - Weather Settings View
struct WeatherSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var weatherService = WeatherService.shared
    @State private var locationText = ""
    @State private var useCurrentLocation = true
    @State private var temperatureUnit = "celsius"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location")) {
                    Toggle("Use Current Location", isOn: $useCurrentLocation)
                    
                    if !useCurrentLocation {
                        TextField("City, State", text: $locationText)
                            .autocapitalization(.words)
                    }
                }
                
                Section(header: Text("Units")) {
                    Picker("Temperature", selection: $temperatureUnit) {
                        Text("Celsius (°C)").tag("celsius")
                        Text("Fahrenheit (°F)").tag("fahrenheit")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Settings")
                        // Color handled by buttonStyle
                    }
                    .buttonStyle(TextButtonStyle(color: .blue)) // Apply text style with blue color
                }
            }
            .navigationTitle("Weather Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(TextButtonStyle())) // Apply text style
            .onAppear {
                // Load current settings
                locationText = weatherService.customLocation ?? ""
                useCurrentLocation = weatherService.useCurrentLocation
                temperatureUnit = weatherService.temperatureUnit
            }
        }
    }
    
    private func saveSettings() {
        weatherService.useCurrentLocation = useCurrentLocation
        weatherService.customLocation = useCurrentLocation ? nil : locationText
        weatherService.temperatureUnit = temperatureUnit
        
        // Refresh weather with new settings
        weatherService.fetchWeather { _ in }
    }
}

#if DEBUG
struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
            .previewLayout(.fixed(width: 375, height: 120))
            .padding()
    }
}
#endif
