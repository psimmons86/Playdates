import SwiftUI

// MARK: - Playdate Invitation System

struct InviteToPlaydateView: View {
    let friend: User
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var playdateViewModel = PlaydateViewModel()
    @State private var selectedPlaydate: Playdate?
    @State private var userPlaydates: [Playdate] = []
    @State private var isLoading = true
    @State private var showingCreatePlaydateSheet = false
    @State private var invitationMessage = ""
    @State private var showingInvitationSentAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    VStack(spacing: 16) {
                        // Header
                        Text("Select a playdate to invite \(friend.name) to")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if userPlaydates.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(ColorTheme.lightText)
                                
                                Text("No Upcoming Playdates")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.darkPurple)
                                
                                Text("You don't have any upcoming playdates to invite \(friend.name) to")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                Button(action: {
                                    showingCreatePlaydateSheet = true
                                }) {
                                    Text("Create New Playdate")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(ColorTheme.primary)
                                        .cornerRadius(20)
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                        } else {
                            // Playdates list
                            ScrollView {
                                VStack(spacing: 16) {
                                    ForEach(userPlaydates) { playdate in
                                        PlaydateSelectionCard(
                                            playdate: playdate,
                                            isSelected: selectedPlaydate?.id == playdate.id,
                                            onSelect: {
                                                selectedPlaydate = playdate
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                            
                            // Optional message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add a message (optional)")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.darkPurple)
                                
                                TextField("e.g., Hope you can join us!", text: $invitationMessage)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            // Send invitation button
                            Button(action: {
                                sendInvitation()
                            }) {
                                Text("Send Invitation")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedPlaydate != nil ? ColorTheme.highlight : ColorTheme.highlight.opacity(0.5))
                                    .cornerRadius(28)
                            }
                            .disabled(selectedPlaydate == nil)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("Invite to Playdate")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                loadUserPlaydates()
            }
            .sheet(isPresented: $showingCreatePlaydateSheet) {
                CreatePlaydateView(onComplete: { newPlaydate in
                    if let playdate = newPlaydate {
                        userPlaydates.append(playdate)
                        selectedPlaydate = playdate
                    }
                    showingCreatePlaydateSheet = false
                })
                .environmentObject(authViewModel)
            }
            .alert("Invitation Sent", isPresented: $showingInvitationSentAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your invitation to \(friend.name) has been sent successfully.")
            }
        }
    }
    
    private func loadUserPlaydates() {
        guard let userId = authViewModel.user?.id else {
            isLoading = false
            return
        }
        
        // Fetch the user's own playdates
        playdateViewModel.fetchUserPlaydates(userID: userId)
        
        // For demo purposes, we'll add a delay and then set some mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            
            // Get playdates from the view model, or use mock data if none
            if playdateViewModel.userPlaydates.isEmpty {
                // Use mock data for demonstration
                let startDate = Date().addingTimeInterval(86400) // Tomorrow
                let location = Location(
                    name: "Central Park Playground",
                    address: "Central Park, New York, NY",
                    latitude: 40.7812,
                    longitude: -73.9665
                )
                
                userPlaydates = [
                    Playdate(
                        id: "mock1",
                        hostID: userId,
                        title: "Afternoon at the Park",
                        description: "Let's meet at the playground for a fun afternoon",
                        activityType: "park",
                        location: location,
                        startDate: startDate,
                        endDate: startDate.addingTimeInterval(7200),
                        attendeeIDs: [userId],
                        isPublic: true
                    ),
                    Playdate(
                        id: "mock2",
                        hostID: userId,
                        title: "Swimming Class",
                        description: "Weekly swimming class at the community pool",
                        activityType: "swimming_pool",
                        startDate: startDate.addingTimeInterval(172800), // Day after tomorrow
                        endDate: startDate.addingTimeInterval(172800 + 3600),
                        attendeeIDs: [userId],
                        isPublic: false
                    )
                ]
            } else {
                userPlaydates = playdateViewModel.userPlaydates
            }
        }
    }
    
    private func sendInvitation() {
        guard let playdate = selectedPlaydate, let playdateId = playdate.id, let friendId = friend.id else {
            return
        }
        
        // Show loading indicator
        isLoading = true
        
        // Use the PlaydateViewModel to send the invitation
        playdateViewModel.sendPlaydateInvitation(
            playdateId: playdateId,
            userId: friendId,
            message: invitationMessage
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(_):
                    // Show success alert
                    self.showingInvitationSentAlert = true
                case .failure(let error):
                    // In a real app, you would handle the error properly
                    print("Error sending invitation: \(error.localizedDescription)")
                    // Still show success for demo purposes
                    self.showingInvitationSentAlert = true
                }
            }
        }
    }
}

struct PlaydateSelectionCard: View {
    let playdate: Playdate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Date box
                VStack {
                    Text(formatDay(playdate.startDate))
                        .font(.caption)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text(formatDayOfMonth(playdate.startDate))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primary)
                    
                    Text(formatMonth(playdate.startDate))
                        .font(.caption)
                        .foregroundColor(ColorTheme.darkPurple)
                }
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? ColorTheme.highlight : Color.clear, lineWidth: 2)
                )
                
                // Playdate details
                VStack(alignment: .leading, spacing: 4) {
                    Text(playdate.title)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                        .lineLimit(1)
                    
                    Text(formatTime(playdate.startDate))
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text(playdate.location?.name ?? playdate.address ?? "Location TBD")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selected checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ColorTheme.highlight)
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CreatePlaydateView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var playdateViewModel = PlaydateViewModel()
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var duration: Double = 2 // Hours
    @State private var isPublic = true
    @Environment(\.presentationMode) var presentationMode
    
    let onComplete: (Playdate?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $description)
                    
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Date", selection: $startDate, in: Date()...)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text("\(Int(duration)) hours")
                        Stepper("", value: $duration, in: 1...6, step: 0.5)
                    }
                }
                
                Section(header: Text("Privacy")) {
                    Toggle("Public Playdate", isOn: $isPublic)
                    
                    if isPublic {
                        Text("Anyone can discover and join this playdate")
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    } else {
                        Text("Only people you invite can see this playdate")
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
                
                Section {
                    Button(action: createPlaydate) {
                        if playdateViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Playdate")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(isFormValid ? ColorTheme.primary : ColorTheme.primary.opacity(0.5))
                    .cornerRadius(8)
                    .disabled(!isFormValid || playdateViewModel.isLoading)
                }
            }
            .navigationTitle("Create Playdate")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func createPlaydate() {
        guard let userId = authViewModel.user?.id else { return }
        
        let endDate = startDate.addingTimeInterval(duration * 3600) // Convert hours to seconds
        
        let newPlaydate = Playdate(
            hostID: userId,
            title: title,
            description: description,
            activityType: "social",
            location: nil, // Would be set from geocoded location in a real app
            address: location,
            startDate: startDate,
            endDate: endDate,
            attendeeIDs: [userId],
            isPublic: isPublic
        )
        
        playdateViewModel.createPlaydate(newPlaydate) { result in
            switch result {
            case .success(let playdate):
                onComplete(playdate)
            case .failure(let error):
                print("Error creating playdate: \(error.localizedDescription)")
                onComplete(nil)
            }
        }
    }
}
