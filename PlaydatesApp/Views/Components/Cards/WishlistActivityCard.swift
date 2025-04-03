import SwiftUI
import Foundation

struct WishlistActivityCard: View {
    let activity: Activity
    // Removed onRemove parameter
    @EnvironmentObject var activityViewModel: ActivityViewModel // Inject ViewModel
    
    // Removed @State private var isAnimating = false
    
    var body: some View {
        RoundedCard { // Using RoundedCard with default white background
            HStack(spacing: 16) {
                // Activity icon
                Image(systemName: activityIcon)
                    .font(.system(size: 24))
                    .foregroundColor(ColorTheme.primary) // Use theme color
                    .frame(minWidth: 40, idealWidth: 50, maxWidth: 50, minHeight: 40, idealHeight: 50, maxHeight: 50)
                    .background(ColorTheme.primaryLight.opacity(0.3)) // Use theme color background
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Activity details
                VStack(alignment: .leading, spacing: 4) {
                    // Title and rating
                    HStack {
                        Text(activity.name)
                            .font(.headline)
                            .foregroundColor(ColorTheme.text) // Use theme color
                            // Allow wrapping
                        
                        Spacer()
                        
                        if let rating = activity.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(ColorTheme.highlight) // Use theme color
                                
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.text) // Use theme color
                            }
                        }
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText) // Use theme color
                        
                        Text(activity.location.name)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText) // Use theme color
                            // Allow wrapping
                    }
                    
                    // Activity type
                    HStack {
                        Image(systemName: "tag")
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText) // Use theme color
                        
                        Text(activity.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText) // Use theme color
                    }
                }
                
                // Wishlist button (replaces remove button)
                Button {
                    Task {
                        await activityViewModel.toggleWantToDo(activity: activity)
                    }
                } label: {
                    let isWishlisted = activityViewModel.isWantToDo(activity: activity)
                    Image(systemName: isWishlisted ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isWishlisted ? ColorTheme.highlight : ColorTheme.lightText) // Use theme colors
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
        }
    }
    
    // Helper to determine activity icon
    private var activityIcon: String {
        switch activity.type {
        case .park:
            return "leaf.fill"
        case .museum:
            return "building.columns.fill"
        case .playground:
            return "figure.play"
        case .library:
            return "book.fill"
        case .swimmingPool:
            return "figure.pool.swim"
        case .sportingEvent:
            return "sportscourt.fill"
        case .zoo:
            return "pawprint.fill"
        case .aquarium:
            return "drop.fill"
        case .movieTheater:
            return "film.fill"
        case .themePark:
            return "ferriswheel"
        default:
            return "mappin.circle.fill"
        }
    }
    
    // Helper to determine activity color
    private var activityColor: Color {
        switch activity.type {
        case .park:
            return Color(red: 0.02, green: 0.84, blue: 0.63)
        case .museum, .library:
            return ColorTheme.accent
        case .playground, .zoo:
            return ColorTheme.highlight
        case .swimmingPool, .aquarium:
            return Color(red: 0.07, green: 0.54, blue: 0.7)
        case .sportingEvent, .themePark:
            return Color(red: 0.94, green: 0.28, blue: 0.44)
        case .movieTheater:
            return Color(red: 0.46, green: 0.47, blue: 0.93)
        default:
            return ColorTheme.primary
        }
    }
}
