import SwiftUI
import Combine
import CoreLocation
import Firebase
import FirebaseAuth

struct ExploreActivityDetailView: View {
    let activity: Activity
    // Use the shared instance directly
    @ObservedObject var activityViewModel = ActivityViewModel.shared
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Add AuthViewModel from environment
    @EnvironmentObject var friendManagementViewModel: FriendManagementViewModel // Add FriendManagementViewModel
    @State private var showingCreatePlaydateSheet = false
    @State private var isCreatingPlaydate = false
    @State private var playdateCreationError: String? = nil
    @State private var isFetchingDetails = false // State to track detail fetching
    @State private var showingCheckInSheet = false // State for CheckInView sheet
    @State private var checkIns: [CheckIn] = [] // State to hold fetched check-ins
    @State private var isLoadingCheckIns = false // State for loading check-ins

    // Find the activity from the view model to get live updates
    private var liveActivity: Activity? {
        activityViewModel.activities.first { $0.id == activity.id } ??
        activityViewModel.nearbyActivities.first { $0.id == activity.id } ??
        activityViewModel.popularActivities.first { $0.id == activity.id } ??
        activity // Fallback to the initially passed activity
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) { // Use spacing 0 and manage padding manually

                // Activity Image
                activityImageView
                    .frame(height: 250)
                    .clipped()

                // Main Content Area with Padding
                VStack(alignment: .leading, spacing: 20) {

                    // Header: Name, Type, Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)

                        Text(activity.type.title)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if let rating = activity.rating {
                            ratingView(rating: rating)
                        }
                    }

                    Divider()

                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)

                        // Display Editorial Summary (fetched from Google Places) or fallback
                        if isFetchingDetails && liveActivity?.editorialSummary == nil {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        } else if let summary = liveActivity?.editorialSummary, !summary.isEmpty {
                            Text(summary)
                                .font(.body)
                                .foregroundColor(ColorTheme.darkText)
                                .fixedSize(horizontal: false, vertical: true) // Allow text wrapping
                        } else if let description = liveActivity?.description, !description.isEmpty {
                            // Fallback to original description if summary is empty/nil
                            Text(description)
                                .font(.body)
                                .foregroundColor(ColorTheme.darkText)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Description not available.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }

                    // Opening Hours Section (if available) - Use liveActivity
                    if let hours = liveActivity?.openingHours, !hours.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Opening Hours")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)

