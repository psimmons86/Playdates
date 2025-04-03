import SwiftUI
import CoreLocation // Needed for ExploreActivityCard distance calculation

// MARK: - Explore Search Bar
struct ExploreSearchBar: View {
    @Binding var text: String
    var placeholder: String
    @State private var isFocused = false
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? ColorTheme.primary : Color.gray)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    isFocused ?
                        Animation.spring(response: 0.3, dampingFraction: 0.6).repeatCount(1) :
                        .default,
                    value: isAnimating
                )

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(ColorTheme.darkText)
                .submitLabel(.search)
                .onTapGesture {
                    isFocused = true
                    isAnimating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                }

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ColorTheme.lightText)
                        .opacity(0.8)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: text)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: isFocused ?
                        ColorTheme.primary.opacity(0.2) :
                        Color.black.opacity(0.05),
                       radius: isFocused ? 4 : 2,
                       x: 0,
                       y: isFocused ? 2 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? ColorTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isFocused = false
            }
        }
        // Remember to remove observer onDisappear if needed in the parent view
    }
}

// MARK: - Explore Category Button
struct ExploreCategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false

    private var categoryColor: Color {
        // Color logic based on category title
        switch category {
            case ActivityType.park.title, ActivityType.hikingTrail.title: return Color(hex: "4CAF50") // Green
            case ActivityType.museum.title, ActivityType.library.title: return Color(hex: "2196F3") // Blue
            case ActivityType.playground.title, ActivityType.indoorPlayArea.title: return Color(hex: "FFC107") // Yellow
            case ActivityType.swimmingPool.title, ActivityType.beach.title: return Color(hex: "00BCD4") // Cyan
            case ActivityType.sportingEvent.title: return Color(hex: "F44336") // Red
            case ActivityType.zoo.title, ActivityType.aquarium.title: return Color(hex: "9C27B0") // Purple
            case ActivityType.movieTheater.title: return Color(hex: "795548") // Brown
            case ActivityType.themePark.title, ActivityType.summerCamp.title: return Color(hex: "FF9800") // Orange
            case "All": return ColorTheme.primary
            default: return ColorTheme.primaryDark // Fallback for .other or unknown
        }
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? categoryColor.opacity(0.2) : Color.white)
                        .frame(width: 32, height: 32)
                    categoryIcon
                        .foregroundColor(isSelected ? categoryColor : ColorTheme.lightText)
                        .frame(width: 18, height: 18)
                }
                Text(category)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? categoryColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? categoryColor : ColorTheme.darkText)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture { // Apply press effect on tap
             withAnimation { isPressed = true }
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                 withAnimation { isPressed = false }
             }
        }
    }

    private var categoryIcon: some View {
        // Using ActivityIcons based on category title
        SwiftUI.Group {
             switch category {
                 case ActivityType.park.title: ActivityIcons.ParkIcon(size: 18)
                 case ActivityType.museum.title: ActivityIcons.MuseumIcon(size: 18)
                 case ActivityType.playground.title: ActivityIcons.PlaygroundIcon(size: 18)
                 case ActivityType.library.title: ActivityIcons.LibraryIcon(size: 18)
                 case ActivityType.swimmingPool.title: ActivityIcons.SwimmingIcon(size: 18)
                 case ActivityType.sportingEvent.title: ActivityIcons.SportsIcon(size: 18)
                 case ActivityType.zoo.title: ActivityIcons.ZooIcon(size: 18)
                 case ActivityType.aquarium.title: ActivityIcons.AquariumIcon(size: 18)
                 case ActivityType.movieTheater.title: ActivityIcons.MovieTheaterIcon(size: 18)
                 case ActivityType.themePark.title: ActivityIcons.ThemeParkIcon(size: 18)
                 case ActivityType.hikingTrail.title: Image(systemName: "figure.hiking") // Example
                 case ActivityType.indoorPlayArea.title: Image(systemName: "figure.play") // Example
                 case ActivityType.beach.title: Image(systemName: "figure.pool.swim") // Example
                 case ActivityType.summerCamp.title: Image(systemName: "tent.fill") // Example
                 case "All": Image(systemName: "square.grid.2x2.fill")
                 default: ActivityIcons.OtherActivityIcon(size: 18)
             }
        }
    }
}

