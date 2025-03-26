import SwiftUI
import Combine
import CoreLocation

struct ExploreActivityDetailView: View {
    let activity: Activity
    @ObservedObject var viewModel = ActivityViewModel.shared
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @State private var showingCreatePlaydateSheet = false
    @State private var isCreatingPlaydate = false
    @State private var playdateCreationError: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Activity icon
                HStack {
                    Spacer()
                    
                    activityIcon
                        .frame(width: 120, height: 120)
                    
                    Spacer()
                }
                .padding(.vertical)
                
                // Activity details
                VStack(alignment: .leading, spacing: 16) {
                    // Name and type
                    Text(activity.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text(activity.type.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Rating
                    if let rating = activity.rating {
                        ratingView(rating: rating)
                    }
                    
                    Divider()
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text(activity.description)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    // Location
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.location.name)
                            .fontWeight(.medium)
                        
                        Text(activity.location.address)
                            .foregroundColor(.secondary)
                        
                        // Distance from user
                        if let userLocation = LocationManager.shared.location {
                            let activityLocation = CLLocation(
                                latitude: activity.location.latitude,
                                longitude: activity.location.longitude
                            )
                            let distanceInMeters = userLocation.distance(from: activityLocation)
                            let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
                            
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.blue)
                                
                                // Format distance based on how far away it is
                                if distanceInMiles < 0.1 {
                                    Text("Nearby")
                                        .foregroundColor(.blue)
                                } else if distanceInMiles < 10 {
                                    Text(String(format: "%.1f miles from your location", distanceInMiles))
                                        .foregroundColor(.blue)
                                } else {
                                    Text(String(format: "%.0f miles from your location", distanceInMiles))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // Map placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                        )
                }
                .padding(.horizontal)
                
                // Create Playdate Button
                Button(action: {
                    showingCreatePlaydateSheet = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18))
                        Text("Create Playdate Here")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Error message if playdate creation fails
                if let error = playdateCreationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Contact information
                if activity.website != nil || activity.phoneNumber != nil {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                            .padding(.horizontal)
                        
                        if let website = activity.website {
                            websiteButton(website: website)
                        }
                        
                        if let phoneNumber = activity.phoneNumber {
                            phoneButton(phoneNumber: phoneNumber)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: favoriteButton)
        .sheet(isPresented: $showingCreatePlaydateSheet) {
            createPlaydateView
        }
    }
    
    private var createPlaydateView: some View {
        NavigationView {
            CreatePlaydateFromActivityView(
                activity: activity,
                isPresented: $showingCreatePlaydateSheet,
                onPlaydateCreated: { playdate in
                    showingCreatePlaydateSheet = false
                    playdateCreationError = nil
                }
            )
            .environmentObject(playdateViewModel)
            .navigationTitle("Create Playdate")
            .navigationBarItems(trailing: Button("Cancel") {
                showingCreatePlaydateSheet = false
            })
        }
    }
    
    private var favoriteButton: some View {
        Button(action: {
            viewModel.toggleFavorite(for: activity)
        }) {
            Image(systemName: viewModel.isFavorite(activity: activity) ? "heart.fill" : "heart")
                .foregroundColor(viewModel.isFavorite(activity: activity) ? .red : .gray)
                .font(.system(size: 22))
        }
    }
    
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 120)
            case .museum:
                ActivityIcons.MuseumIcon(size: 120)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 120)
            case .library:
                ActivityIcons.LibraryIcon(size: 120)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 120)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 120)
            case .zoo:
                ActivityIcons.ZooIcon(size: 120)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 120)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 120)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 120)
            default:
                ActivityIcons.OtherActivityIcon(size: 120)
            }
        }
    }
    
    private func ratingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            
            Text(String(format: "%.1f", rating))
                .fontWeight(.medium)
            
            if let reviewCount = activity.reviewCount {
                Text("(\(reviewCount) reviews)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func websiteButton(website: String) -> some View {
        Button(action: {
            if let url = URL(string: website) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "globe")
                Text(website)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private func phoneButton(phoneNumber: String) -> some View {
        Button(action: {
            let formattedNumber = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if let url = URL(string: "tel://\(formattedNumber)") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "phone")
                Text(phoneNumber)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct CreatePlaydateFromActivityView: View {
    let activity: Activity
    @Binding var isPresented: Bool
    var onPlaydateCreated: (Playdate) -> Void
    
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var endDate = Date().addingTimeInterval(86400 + 7200) // 2 hours after start
    @State private var isPublic = true
    @State private var minAge: String = ""
    @State private var maxAge: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity info section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create a playdate at:")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    HStack(spacing: 16) {
                        // Activity icon
                        activityIcon
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            Text(activity.type.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(activity.location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Playdate details form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Playdate Details")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        TextField("Enter title", text: $title)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Date and time pickers
                    VStack(alignment: .leading, spacing: 16) {
                        // Start date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Date & Time")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            DatePicker("", selection: $startDate)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .onChange(of: startDate) { newValue in
                                    // Ensure end date is after start date
                                    if endDate <= newValue {
                                        endDate = newValue.addingTimeInterval(7200) // 2 hours later
                                    }
                                }
                        }
                        
                        // End date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Date & Time")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                        }
                    }
                    
                    // Age range
                    HStack(spacing: 16) {
                        // Min age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Min Age")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            TextField("Optional", text: $minAge)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Max age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Age")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            TextField("Optional", text: $maxAge)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Public toggle
                    Toggle(isOn: $isPublic) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Public Playdate")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            Text("Anyone can discover and join this playdate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.primary))
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Create button
                Button(action: createPlaydate) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .cornerRadius(12)
                    } else {
                        Text("Create Playdate")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading || !isFormValid)
                .padding(.top, 16)
            }
            .padding()
        }
        .onAppear {
            // Pre-fill title and description based on activity
            title = "Playdate at \(activity.name)"
            description = "Join me for a playdate at \(activity.name)! \(activity.description)"
        }
    }
    
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .park:
                ActivityIcons.ParkIcon(size: 60)
            case .museum:
                ActivityIcons.MuseumIcon(size: 60)
            case .playground:
                ActivityIcons.PlaygroundIcon(size: 60)
            case .library:
                ActivityIcons.LibraryIcon(size: 60)
            case .swimmingPool:
                ActivityIcons.SwimmingIcon(size: 60)
            case .sportingEvent:
                ActivityIcons.SportsIcon(size: 60)
            case .zoo:
                ActivityIcons.ZooIcon(size: 60)
            case .aquarium:
                ActivityIcons.AquariumIcon(size: 60)
            case .movieTheater:
                ActivityIcons.MovieTheaterIcon(size: 60)
            case .themePark:
                ActivityIcons.ThemeParkIcon(size: 60)
            default:
                ActivityIcons.OtherActivityIcon(size: 60)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        startDate < endDate &&
        validateAgeRange()
    }
    
    private func validateAgeRange() -> Bool {
        // If both fields are empty, that's valid (no age restriction)
        if minAge.isEmpty && maxAge.isEmpty {
            return true
        }
        
        // If only one field has a value, that's valid
        if minAge.isEmpty || maxAge.isEmpty {
            return true
        }
        
        // If both fields have values, min should be less than or equal to max
        if let min = Int(minAge), let max = Int(maxAge) {
            return min <= max
        }
        
        // If we can't parse the values as integers, it's invalid
        return false
    }
    
    private func createPlaydate() {
        guard let currentUserId = playdateViewModel.currentUserId else {
            errorMessage = "You must be signed in to create a playdate"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Parse age range
        let minAgeInt = minAge.isEmpty ? nil : Int(minAge)
        let maxAgeInt = maxAge.isEmpty ? nil : Int(maxAge)
        
        // Create playdate object
        let newPlaydate = Playdate(
            hostID: currentUserId,
            title: title,
            description: description,
            activityType: activity.type.rawValue,
            location: activity.location,
            address: activity.location.address,
            startDate: startDate,
            endDate: endDate,
            minAge: minAgeInt,
            maxAge: maxAgeInt,
            attendeeIDs: [currentUserId], // Host is automatically an attendee
            isPublic: isPublic,
            createdAt: Date()
        )
        
        // Save to Firebase
        playdateViewModel.createPlaydate(newPlaydate) { result in
            isLoading = false
            
            switch result {
            case .success(let playdate):
                // Call the completion handler with the created playdate
                onPlaydateCreated(playdate)
                isPresented = false
                
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Extension for PlaydateViewModel to provide a current user ID (stub for now)
extension PlaydateViewModel {
    var currentUserId: String? {
        // In a real implementation, this would get the current user ID from authentication
        // For this placeholder, we'll return a static ID
        return "current-user-id"
    }
}

struct ExploreActivityDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivity = Activity(
            id: "mock-id",
            name: "Central Park",
            description: "A beautiful park in the heart of the city",
            type: .park,
            location: Location(
                id: "loc-1",
                name: "Central Park",
                address: "New York, NY",
                latitude: 40.7812,
                longitude: -73.9665
            ),
            rating: 4.5
        )
        
        NavigationView {
            ExploreActivityDetailView(activity: mockActivity)
                .environmentObject(PlaydateViewModel.shared)
        }
    }
}
