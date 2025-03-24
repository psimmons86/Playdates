import SwiftUI
import CoreLocation

struct ActivitySearchView: View {
    @StateObject private var viewModel = ActivitySearchViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var showingCreatePlaydateSheet = false
    @State private var playdateTitle = ""
    @State private var playdateDescription = ""
    @State private var playdateStartDate = Date()
    @State private var playdateEndDate = Date().addingTimeInterval(3600) // 1 hour later
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search for activities (e.g., park, museum)", text: $viewModel.searchQuery)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        viewModel.searchActivities()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("Searching...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.selectedActivity != nil {
                    // Activity detail view
                    activityDetailView
                } else {
                    // Activity list
                    activityListView
                }
            }
            .navigationTitle("Find Activities")
            .sheet(isPresented: $showingCreatePlaydateSheet) {
                createPlaydateView
            }
            .onAppear {
                // Debug location services
                let locationManager = LocationManager.shared
                print("Debug: LocationManager authorization status: \(locationManager.authorizationStatus.rawValue)")
                print("Debug: Current location available: \(locationManager.location != nil)")
                if let location = locationManager.location {
                    print("Debug: Current location coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                }
            }
        }
    }
    
    // List of activities
    private var activityListView: some View {
        List(viewModel.activities) { activity in
            Button(action: {
                viewModel.getActivityDetails(for: activity)
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(activity.name)
                            .font(.headline)
                        
                        Text(activity.location.address ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let rating = activity.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(rating, specifier: "%.1f")/5")
                                
                                if let totalRatings = activity.userRatingsTotal {
                                    Text("(\(totalRatings))")
                                        .foregroundColor(.gray)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // Detail view for a selected activity
    private var activityDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let activity = viewModel.selectedActivity {
                    // Header with name and back button
                    HStack {
                        Button(action: {
                            viewModel.clearSelectedActivity()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Activity name
                    Text(activity.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Address
                    if let address = activity.address {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(address)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Rating
                    if let rating = activity.rating {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(activity.formattedRating)
                            
                            if let priceLevel = activity.priceLevel, priceLevel > 0 {
                                Text("•")
                                Text(activity.formattedPriceLevel)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Open now
                    if let isOpen = activity.isOpen {
                        HStack {
                            Image(systemName: isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isOpen ? .green : .red)
                            Text(isOpen ? "Open Now" : "Closed")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Photos
                    if let photos = activity.photos, !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(photos, id: \.reference) { photo in
                                    if let url = viewModel.getPhotoURL(for: photo) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 200, height: 150)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Opening hours
                    if let weekdayHours = activity.weekdayHours, !weekdayHours.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Opening Hours")
                                .font(.headline)
                            
                            ForEach(weekdayHours, id: \.self) { hours in
                                Text(hours)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Contact info
                    VStack(alignment: .leading, spacing: 8) {
                        if let phoneNumber = activity.phoneNumber {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.blue)
                                Text(phoneNumber)
                            }
                        }
                        
                        if let website = activity.website {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Text(website)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Reviews
                    if let reviews = activity.reviews, !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(reviews, id: \.authorName) { review in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(review.authorName)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        
                                        Spacer()
                                        
                                        HStack {
                                            ForEach(0..<5) { index in
                                                Image(systemName: index < review.rating ? "star.fill" : "star")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                    
                                    Text(review.text)
                                        .font(.subheadline)
                                    
                                    Text(review.time, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Create Playdate button
                    Button(action: {
                        // Pre-fill playdate details
                        playdateTitle = "Playdate at \(activity.name)"
                        playdateDescription = "Join us for a playdate at \(activity.name)!"
                        showingCreatePlaydateSheet = true
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Create Playdate Here")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
    }
    
    // View for creating a playdate
    private var createPlaydateView: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Title", text: $playdateTitle)
                    
                    TextField("Description", text: $playdateDescription)
                        .frame(height: 100)
                }
                
                Section(header: Text("Date and Time")) {
                    DatePicker("Start Time", selection: $playdateStartDate)
                    
                    DatePicker("End Time", selection: $playdateEndDate)
                }
                
                Section {
                    Button(action: createPlaydate) {
                        Text("Create Playdate")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Create Playdate")
            .navigationBarItems(trailing: Button("Cancel") {
                showingCreatePlaydateSheet = false
            })
        }
    }
    
    // Create a playdate at the selected activity
    private func createPlaydate() {
        guard let user = authViewModel.user, let userID = user.id else {
            // Show error - user not signed in
            return
        }
        
        viewModel.createPlaydateAtSelectedActivity(
            title: playdateTitle,
            description: playdateDescription,
            startDate: playdateStartDate,
            endDate: playdateEndDate,
            hostID: userID
        ) { result in
            showingCreatePlaydateSheet = false
            
            switch result {
            case .success(_):
                // Show success message
                print("Playdate created successfully")
            case .failure(let error):
                // Show error message
                print("Failed to create playdate: \(error.localizedDescription)")
            }
        }
    }
}

struct ActivitySearchView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitySearchView()
            .environmentObject(AuthViewModel())
    }
}