                            ForEach(hours, id: \.self) { hourString in
                                Text(hourString)
                                    .font(.footnote)
                                    .foregroundColor(ColorTheme.darkText)
                            }
                        }
                    }

                    // Features Section (if available) - Use liveActivity
                    if let features = activity.features, !features.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Features")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)

                            // Display features as tags or list
                            HStack(spacing: 8) {
                                ForEach(features, id: \.self) { feature in
                                    Text(feature)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(ColorTheme.accent.opacity(0.15))
                                        .foregroundColor(ColorTheme.accent)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }

                    Divider()

                    // Location Section - Use liveActivity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(liveActivity?.location.name ?? "Unknown Location")
                                .fontWeight(.medium)

                            Text(liveActivity?.location.address ?? "Address not available")
                                .foregroundColor(.secondary)

                            // Distance from user - Use liveActivity
                            if let userLocation = LocationManager.shared.location, let activityLoc = liveActivity?.location {
                                let activityCLLocation = CLLocation(
                                    latitude: activityLoc.latitude,
                                    longitude: activityLoc.longitude
                                )
                                let distanceInMeters = userLocation.distance(from: activityCLLocation)
                                let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles

                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(.blue)

                                    // Format distance based on how far away it is
                                    if distanceInMiles < 0.1 {
                                        Text("Nearby")
                                            .foregroundColor(.blue)
                                    } else if distanceInMiles < 10 {
                                        Text(String(format: "%.1f miles away", distanceInMiles))
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(String(format: "%.0f miles away", distanceInMiles))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }

                        // Map placeholder - More rounded
                        RoundedRectangle(cornerRadius: 16) // Increased corner radius
                            .fill(Color(.systemGray6)) // Lighter background
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "map")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            )
                    }

                    // Contact information (if available) - Use liveActivity
                    if liveActivity?.website != nil || liveActivity?.phoneNumber != nil {
                        Divider()
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact Information")
                                .font(.headline)
                                .foregroundColor(ColorTheme.darkPurple)

                            if let website = liveActivity?.website {
                                websiteButton(website: website)
                            }
                            if let phone = liveActivity?.phoneNumber {
                                phoneButton(phoneNumber: phone)
                            }
                        }
                    }

                    // Check-ins Section
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Check-ins")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)

                        if isLoadingCheckIns {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if checkIns.isEmpty {
                            Text("No one has checked in here yet.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            // Limit the number of check-ins shown initially if desired
                            ForEach(checkIns.prefix(5)) { checkIn in // Show latest 5
                                CheckInRowView(checkIn: checkIn)
                                Divider().padding(.leading, 52) // Indent divider
                            }
                            // Optionally add a "See All Check-ins" button
                        }
                    }

                    // Error message if playdate creation fails
                    if let error = playdateCreationError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }

                }
                .padding() // Add padding around the main content block
                .background(Color.white) // White background for the content area
                .cornerRadius(20, corners: [.topLeft, .topRight]) // Rounded top corners
                .offset(y: -20) // Pull content up slightly over the image bottom

            }

            // Create Playdate Button (Sticky at bottom or after content)
            // For simplicity, placing it after the content block for now
            Button {
                showingCreatePlaydateSheet = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Create Playdate Here")
                }
                .frame(maxWidth: .infinity) // Make button full width
            }
            .buttonStyle(PrimaryButtonStyle()) // Use correct button style
            .padding() // Add padding around the button
            .background(Color.white) // Ensure button background contrasts if needed

            // Add Check In Button below Create Playdate button
            checkInButton

        }
        .background(ColorTheme.background.edgesIgnoringSafeArea(.all)) // Background for the whole scroll view
        .navigationBarTitleDisplayMode(.inline)
        // Updated navigation bar items
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                wantToDoButton // Add Want to Do button
                favoriteButton // Keep Favorite button
            }
        }
        .sheet(isPresented: $showingCreatePlaydateSheet) {
            // Pass the potentially updated liveActivity to the sheet
            createPlaydateView(activityToUse: liveActivity ?? activity)
        }
        // Add sheet modifier for CheckInView
        // Add sheet modifier for CheckInView
        .sheet(isPresented: $showingCheckInSheet) {
            // Ensure we have a valid activity and access to AuthViewModel from the environment
            if let activityToCheckIn = liveActivity {
                // Use the correct initializer and pass the environment's AuthViewModel
                CheckInView(activity: activityToCheckIn, authViewModel: authViewModel)
                    .environmentObject(friendManagementViewModel) // Inject FriendManagementViewModel
                    // AuthViewModel is already passed via initializer and likely in environment too
            } else {
                // Handle case where activity is somehow nil (shouldn't happen here)
                Text("Error: Activity data missing.")
            }
        }
        .onAppear {
            // Fetch details if summary or hours are missing and ID exists
            if let activityID = liveActivity?.id, liveActivity?.editorialSummary == nil || liveActivity?.openingHours == nil {
                isFetchingDetails = true
                // Call the fetch function - UI will update when @Published properties change
                activityViewModel.fetchAndSetActivityDetails(activityID: activityID)
                // Set fetching state back to false after a delay or via a callback if needed
                // For simplicity, we'll rely on the view updating when liveActivity changes.
                // We might need a better way to track loading completion if needed for the ProgressView
                // For now, assume it finishes quickly or handle loading state more robustly if required.
                // Setting isFetchingDetails back to false might happen too quickly here.
                // A better approach might involve observing a loading state specific to this activity ID in the ViewModel.
                // Let's remove the immediate setting back to false for now.
                // isFetchingDetails = false
            }
            // Also fetch check-ins on appear
            fetchCheckIns()
        }
    }

    // Function to fetch check-ins for the current activity
    private func fetchCheckIns() {
        guard let activityID = liveActivity?.id else { return }
        isLoadingCheckIns = true
        FirestoreService.shared.fetchCheckInsForActivity(activityID: activityID) { result in
            isLoadingCheckIns = false
            switch result {
            case .success(let fetchedCheckIns):
                self.checkIns = fetchedCheckIns
                print("✅ Fetched \(fetchedCheckIns.count) check-ins for activity \(activityID)")
            case .failure(let error):
                print("❌ Error fetching check-ins: \(error.localizedDescription)")
                // Optionally show an error message to the user
            }
        }
    }

    // Keep the version that accepts activityToUse
    private func createPlaydateView(activityToUse: Activity) -> some View {
        NavigationView {
            CreatePlaydateFromActivityView(
                activity: activityToUse, // Use the passed activity
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
            }
            .buttonStyle(TextButtonStyle())) // Apply text style to Cancel button
        }
    }

    // Check In Button
    private var checkInButton: some View {
        Button {
            showingCheckInSheet = true
        } label: {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text("Check In Here")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle()) // Use secondary style for check-in
        .padding(.horizontal) // Add horizontal padding
        .padding(.bottom, 8) // Add some bottom padding
    }

    // Updated Favorite button to use async toggle
    private var favoriteButton: some View {
        Button {
            Task {
                if let act = liveActivity {
                    await activityViewModel.toggleFavorite(activity: act)
                }
            }
        } label: {
            // Use isFavorite function from ViewModel
            let isFav = liveActivity.map { activityViewModel.isFavorite(activity: $0) } ?? false
            Image(systemName: isFav ? "heart.fill" : "heart")
                .foregroundColor(isFav ? .red : .gray)
                .font(.system(size: 22))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Added Want to Do button
    private var wantToDoButton: some View {
        Button {
            Task {
                if let act = liveActivity {
                    await activityViewModel.toggleWantToDo(activity: act)
                }
            }
        } label: {
            // Use isWantToDo function from ViewModel
            let isWant = liveActivity.map { activityViewModel.isWantToDo(activity: $0) } ?? false
            Image(systemName: isWant ? "bookmark.fill" : "bookmark")
                .foregroundColor(isWant ? ColorTheme.primary : .gray) // Use theme color
                .font(.system(size: 22))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Updated to show image from URL - Use liveActivity
    @ViewBuilder
    private var activityImageView: some View {
        // Use photos from liveActivity
        if let photos = liveActivity?.photos, let firstPhotoUrlString = photos.first, let url = URL(string: firstPhotoUrlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray5))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Fill the frame
                case .failure:
                    defaultActivityImagePlaceholder
                @unknown default:
                    defaultActivityImagePlaceholder
                }
            }
        } else {
            defaultActivityImagePlaceholder
        }
    }

    // Placeholder for when image fails or is missing
    private var defaultActivityImagePlaceholder: some View {
        ZStack {
            Color(.systemGray5) // Placeholder background
            Image(systemName: "photo") // Placeholder icon
                .font(.system(size: 50))
                .foregroundColor(.secondary)
        }
    }

    // Use liveActivity for rating view
    private func ratingView(rating: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }

            Text(String(format: "%.1f", rating))
                .fontWeight(.medium)

            // Use reviewCount from liveActivity
            if let reviewCount = liveActivity?.reviewCount {
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
                    // Label for the primary button
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(height: 20) // Match approx text height
                    } else {
                        Text("Create Playdate")
                    }
                }
                .primaryStyle() // Apply primary style
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
        SwiftUI.Group {
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
            isPublic: isPublic
            // createdAt is handled by @ServerTimestamp in the model
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

// MARK: - CheckIn Row View
struct CheckInRowView: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Profile Image
            ProfileImageView(imageURL: checkIn.userProfileImageURL, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                // User Name and Timestamp
                HStack {
                    Text(checkIn.userName).fontWeight(.semibold)
                    Text("checked in") // Or similar action text
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(checkIn.timestamp.dateValue(), style: .relative) // Relative time
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Comment (if exists)
                if let comment = checkIn.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true) // Allow wrapping
                }

                // Photos (if exists) - Simple horizontal scroll for now
                if let photoURLs = checkIn.photoURLs, !photoURLs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photoURLs, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable()
                                                 .scaledToFill()
                                                 .frame(width: 100, height: 100) // Adjust size
                                                 .cornerRadius(8)
                                                 .clipped()
                                        case .failure:
                                            Image(systemName: "photo") // Placeholder
                                                .frame(width: 100, height: 100)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        default:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 105) // Adjust height
                    .padding(.top, 4)
                }

                // Tagged Friends (if exists) - Simple display
                if let taggedIDs = checkIn.taggedUserIDs, !taggedIDs.isEmpty {
                     // TODO: Fetch friend names based on IDs for better display
                     Text("Tagged: \(taggedIDs.count) friend(s)")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .padding(.top, 4)
                 }
            }
        }
        .padding(.vertical, 8) // Add padding between rows
    }
}

// Extension for PlaydateViewModel to provide a current user ID from Firebase Auth
extension PlaydateViewModel {
    var currentUserId: String? {
        // Get the actual user ID from Firebase Auth
        return Auth.auth().currentUser?.uid
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
                .environmentObject(PlaydateViewModel())
        }
    }
}
