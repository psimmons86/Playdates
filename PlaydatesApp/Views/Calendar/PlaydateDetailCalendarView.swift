import SwiftUI

struct PlaydateDetailCalendarView: View {
    let playdate: Playdate
    let attendees: [User]
    @StateObject private var calendarService = CalendarService.shared
    @State private var isInCalendar: Bool = false
    @State private var isCheckingCalendar = true
    @State private var showingSyncOptions = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if isCheckingCalendar {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Checking calendar status...")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .padding(.leading, 8)
                }
            } else if isInCalendar {
                // Playdate is already in calendar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.green)
                        Text("Added to Calendar")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Button { // Use trailing closure syntax
                            showingSyncOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Sync Options")
                                // Font/color handled by textStyle
                            }
                            // Remove custom styling
                        }
                        .textStyle() // Apply text style
                        
                        Button { // Use trailing closure syntax
                            removeFromCalendar()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.minus")
                                Text("Remove")
                                // Font/color handled by textStyle
                            }
                            // Remove custom styling
                        }
                        .textStyle(color: .red) // Apply text style with red color
                    }
                }
            } else {
                // Not in calendar yet
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add this playdate to your calendar to keep track of it")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                    
                    AddToCalendarButton(playdate: playdate, attendees: attendees)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            checkCalendarStatus()
        }
        .actionSheet(isPresented: $showingSyncOptions) {
            ActionSheet(
                title: Text("Calendar Sync Options"),
                buttons: [
                    .default(Text("Update Calendar Event")) {
                        syncWithCalendar()
                    },
                    .destructive(Text("Remove from Calendar")) {
                        removeFromCalendar()
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func checkCalendarStatus() {
        isCheckingCalendar = true
        
        // Check if the playdate is already in the calendar
        if let _ = playdate.calendarEventIdentifier {
            isInCalendar = true
        } else {
            isInCalendar = false
        }
        
        isCheckingCalendar = false
    }
    
    private func syncWithCalendar() {
        playdate.syncWithCalendar(attendees: attendees) { result in
            switch result {
            case .success:
                // Successfully synced
                isInCalendar = true
                
            case .failure(let error):
                // Error syncing
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func removeFromCalendar() {
        playdate.removeFromCalendar { result in
            switch result {
            case .success:
                // Successfully removed
                isInCalendar = false
                
            case .failure(let error):
                // Error removing
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

/// Calendar invite section for PlaydateDetailView
struct PlaydateCalendarInviteSection: View {
    let playdate: Playdate
    let currentUser: User
    let friends: [User]
    @State private var showingInviteFriends = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar Invites")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            Text("Send calendar invites to friends for this playdate")
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
            
            Button { // Use trailing closure syntax
                showingInviteFriends = true
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Send Calendar Invites")
                    // Font/color handled by primaryStyle
                }
                // Styling handled by primaryStyle
            }
            .primaryStyle() // Apply primary style
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingInviteFriends) {
            CalendarInviteFriendsView(
                playdate: playdate,
                currentUser: currentUser,
                friends: friends
            )
        }
    }
}

/// View for inviting friends to a playdate via calendar
struct CalendarInviteFriendsView: View {
    let playdate: Playdate
    let currentUser: User
    let friends: [User]
    @State private var selectedFriends: Set<String> = []
    @State private var isLoading = false
    @State private var showingCompletionAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Select Friends to Invite")) {
                        if friends.isEmpty {
                            Text("You don't have any friends yet")
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            ForEach(friends, id: \.id) { friend in
                                // Break down the complex expression into smaller parts
                                let friendRow = HStack {
                                    ProfileImageView(imageURL: friend.profileImageURL, size: 40)
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.name)
                                            .fontWeight(.medium)
                                        
                                        // Use direct property access since email is non-optional
                                        if !friend.email.isEmpty {
                                            Text(friend.email)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let friendId = friend.id, selectedFriends.contains(friendId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Button(action: {
                                    if let friendId = friend.id {
                                        toggleFriendSelection(friendId)
                                    }
                                }) {
                                    friendRow
                                }
                                .buttonStyle(PlainButtonStyle()) // Apply plain style to list row button
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
                
                VStack {
                    Button { // Use trailing closure syntax
                        sendInvites()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 20) // Match approx text height
                        } else {
                            Text("Send Calendar Invites")
                            // Font/color handled by primaryStyle
                        }
                    }
                    .primaryStyle() // Apply primary style
                    .disabled(selectedFriends.isEmpty || isLoading)
                    .padding()
                }
            }
            .navigationTitle("Calendar Invites")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .textStyle()) // Apply text style
            .alert(isPresented: $showingCompletionAlert) {
                Alert(
                    title: Text("Invites Sent"),
                    message: Text("Calendar invites have been sent to the selected friends"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func toggleFriendSelection(_ friendId: String) {
        if selectedFriends.contains(friendId) {
            selectedFriends.remove(friendId)
        } else {
            selectedFriends.insert(friendId)
        }
    }
    
    private func sendInvites() {
        isLoading = true
        
        // Get selected friends
        let selectedFriendObjects = friends.filter { friend in
            guard let friendId = friend.id else { return false }
            return selectedFriends.contains(friendId)
        }
        
        // Track completion
        var completedCount = 0
        let totalCount = selectedFriendObjects.count
        
        // Send invites to each friend
        for friend in selectedFriendObjects {
            friend.sendCalendarInvite(playdate: playdate, sender: currentUser) { _ in
                completedCount += 1
                
                // When all invites are sent, show completion alert
                if completedCount == totalCount {
                    isLoading = false
                    showingCompletionAlert = true
                }
            }
        }
        
        // If no friends selected, just complete
        if selectedFriendObjects.isEmpty {
            isLoading = false
        }
    }
}
