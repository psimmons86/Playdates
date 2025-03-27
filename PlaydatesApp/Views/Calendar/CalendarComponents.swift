import SwiftUI
import EventKit

// MARK: - Calendar UI Components

/// Button that adds a playdate to the calendar
struct AddToCalendarButton: View {
    let playdate: Playdate
    let attendees: [User]
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingSettings = false
    
    var body: some View {
        Button(action: {
            addToCalendar()
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, 4)
                } else {
                    Text("Add to Calendar")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ColorTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isLoading)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .default(Text("Settings"), action: {
                    showingSettings = true
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                CalendarSettingsView()
            }
        }
    }
    
    private func addToCalendar() {
        isLoading = true
        
        // Check if calendar access is granted
        if !CalendarService.shared.hasCalendarAccess {
            // Request access
            CalendarService.shared.requestCalendarAccess { granted in
                if granted {
                    // Access granted, try to add to calendar
                    addPlaydateToCalendar()
                } else {
                    // Access denied, show alert
                    isLoading = false
                    showCalendarAccessAlert()
                }
            }
        } else {
            // Already have access, add to calendar
            addPlaydateToCalendar()
        }
    }
    
    private func addPlaydateToCalendar() {
        playdate.addToCalendar(attendees: attendees) { result in
            isLoading = false
            
            switch result {
            case .success:
                // Show success alert
                alertTitle = "Added to Calendar"
                alertMessage = "This playdate has been added to your calendar"
                showingAlert = true
                
            case .failure(let error):
                // Show error alert
                if let calendarError = error as? CalendarIntegrationError,
                   case .eventAlreadyExists = calendarError {
                    // Playdate is already in calendar
                    alertTitle = "Already in Calendar"
                    alertMessage = "This playdate is already in your calendar"
                } else {
                    // Other error
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                }
                showingAlert = true
            }
        }
    }
    
    private func showCalendarAccessAlert() {
        alertTitle = "Calendar Access Required"
        alertMessage = "Please enable calendar access in Settings to add playdates to your calendar"
        showingAlert = true
    }
}

/// Component that shows calendar availability for a date range
struct CalendarAvailabilityIndicator: View {
    let startDate: Date
    let endDate: Date
    @State private var isAvailable: Bool? = nil
    @State private var isLoading = false
    
    var body: some View {
        SwiftUI.Group {
            if isLoading {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Checking availability...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else if let isAvailable = isAvailable {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isAvailable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(isAvailable ? "You're available" : "You have other events at this time")
                        .font(.caption)
                        .foregroundColor(isAvailable ? .green : .orange)
                }
            } else {
                Button(action: {
                    checkAvailability()
                }) {
                    Text("Check availability")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // Check availability when view appears if we have calendar access
            if CalendarService.shared.hasCalendarAccess {
                checkAvailability()
            }
        }
    }
    
    private func checkAvailability() {
        isLoading = true
        
        // Check if we have calendar access
        if !CalendarService.shared.hasCalendarAccess {
            // Request access
            CalendarService.shared.requestCalendarAccess { granted in
                if granted {
                    // Access granted, check availability
                    performAvailabilityCheck()
                } else {
                    // Access denied
                    isLoading = false
                }
            }
        } else {
            // Already have access, check availability
            performAvailabilityCheck()
        }
    }
    
    private func performAvailabilityCheck() {
        CalendarService.shared.checkAvailability(
            startDate: startDate,
            endDate: endDate
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let available):
                isAvailable = available
            case .failure:
                isAvailable = nil
            }
        }
    }
}

/// Component to select calendar for playdate
struct CalendarSelector: View {
    @ObservedObject private var calendarService = CalendarService.shared
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
            
            if !calendarService.hasCalendarAccess {
                Button(action: {
                    calendarService.requestCalendarAccess { _ in }
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Grant Calendar Access")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if calendarService.availableCalendars.isEmpty {
                Button(action: {
                    showingSettings = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("No calendars available")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Menu {
                    ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                        Button(action: {
                            calendarService.selectedCalendarIdentifier = calendar.calendarIdentifier
                        }) {
                            HStack {
                                Circle()
                                    .fill(Color(UIColor(cgColor: calendar.cgColor)))
                                    .frame(width: 12, height: 12)
                                Text(calendar.title)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Label("Calendar Settings", systemImage: "gear")
                    }
                } label: {
                    HStack {
                        if let selectedId = calendarService.selectedCalendarIdentifier,
                           let selectedCalendar = calendarService.availableCalendars.first(where: { $0.calendarIdentifier == selectedId }) {
                            HStack {
                                Circle()
                                    .fill(Color(UIColor(cgColor: selectedCalendar.cgColor)))
                                    .frame(width: 12, height: 12)
                                Text(selectedCalendar.title)
                            }
                        } else {
                            Text("Select Calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                CalendarSettingsView()
            }
        }
    }
}

/// Calendar invite button for sending invites to friends
struct SendCalendarInviteButton: View {
    let playdate: Playdate
    let recipient: User
    let sender: User
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: {
            sendInvite()
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 14))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, 4)
                } else {
                    Text("Send Calendar Invite")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ColorTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .disabled(isLoading)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func sendInvite() {
        isLoading = true
        
        // Send calendar invite to recipient
        recipient.sendCalendarInvite(playdate: playdate, sender: sender) { result in
            isLoading = false
            
            switch result {
            case .success:
                // Show success alert
                alertTitle = "Invite Sent"
                alertMessage = "Calendar invite has been sent to \(recipient.name)"
                showingAlert = true
                
            case .failure(let error):
                // Show error alert
                alertTitle = "Error"
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}
