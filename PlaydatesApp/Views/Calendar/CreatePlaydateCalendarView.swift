import SwiftUI

struct CreatePlaydateCalendarView: View {
    @ObservedObject private var calendarService = CalendarService.shared
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var addToCalendar: Bool
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendar")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Toggle("Add to Calendar", isOn: $addToCalendar)
                    .toggleStyle(SwitchToggleStyle(tint: ColorTheme.primary))
            }
            
            if addToCalendar {
                if !calendarService.hasCalendarAccess {
                    Button(action: {
                        requestCalendarAccess()
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Grant Calendar Access")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    // Calendar selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Calendar")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                        
                        if calendarService.availableCalendars.isEmpty {
                            Button(action: {
                                showingSettings = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text("No calendars available")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
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
                    
                    // Calendar availability
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Availability")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                        
                        CalendarAvailabilityIndicator(startDate: startDate, endDate: endDate)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                CalendarSettingsView()
            }
        }
    }
    
    private func requestCalendarAccess() {
        calendarService.requestCalendarAccess { granted in
            // After access is granted, settings will be updated automatically
        }
    }
}

// MARK: - Calendar Integration for PlaydateViewModel

extension PlaydateViewModel {
    /// Creates a playdate and adds it to the calendar if requested
    func createPlaydateWithCalendarIntegration(
        playdate: Playdate,
        addToCalendar: Bool,
        completion: @escaping (Result<Playdate, Error>) -> Void
    ) {
        // First create the playdate in the database
        createPlaydate(playdate) { [weak self] result in
            switch result {
            case .success(var createdPlaydate):
                // If calendar integration is requested
                if addToCalendar {
                    // Add to calendar
                    createdPlaydate.addToCalendar { calendarResult in
                        switch calendarResult {
                        case .success:
                            // Successfully added to calendar
                            completion(.success(createdPlaydate))
                            
                        case .failure(let error):
                            // Calendar error, but playdate was still created
                            self?.error = "Playdate created but couldn't add to calendar: \(error.localizedDescription)"
                            completion(.success(createdPlaydate))
                        }
                    }
                } else {
                    // No calendar integration, just return the created playdate
                    completion(.success(createdPlaydate))
                }
                
            case .failure(let error):
                // Failed to create playdate
                completion(.failure(error))
            }
        }
    }
    
    /// Updates a playdate and syncs changes with the calendar if it was added
    func updatePlaydateWithCalendarSync(
        playdate: Playdate,
        completion: @escaping (Result<Playdate, Error>) -> Void
    ) {
        // First update the playdate in the database
        updatePlaydate(playdate) { [weak self] result in
            switch result {
            case .success(let updatedPlaydate):
                // If playdate was previously added to calendar, sync the changes
                if updatedPlaydate.calendarEventIdentifier != nil {
                    updatedPlaydate.syncWithCalendar { calendarResult in
                        switch calendarResult {
                        case .success:
                            // Successfully synced with calendar
                            completion(.success(updatedPlaydate))
                            
                        case .failure(let error):
                            // Calendar error, but playdate was still updated
                            self?.error = "Playdate updated but couldn't sync with calendar: \(error.localizedDescription)"
                            completion(.success(updatedPlaydate))
                        }
                    }
                } else {
                    // No calendar integration, just return the updated playdate
                    completion(.success(updatedPlaydate))
                }
                
            case .failure(let error):
                // Failed to update playdate
                completion(.failure(error))
            }
        }
    }
    
    /// Deletes a playdate and removes it from the calendar if it was added
    func deletePlaydateWithCalendarCleanup(
        playdate: Playdate,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Check if playdate was added to calendar
        if let eventId = playdate.calendarEventIdentifier {
            // Remove from calendar first
            CalendarService.shared.deletePlaydateEvent(eventIdentifier: eventId) { _ in
                // Continue with deletion regardless of calendar result
                self.deletePlaydate(id: playdate.id ?? "") { result in
                    completion(result)
                }
            }
        } else {
            // No calendar event, just delete the playdate
            deletePlaydate(id: playdate.id ?? "") { result in
                completion(result)
            }
        }
    }
}
