import SwiftUI
import CoreLocation

struct WeatherSuggestionView: View {
    @StateObject private var viewModel = WeatherSuggestionViewModel()
    // Inject ActivityViewModel to potentially navigate to details
    @EnvironmentObject var activityViewModel: ActivityViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Current Weather Display
                if let weather = viewModel.currentWeather {
                    CurrentWeatherCard(weather: weather)
                } else if viewModel.isLoading {
                    // Show loading specifically for weather
                    HStack {
                        ProgressView()
                        Text("Fetching current weather...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if viewModel.errorMessage?.contains("weather") ?? false {
                    // Show weather-specific error
                    Text(viewModel.errorMessage ?? "Could not load weather.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Prompt to enable location if weather isn't loading and no error yet
                     Text("Enable location services to get weather-based suggestions.")
                         .foregroundColor(.secondary)
                         .padding()
                         .multilineTextAlignment(.center)
                }

                Divider()

                // Suggested Activities Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Activities")
                        .font(.title2)
                        .fontWeight(.bold)

                    if viewModel.isLoading {
                        ProgressView("Finding suggestions...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    } else if let error = viewModel.errorMessage, !error.contains("weather") { // Show non-weather errors here
                         Text(error)
                             .foregroundColor(.orange) // Use orange for suggestion-related info/errors
                             .padding()
                             .frame(maxWidth: .infinity)
                    } else if viewModel.suggestedActivities.isEmpty && viewModel.currentWeather != nil {
                        // Only show this if weather is loaded but no suggestions found
                         Text("No suitable activities found in your Favorites or Want to Do lists for the current weather.")
                             .foregroundColor(.secondary)
                             .padding()
                             .frame(maxWidth: .infinity)
                    } else {
                        // Display suggested activities
                        ForEach(viewModel.suggestedActivities) { activity in
                            // Use ExploreActivityCard or a dedicated suggestion card
                            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {
                                ExploreActivityCard(activity: activity)
                                    .environmentObject(activityViewModel) // Pass VM if card needs it
                            }
                            .buttonStyle(PlainButtonStyle()) // Make card tappable
                        }
                    }
                }
                .padding(.horizontal)

            }
            .padding(.vertical)
        }
        .navigationTitle("Weather Suggestions")
        .background(ColorTheme.background.edgesIgnoringSafeArea(.all))
        // Trigger initial fetch if location is already available
        .onAppear {
             if let location = LocationManager.shared.location, viewModel.currentWeather == nil {
                 viewModel.fetchWeatherAndSuggestActivities(location: location)
             }
        }
    }
}

// Simple card to display current weather info
struct CurrentWeatherCard: View {
    let weather: WeatherData

    // Helper function to map condition string to SF Symbol name
    private func weatherIconName(for condition: String) -> String {
        let lowercasedCondition = condition.lowercased()
        switch lowercasedCondition {
        case let c where c.contains("clear"):
            return "sun.max.fill"
        case let c where c.contains("partly cloudy"):
            return "cloud.sun.fill"
        case let c where c.contains("cloudy"):
            return "cloud.fill"
        case let c where c.contains("rain"):
            return "cloud.rain.fill"
        case let c where c.contains("thunderstorm"):
            return "cloud.bolt.rain.fill"
        case let c where c.contains("snow"):
            return "cloud.snow.fill"
        case let c where c.contains("sunny"): // Added explicit sunny case
             return "sun.max.fill"
        default:
            return "questionmark.circle" // Default icon
        }
    }

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: weatherIconName(for: weather.condition)) // Use helper function
                .font(.system(size: 50))
                .symbolRenderingMode(.multicolor) // Make icons colorful if possible
                .foregroundColor(ColorTheme.primary) // Fallback color

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weather.temperature.rounded()))°C") // Assuming Celsius for now, adjust if needed based on settings
                    .font(.title)
                    .fontWeight(.bold)
                Text(weather.condition) // Use weather.condition directly
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Spacer() // Pushes content to the left
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .padding(.horizontal)
    }
}

struct WeatherSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WeatherSuggestionView()
                .environmentObject(ActivityViewModel.shared) // Provide dummy VM
        }
    }
}
