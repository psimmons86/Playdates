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
                        
                        Text(activity.location.address)
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
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(activity.location.address)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    
                    // Rating
                    if let rating = activity.rating {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(activity.formattedRating)
                        }
                        .padding(.horizontal)
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
