import SwiftUI

struct PlaydatesView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var playdateViewModel: PlaydateViewModel
    
    @State private var selectedTab = 0
    @State private var showingCreatePlaydateSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                HStack {
                    TabButton(title: "Upcoming", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Invitations", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "Past", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Upcoming playdates
                    upcomingPlaydatesView
                        .tag(0)
                    
                    // Playdate invitations
                    playdateInvitationsView
                        .tag(1)
                    
                    // Past playdates
                    pastPlaydatesView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Playdates")
            .navigationBarItems(trailing: createButton)
            .onAppear {
                if let userID = authViewModel.user?.id {
                    playdateViewModel.fetchPlaydates(for: userID)
                }
            }
            .sheet(isPresented: $showingCreatePlaydateSheet) {
                CreatePlaydateView()
            }
        }
    }
    
    // MARK: - Components
    
    private var upcomingPlaydatesView: some View {
        ScrollView {
            if playdateViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if playdateViewModel.upcomingPlaydates.isEmpty {
                emptyStateView(
                    icon: "calendar",
                    title: "No Upcoming Playdates",
                    message: "You don't have any upcoming playdates. Create one or join one to see it here."
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(playdateViewModel.upcomingPlaydates) { playdate in
                        NavigationLink(destination: PlaydateDetailView(playdate: playdate)) {
                            PlaydateCard(playdate: playdate)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .refreshable {
            if let userID = authViewModel.user?.id {
                playdateViewModel.fetchPlaydates(for: userID)
            }
        }
    }
    
    private var playdateInvitationsView: some View {
        ScrollView {
            if playdateViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if playdateViewModel.invitedPlaydates.isEmpty {
                emptyStateView(
                    icon: "envelope",
                    title: "No Invitations",
                    message: "You don't have any playdate invitations at the moment."
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(playdateViewModel.invitedPlaydates) { playdate in
                        PlaydateInvitationCard(playdate: playdate)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            if let userID = authViewModel.user?.id {
                playdateViewModel.fetchPlaydates(for: userID)
            }
        }
    }
    
    private var pastPlaydatesView: some View {
        ScrollView {
            if playdateViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if playdateViewModel.pastPlaydates.isEmpty {
                emptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Past Playdates",
                    message: "Your completed playdates will appear here."
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(playdateViewModel.pastPlaydates) { playdate in
                        NavigationLink(destination: PlaydateDetailView(playdate: playdate)) {
                            PlaydateCard(playdate: playdate, isPast: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
        .refreshable {
            if let userID = authViewModel.user?.id {
                playdateViewModel.fetchPlaydates(for: userID)
            }
        }
    }
    
    private var createButton: some View {
        Button(action: {
            showingCreatePlaydateSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary)
                .padding(8)
                .background(ColorTheme.primary.opacity(0.1))
                .clipShape(Circle())
        }
    }
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(ColorTheme.primary.opacity(0.7))
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text(message)
                .font(.body)
                .foregroundColor(ColorTheme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if title == "No Upcoming Playdates" {
                Button(action: {
                    showingCreatePlaydateSheet = true
                }) {
                    Text("Create Playdate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(ColorTheme.primary)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.text.opacity(0.6))
                
                Rectangle()
                    .fill(isSelected ? ColorTheme.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PlaydateDetailView: View {
    let playdate: Playdate
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var playdateViewModel: PlaydateViewModel
    
    @State private var showingCancelAlert = false
    @State private var showingLeaveAlert = false
    @State private var comment = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(playdate.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.text)
                    
                    HStack {
                        Text(playdate.activityType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.primary)
                            .cornerRadius(20)
                        
                        if playdate.status == .completed {
                            Text("Completed")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorTheme.secondary)
                                .cornerRadius(20)
                        } else if playdate.status == .inProgress {
                            Text("In Progress")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorTheme.accent)
                                .cornerRadius(20)
                        }
                    }
                }
                
                // Date and time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date & Time")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(ColorTheme.primary)
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(ColorTheme.primary)
                        
                        Text(formattedTime)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text)
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
                        
                        Text(playdate.location.name)
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text.opacity(0.8))
                    }
                    
                    Text(playdate.location.address)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.text.opacity(0.8))
                    
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
                    
                    Text(playdate.description)
                        .font(.body)
                        .foregroundColor(ColorTheme.text.opacity(0.8))
                }
                
                // Participants
                VStack(alignment: .leading, spacing: 8) {
                    Text("Participants")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    HStack {
                        ForEach(0..<min(5, playdate.participantIDs.count), id: \.self) { index in
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(index + 1))
                                        .foregroundColor(ColorTheme.text.opacity(0.5))
                                )
                        }
                        
                        if playdate.participantIDs.count > 5 {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("+\(playdate.participantIDs.count - 5)")
                                        .foregroundColor(ColorTheme.text.opacity(0.5))
                                )
                        }
                        
                        Spacer()
                    }
                }
                
                // Comments
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comments")
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    if let comments = playdate.comments, !comments.isEmpty {
                        ForEach(comments) { comment in
                            CommentView(comment: comment)
                        }
                    } else {
                        Text("No comments yet")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text.opacity(0.5))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // Add comment
                    HStack {
                        TextField("Add a comment...", text: $comment)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        
                        Button(action: {
                            addComment()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(ColorTheme.primary)
                                .padding(10)
                                .background(ColorTheme.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(comment.isEmpty)
                    }
                }
                
                // Action buttons
                if playdate.status != .completed && playdate.status != .cancelled {
                    HStack {
                        if isOrganizer {
                            Button(action: {
                                showingCancelAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Cancel Playdate")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                showingLeaveAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "person.fill.xmark")
                                    Text("Leave Playdate")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
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
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingCancelAlert) {
            Alert(
                title: Text("Cancel Playdate"),
                message: Text("Are you sure you want to cancel this playdate? This action cannot be undone."),
                primaryButton: .destructive(Text("Cancel Playdate")) {
                    cancelPlaydate()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        return dateFormatter.string(from: playdate.startDate)
    }
    
    private var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return "\(dateFormatter.string(from: playdate.startDate)) - \(dateFormatter.string(from: playdate.endDate))"
    }
    
    private var isOrganizer: Bool {
        return playdate.organizerID == authViewModel.user?.id
    }
    
    private func addComment() {
        guard let userID = authViewModel.user?.id, !comment.isEmpty else { return }
        
        playdateViewModel.addComment(to: playdate, userID: userID, text: comment) { _ in
            comment = ""
        }
    }
    
    private func cancelPlaydate() {
        playdateViewModel.cancelPlaydate(playdate) { _ in
            // Handle result if needed
        }
    }
    
    private func leavePlaydate() {
        guard let userID = authViewModel.user?.id else { return }
        
        playdateViewModel.leavePlaydate(playdate, userID: userID) { _ in
            // Handle result if needed
        }
    }
}

struct CreatePlaydateView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var playdateViewModel: PlaydateViewModel
    @EnvironmentObject private var locationManager: LocationManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedActivityType: ActivityType = .park
    @State private var location = Location(name: "", address: "", latitude: 0, longitude: 0)
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later
    @State private var isPrivate = false
    @State private var invitedFriends: [String] = []
    @State private var showingLocationPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Activity Type", selection: $selectedActivityType) {
                        ForEach(ActivityType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Description")
                                        .foregroundColor(Color.gray.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section(header: Text("Location")) {
                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            if location.name.isEmpty {
                                Text("Select Location")
                                    .foregroundColor(Color.gray.opacity(0.5))
                            } else {
                                VStack(alignment: .leading) {
                                    Text(location.name)
                                    Text(location.address)
                                        .font(.caption)
                                        .foregroundColor(Color.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.gray)
                        }
                    }
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Start Date", selection: $startDate, in: Date()...)
                    DatePicker("End Date", selection: $endDate, in: startDate...)
                }
                
                Section(header: Text("Privacy")) {
                    Toggle("Private Playdate", isOn: $isPrivate)
                    
                    if isPrivate {
                        Text("Only invited friends will be able to see this playdate.")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                    } else {
                        Text("This playdate will be visible to all your friends.")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                    }
                }
                
                Section(header: Text("Invite Friends")) {
                    Text("Friend selection will be implemented here")
                        .foregroundColor(Color.gray)
                }
                
                Section {
                    Button(action: {
                        createPlaydate()
                    }) {
                        Text("Create Playdate")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? ColorTheme.primary : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Create Playdate")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingLocationPicker) {
                Text("Location Picker View")
                    // This would be a custom view for selecting a location
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        return !title.isEmpty && !description.isEmpty && !location.name.isEmpty
    }
    
    private func createPlaydate() {
        guard let userID = authViewModel.user?.id else { return }
        
        playdateViewModel.createPlaydate(
            title: title,
            description: description,
            organizerID: userID,
            participantIDs: [userID],
            invitedIDs: invitedFriends,
            startDate: startDate,
            endDate: endDate,
            location: location,
            activityType: selectedActivityType,
            isPrivate: isPrivate
        ) { result in
            switch result {
            case .success(_):
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Error creating playdate: \(error.localizedDescription)")
            }
        }
    }
}

struct PlaydatesView_Previews: PreviewProvider {
    static var previews: some View {
        PlaydatesView()
            .environmentObject(AuthViewModel())
            .environmentObject(PlaydateViewModel())
    }
}
