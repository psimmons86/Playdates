import SwiftUI
import CoreLocation

// MARK: - Placeholder FavoriteButton (Replace with actual implementation)
struct FavoriteButton: View {
    let activity: Activity
    var listStyle: Bool = false // Example parameter based on usage
    @StateObject private var viewModel = ActivityViewModel.shared // Assuming access

    var body: some View {
        Button(action: {
            viewModel.toggleFavorite(for: activity)
        }) {
            Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : ColorTheme.lightText)
                .font(.system(size: listStyle ? 20 : 18)) // Adjust size based on style
                .padding(listStyle ? 6: 8)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
    }
}


// Use components from their dedicated files
// These are already imported via the main module

// MARK: - Activity Card Components
struct EnhancedActivityGridCard: View {
    let activity: Activity
    @StateObject private var viewModel = ActivityViewModel.shared
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {
                VStack(alignment: .leading, spacing: 6) {
                    // Activity image/icon
                    ZStack {
                        // Gradient background
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorForActivityType(activity.type).opacity(0.2),
                                        colorForActivityType(activity.type).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 70)
                        
                        activityIcon
                            .frame(width: 40, height: 40)
                    }
                    .frame(height: 70)
                    .cornerRadius(12)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 5) {
                        Text(activity.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.text)
                            .lineLimit(1)
                        
                        Text(activity.type.title)
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText)
                            .lineLimit(1)
                        
                        // Info row
                        HStack(spacing: 8) {
                            // Rating
                            if let rating = activity.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 10))
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(ColorTheme.text)
                                }
                            }
                            
                            // Distance
                            if let userLocation = LocationManager.shared.location {
                                let activityLocation = CLLocation(
                                    latitude: activity.location.latitude,
                                    longitude: activity.location.longitude
                                )
                                let distanceInMeters = userLocation.distance(from: activityLocation)
                                let distanceInMiles = distanceInMeters / 1609.34
                                
                                HStack(spacing: 2) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(colorForActivityType(activity.type))
                                        .font(.system(size: 9))
                                    
                                    Text(formatDistance(distanceInMiles))
                                        .font(.system(size: 10))
                                        .foregroundColor(ColorTheme.lightText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .frame(minHeight: 160)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in self.isPressed = true }
                    .onEnded { _ in self.isPressed = false }
            )

            // Favorite button with improved positioning and animation
            FavoriteButton(activity: activity)
                .offset(x: -5, y: 5)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    private var activityIcon: some View {
         SwiftUI.Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 40)
            case .museum:
                ActivityIcons.MuseumIcon(size: 40)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 40)
            case .library:
                ActivityIcons.LibraryIcon(size: 40)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 40)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 40)
            case .zoo:
                ActivityIcons.ZooIcon(size: 40)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 40)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 40)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 40)
            default:
                ActivityIcons.OtherActivityIcon(size: 40)
            }
        }
    }
    
    private func colorForActivityType(_ type: ActivityType) -> Color {
        switch type {
        case .park, .playground:
            return .green
        case .museum, .library:
            return .blue
        case .swimmingPool, .aquarium:
            return Color(red: 0.0, green: 0.7, blue: 0.9)
        case .zoo:
            return .orange
        case .movieTheater:
            return .purple
        case .themePark:
            return .red
        default:
            return ColorTheme.primary
        }
    }
    
    private func formatDistance(_ distanceInMiles: Double) -> String {
        if distanceInMiles < 0.1 {
            return "Nearby"
        } else if distanceInMiles < 10 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
}

// MARK: - Enhanced List Card
struct EnhancedActivityListCard: View {
    let activity: Activity
    @StateObject private var viewModel = ActivityViewModel.shared
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: ExploreActivityDetailView(activity: activity)) {
                HStack(spacing: 14) {
                    // Activity icon with enhanced styling
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorForActivityType(activity.type).opacity(0.2),
                                        colorForActivityType(activity.type).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        activityIcon
                            .frame(width: 32, height: 32)
                    }
                    .frame(width: 56, height: 56)
                    
                    // Content with improved layout
                    VStack(alignment: .leading, spacing: 3) {
                        Text(activity.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ColorTheme.text)
                            .lineLimit(1)
                        
                        // Activity type with subtle indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colorForActivityType(activity.type))
                                .frame(width: 6, height: 6)
                            
                            Text(activity.type.title)
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                        
                        // Enhanced info row with consistent spacing
                        HStack(spacing: 12) {
                            if let rating = activity.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 11))
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(ColorTheme.text)
                                    
                                    if let reviewCount = activity.reviewCount, reviewCount > 0 {
                                        Text("(\(reviewCount))")
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.lightText)
                                    }
                                }
                            }
                            
                            if let userLocation = LocationManager.shared.location {
                                let activityLocation = CLLocation(
                                    latitude: activity.location.latitude,
                                    longitude: activity.location.longitude
                                )
                                let distanceInMeters = userLocation.distance(from: activityLocation)
                                let distanceInMiles = distanceInMeters / 1609.34
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(colorForActivityType(activity.type))
                                        .font(.system(size: 11))
                                    
                                    Text(formatDistance(distanceInMiles))
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.text)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    // Animated chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorTheme.lightText)
                        .opacity(isPressed ? 0.5 : 1.0)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: isPressed)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in self.isPressed = true }
                    .onEnded { _ in self.isPressed = false }
            )
            
            // Enhanced favorite button
            FavoriteButton(
                activity: activity,
                listStyle: true
            )
            .offset(x: -5, y: 5)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
    }
    
    private var activityIcon: some View {
        SwiftUI.Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 32)
            case .museum:
                ActivityIcons.MuseumIcon(size: 32)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 32)
            case .library:
                ActivityIcons.LibraryIcon(size: 32)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 32)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 32)
            case .zoo:
                ActivityIcons.ZooIcon(size: 32)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 32)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 32)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 32)
            default:
                ActivityIcons.OtherActivityIcon(size: 32)
            }
        }
    }
    
    private func colorForActivityType(_ type: ActivityType) -> Color {
        switch type {
        case .park, .playground:
            return .green
        case .museum, .library:
            return .blue
        case .swimmingPool, .aquarium:
            return Color(red: 0.0, green: 0.7, blue: 0.9)
        case .zoo:
            return .orange
        case .movieTheater:
            return .purple
        case .themePark:
            return .red
        default:
            return ColorTheme.primary
        }
    }
    
    private func formatDistance(_ distanceInMiles: Double) -> String {
        if distanceInMiles < 0.1 {
            return "Nearby"
        } else if distanceInMiles < 10 {
            return String(format: "%.1f mi", distanceInMiles)
        } else {
            return String(format: "%.0f mi", distanceInMiles)
        }
    }
}

// MARK: - Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.white.opacity(0.3)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: phase - 0.3),
                                            .init(color: .white.opacity(0.7), location: phase),
                                            .init(color: .clear, location: phase + 0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: geometry.size.width * 3)
                                .offset(x: -2 * geometry.size.width + phase * 3 * geometry.size.width)
                        )
                }
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    self.phase = 1
                }
            }
    }
}
