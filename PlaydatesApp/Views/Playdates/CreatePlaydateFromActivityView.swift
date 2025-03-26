import SwiftUI
import Combine
import FirebaseFirestore

struct CreatePlaydateFromActivityView: View {
    let activity: Activity
    @Binding var isPresented: Bool
    var onPlaydateCreated: (Playdate) -> Void
    
    @ObservedObject private var authViewModel = AuthViewModel()
    @ObservedObject private var playdateViewModel = PlaydateViewModel()
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var endDate = Date().addingTimeInterval(86400 + 7200) // 2 hours after start
    @State private var isPublic = true
    @State private var minAge: String = ""
    @State private var maxAge: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    private var location: Location {
        return activity.location
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity info section
                activityInfoSection
                
                // Playdate details form
                playdateDetailsForm
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Create button
                createButton
            }
            .padding()
        }
        .onAppear {
            // Pre-fill title and description based on activity
            title = "Playdate at \(activity.name)"
            description = "Join me for a playdate at \(activity.name)! \(activity.description)"
        }
    }
    
    private var activityInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create a playdate at:")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Activity icon
                activityIcon
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
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
    }
    
    private var playdateDetailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Playdate Details")
                .font(.headline)
            
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
                    
                    Text("Anyone can discover and join this playdate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "91DDCF")))
        }
    }
    
    private var createButton: some View {
        Button(action: createPlaydate) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "91DDCF"))
                    .cornerRadius(12)
            } else {
                Text("Create Playdate")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "91DDCF"))
                    .foregroundColor(Color(hex: "5D4E6D"))
                    .cornerRadius(12)
            }
        }
        .disabled(isLoading || !isFormValid)
        .padding(.top, 16)
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
        guard let currentUser = authViewModel.currentUser, let userID = currentUser.id else {
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
            hostID: userID,
            title: title,
            description: description,
            activityType: activity.type.rawValue,
            location: location,
            startDate: startDate,
            endDate: endDate,
            minAge: minAgeInt,
            maxAge: maxAgeInt,
            attendeeIDs: [userID], // Host is automatically an attendee
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

// Helper extension for hex colors
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
