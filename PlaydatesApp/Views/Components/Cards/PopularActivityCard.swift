import SwiftUI
import Foundation

struct PopularActivityCard: View {
    let activity: Activity
    let onAddToWishlist: () -> Void
    let isInWishlist: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Activity image or placeholder
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        activityColor,
                        activityColor.opacity(0.7)
                    ]),
                    startPoint: isAnimating ? .topLeading : .bottomTrailing,
                    endPoint: isAnimating ? .bottomTrailing : .topLeading
                )
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12, corners: [.topLeft, .topRight]))
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
                
                // Activity icon
                Image(systemName: activityIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Activity details
            VStack(alignment: .leading, spacing: 8) {
                // Title and rating
                HStack {
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let rating = activity.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme.highlight)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                        }
                    }
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text(activity.location.name)
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                }
                
                // Wishlist button
                Button(action: onAddToWishlist) {
                    HStack {
                        Image(systemName: isInWishlist ? "heart.fill" : "heart")
                            .foregroundColor(isInWishlist ? .red : ColorTheme.lightText)
                        
                        Text(isInWishlist ? "Saved" : "Save")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isInWishlist ? ColorTheme.primary : ColorTheme.lightText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInWishlist ? ColorTheme.primary : ColorTheme.lightText.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
