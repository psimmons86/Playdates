import SwiftUI
import Foundation

struct PopularActivityCard: View {
    let activity: Activity
    let onAddToWishlist: () -> Void
    let isInWishlist: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        GradientCard(
            gradientColors: [
                activityColor,
                activityColor.opacity(0.7)
            ]
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Activity icon
                HStack {
                    Spacer()
                    
                    Image(systemName: activityIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .padding(.top, 12)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Activity details
                VStack(alignment: .leading, spacing: 8) {
                    // Title and rating
                    HStack {
                        Text(activity.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            // Allow wrapping
                        
                        Spacer()
                        
                        if let rating = activity.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(activity.location.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            // Allow wrapping
                    }
                    
                    // Wishlist button
                    Button(action: onAddToWishlist) {
                        HStack {
                            Image(systemName: isInWishlist ? "heart.fill" : "heart")
                                .foregroundColor(isInWishlist ? .white : .white.opacity(0.9))
                            
                            Text(isInWishlist ? "Saved" : "Save")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
            }
            // Removed fixed height to allow natural sizing
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
