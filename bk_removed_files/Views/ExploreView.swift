import SwiftUI
import MapKit

struct ExploreView: View {
    @EnvironmentObject private var activityViewModel: ActivityViewModel
    @EnvironmentObject private var locationManager: LocationManager
    
    @State private var searchText = ""
    @State private var selectedActivityType: ActivityType?
    @State private var showingFilters = false
    @State private var mapRegion: MKCoordinateRegion?
    @State private var viewMode: ViewMode = .list
    
    enum ViewMode {
        case list
        case map
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Activity type filter
                activityTypeFilter
                
                // Content
                if viewMode == .list {
                    listView
                } else {
                    mapView
                }
            }
            .navigationTitle("Explore")
            .navigationBarItems(trailing: viewModeToggle)
            .onAppear {
                if let location = locationManager.location {
                    activityViewModel.fetchNearbyActivities(location: location)
                    mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ColorTheme.text.opacity(0.5))
            
            TextField("Search activities, parks, museums...", text: $searchText)
                .foregroundColor(ColorTheme.text)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ColorTheme.text.opacity(0.5))
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var activityTypeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ActivityType.allCases) { type in
                    Button(action: {
                        if selectedActivityType == type {
                            selectedActivityType = nil
                        } else {
                            selectedActivityType = type
                        }
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.system(size: 14))
                            
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedActivityType == type ? ColorTheme.primary : Color.gray.opacity(0.1))
                        .foregroundColor(selectedActivityType == type ? .white : ColorTheme.text)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if activityViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if filteredActivities.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredActivities) { activity in
                        NavigationLink(destination: ActivityDetailView(activity: activity)) {
                            ActivityListItem(activity: activity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    private var mapView: some View {
        ZStack {
            if let region = mapRegion {
                Map(coordinateRegion: .constant(region), annotationItems: filteredActivities) { activity in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: activity.location.latitude, longitude: activity.location.longitude)) {
                        VStack {
                            Image(systemName: activity.type.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(ColorTheme.primary)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                            
                            Text(activity.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(4)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 1)
                        }
                        .onTapGesture {
                            // Navigate to activity detail
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            } else {
                ProgressView()
            }
            
            // Current location button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let location = locationManager.location {
                            mapRegion = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ColorTheme.primary)
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 50))
                .foregroundColor(ColorTheme.primary.opacity(0.7))
            
            Text("No Activities Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text("Try adjusting your filters or search terms.")
                .font(.body)
                .foregroundColor(ColorTheme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                searchText = ""
                selectedActivityType = nil
            }) {
                Text("Clear Filters")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(ColorTheme.primary)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var viewModeToggle: some View {
        Button(action: {
            viewMode = viewMode == .list ? .map : .list
        }) {
            Image(systemName: viewMode == .list ? "map" : "list.bullet")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary)
                .padding(8)
                .background(ColorTheme.primary.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredActivities: [Activity] {
        var activities = activityViewModel.activities
        
        // Filter by search text
        if !searchText.isEmpty {
            activities = activities.filter { activity in
                activity.name.lowercased().contains(searchText.lowercased()) ||
                activity.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Filter by activity type
        if let type = selectedActivityType {
            activities = activities.filter { $0.type == type }
        }
        
        return activities
    }
}

struct ActivityListItem: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Activity image or icon
            ZStack {
                if let firstPhotoURL = activity.photos?.first, !firstPhotoURL.isEmpty {
                    AsyncImage(url: URL(string: firstPhotoURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    Image(systemName: activity.type.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.gray.opacity(0.5))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            Image(systemName: activity.type.icon)
                                .font(.system(size: 24))
                                .foregroundColor(Color.gray.opacity(0.5))
                        )
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                Text(activity.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondary)
                
                // Rating if available
                if let rating = activity.rating {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(star <= Int(rating) ? ColorTheme.accent : Color.gray.opacity(0.3))
                        }
                        
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(ColorTheme.text.opacity(0.7))
                    }
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                    
                    Text(activity.location.name)
                        .font(.caption)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivityDetailView: View {
    let activity: Activity
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity image or placeholder
                ZStack {
                    if let firstPhotoURL = activity.photos?.first, !firstPhotoURL.isEmpty {
                        AsyncImage(url: URL(string: firstPhotoURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        Image(systemName: activity.type.icon)
                                            .font(.system(size: 50))
                                            .foregroundColor(Color.gray.opacity(0.5))
                                    )
                            @unknown default:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                Image(systemName: activity.type.icon)
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.gray.opacity(0.5))
                            )
                    }
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title and type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.text)
                        
                        HStack {
                            Text(activity.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorTheme.primary)
                                .cornerRadius(20)
                            
                            if let rating = activity.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.accent)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(ColorTheme.text)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(ColorTheme.text)
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(ColorTheme.secondary)
                            
                            Text(activity.location.address)
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.text.opacity(0.8))
                        }
                        
                        // Mini map
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 150)
                            .cornerRadius(12)
                            .overlay(
                                Text("Map View")
                                    .foregroundColor(ColorTheme.text.opacity(0.5))
                            )
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(ColorTheme.text)
                        
                        Text(activity.description)
                            .font(.body)
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                    
                    // Additional info
                    if activity.ageRange != nil || activity.priceRange != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Information")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            if let ageRange = activity.ageRange {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(ColorTheme.secondary)
                                    
                                    Text("Ages \(ageRange.min)-\(ageRange.max)")
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.text.opacity(0.8))
                                }
                            }
                            
                            if let priceRange = activity.priceRange {
                                HStack {
                                    Image(systemName: "dollarsign.circle")
                                        .foregroundColor(ColorTheme.secondary)
                                    
                                    Text(priceRange.description)
                                        .font(.subheadline)
                                        .foregroundColor(ColorTheme.text.opacity(0.8))
                                }
                            }
                        }
                    }
                    
                    // Amenities
                    if let amenities = activity.amenities, !amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amenities")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(amenities, id: \.self) { amenity in
                                    HStack {
                                        Image(systemName: amenity.icon)
                                            .foregroundColor(ColorTheme.secondary)
                                        
                                        Text(amenity.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(ColorTheme.text.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Action buttons
                    HStack {
                        Button(action: {
                            // Create playdate
                        }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Create Playdate")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Get directions
                        }) {
                            HStack {
                                Image(systemName: "map")
                                Text("Directions")
                            }
                            .font(.headline)
                            .foregroundColor(ColorTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environmentObject(ActivityViewModel())
            .environmentObject(LocationManager())
    }
}
