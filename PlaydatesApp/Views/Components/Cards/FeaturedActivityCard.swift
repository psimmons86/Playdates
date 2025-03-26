import SwiftUI
import Foundation

struct FeaturedActivityCard: View {
    let activity: Activity
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    activityColor,
                    activityColor.opacity(0.7),
                    activityColor.opacity(0.5)
                ]),
                startPoint: isAnimating ? .topLeading : .bottomTrailing,
                endPoint: isAnimating ? .bottomTrailing : .topLeading
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            // Decorative elements
            ZStack {
                // Floating circles
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: CGFloat([60, 40, 30][i]))
                        .offset(
                            x: CGFloat([120, -80, 60][i]),
                            y: CGFloat([-40, 60, -80][i])
                        )
                        .blur(radius: 3)
                }
                
                // Activity icon
                Image(systemName: activityIcon)
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 100, y: -30)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(activity.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(activity.location.name)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Rating
                if let rating = activity.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .foregroundColor(.white)
                        }
                        
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                // Featured badge
                Text("FEATURED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .padding(20)
        }
        .frame(height: 200)
        .cornerRadius(16)
        .shadow(color: activityColor.opacity(0.5), radius: 10, x: 0, y: 5)
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
