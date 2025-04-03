import SwiftUI
import Foundation

struct PopularActivityCard: View {
    // Changed to accept ActivityPlace
    let place: ActivityPlace
    // Removed onAddToWishlist and isInWishlist parameters
    
    // Inject ActivityViewModel to handle wishlist logic internally
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        RoundedCard { // Replaced GradientCard with RoundedCard
            VStack(alignment: .leading, spacing: 12) {
                // Activity icon
                HStack {
                    Spacer()
                    
                    // Correctly call the helper function using self
                    Image(systemName: self.activityIcon(from: place.types))
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.primary)
                        .padding(.top, 12)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Activity details
                VStack(alignment: .leading, spacing: 8) {
                    // Title and rating from place
                    HStack {
                        Text(place.name)
                            .font(.headline)
                            .foregroundColor(ColorTheme.text)
                            // Allow wrapping
                        
                        Spacer()
                        
                        if let rating = place.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(ColorTheme.highlight) // Changed from .white
                                
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.text)
                            }
                        }
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText)
                        
                        // Use place.location.name
                        Text(place.location.name)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                            // Allow wrapping
                    }
                    
                    // Wishlist button - Action now defined internally
                    Button {
                        // Create minimal Activity object needed for ViewModel function
                        let activityForToggle = Activity(
                            id: place.id,
                            name: place.name,
                            type: ActivityType(rawValue: place.types.first ?? "") ?? .other,
                            location: place.location
                        )
                        // Call ViewModel function within a Task
                        Task {
                            await activityViewModel.toggleWantToDo(activity: activityForToggle)
                        }
                    } label: {
                        // Check wishlist status internally
                        let isWishlisted = activityViewModel.isWantToDo(activity: Activity(id: place.id)) // Check using ID
                        HStack {
                            Image(systemName: isWishlisted ? "heart.fill" : "heart")
                                .foregroundColor(isWishlisted ? ColorTheme.highlight : ColorTheme.lightText)
                            
                            Text(isWishlisted ? "Saved" : "Save")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.text)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorTheme.primaryLight.opacity(0.3)) // Changed background
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } // End Vstack for text content
                .padding(12)
            } // End Vstack for card body
            // Removed fixed height to allow natural sizing
        } // End RoundedCard
        // Removed activityColor computed property
    } // End body

    // Helper function to determine activity icon from place types (Moved inside struct)
    private func activityIcon(from types: [String]) -> String {
        if types.contains("park") { return "leaf.fill" }
        if types.contains("playground") { return "figure.play" }
        if types.contains("museum") { return "building.columns.fill" }
        if types.contains("library") { return "book.fill" }
        if types.contains("swimming_pool") { return "figure.pool.swim" }
        if types.contains("stadium") || types.contains("sports_complex") { return "sportscourt.fill" }
        if types.contains("zoo") { return "pawprint.fill" }
        if types.contains("aquarium") { return "drop.fill" }
        if types.contains("movie_theater") { return "film.fill" }
        if types.contains("amusement_park") { return "ferriswheel" }
        // Add more mappings as needed
        return "mappin.circle.fill" // Default icon
    }
} // End struct PopularActivityCard

// Add Activity extension for minimal init used in wishlist check (Ensure this is at file scope)
extension Activity {
    init(id: String) {
        self.init(id: id, name: "", type: .other, location: Location(name: "", address: "", latitude: 0, longitude: 0))
    }
}