// MARK: - Explore Activity Card (Redesigned)
struct ExploreActivityCard: View {
    let activity: Activity
    @EnvironmentObject var activityViewModel: ActivityViewModel // Renamed for clarity
    @EnvironmentObject var playdateViewModel: PlaydateViewModel // Add PlaydateViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add AuthViewModel

    var body: some View {
        // Pass the playdateViewModel to the destination view
        NavigationLink(destination: ExploreActivityDetailView(activity: activity).environmentObject(playdateViewModel)) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Section
                ZStack(alignment: .topTrailing) {
                    activityImageView
                        .frame(height: 120) // Fixed height for image
                        .clipped()

                    // Favorite button
                    Button {
                        // Corrected argument label to 'activity:'
                        Task { // Use Task for async function
                            await activityViewModel.toggleFavorite(activity: activity) // Use renamed viewModel
                        }
                        // Add haptic feedback if desired
                    } label: {
                        Image(systemName: activityViewModel.isFavorite(activity: activity) ? "heart.fill" : "heart") // Use renamed viewModel
                            .foregroundColor(activityViewModel.isFavorite(activity: activity) ? .red : .white) // Use renamed viewModel
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }

                // Content Section
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .lineLimit(1)
                    
                    // Description (Added)
                    // Conditionally display description if it's not nil or empty
                    if let description = activity.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                            .lineLimit(2) // Limit description lines on card
                    }

                    Text(activity.type.title)
                        .font(.caption)
                        .foregroundColor(ColorTheme.primary)

                    // Distance
                    if let userLocation = LocationManager.shared.location {
                        let activityLocation = CLLocation(latitude: activity.location.latitude, longitude: activity.location.longitude)
                        let distanceInMeters = userLocation.distance(from: activityLocation)
                        let distanceInMiles = distanceInMeters / 1609.34

                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(ColorTheme.lightText)
                            Text(formatDistance(distanceInMiles))
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                    }

                    // Rating
                    if let rating = activity.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkText)
                            if let reviewCount = activity.reviewCount, reviewCount > 0 {
                                Text("(\(reviewCount))")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.lightText)
                            }
                        }
                    }
                }
                .padding(12) // Padding for the text content
            }
            .background(Color.white) // White background for the card
            .cornerRadius(16) // Rounded corners
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2) // Subtle shadow
        }
        .buttonStyle(PlainButtonStyle()) // Make the whole card tappable
    }

    // Image View Builder (Updated to prioritize photoReference)
    @ViewBuilder
    private var activityImageView: some View {
        // Prioritize Google Places photoReference
        if let photoRef = activity.photoReference, let url = GooglePlacesService.shared.getPhotoURL(photoReference: photoRef, maxWidth: 400) {
             AsyncImage(url: url) { phase in
                 switch phase {
                 case .empty:
                     ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                     defaultImagePlaceholder
                 @unknown default:
                     defaultImagePlaceholder
                 }
             }
        // Fallback to Firebase photos array
        } else if let photos = activity.photos, let firstPhotoUrlString = photos.first, let url = URL(string: firstPhotoUrlString) {
             AsyncImage(url: url) { phase in
                 switch phase {
                 case .empty:
                     ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                 case .success(let image):
                     image.resizable().aspectRatio(contentMode: .fill)
                 case .failure:
                     defaultImagePlaceholder
                 @unknown default:
                     defaultImagePlaceholder
                 }
             }
         } else {
             defaultImagePlaceholder
         }
    }

    // Placeholder Image
    private var defaultImagePlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundColor(.secondary)
        }
    }

    // Distance Formatter
    private func formatDistance(_ distanceInMiles: Double) -> String {
        if distanceInMiles < 0.1 { return "Nearby" }
        else if distanceInMiles < 10 { return String(format: "%.1f mi", distanceInMiles) }
        else { return String(format: "%.0f mi", distanceInMiles) }
    }
}

// Helper for Hex Colors (if not defined elsewhere)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
