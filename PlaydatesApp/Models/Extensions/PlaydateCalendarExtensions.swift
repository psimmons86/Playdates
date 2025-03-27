import Foundation
import EventKit

// MARK: - Playdate Calendar Extensions

// Add extension to Playdate to support calendar functionality
extension Playdate {
    /// Associated calendar event identifier for this playdate
    var calendarEventIdentifier: String? {
        get {
            // Try to get the event ID from UserDefaults
            return UserDefaults.standard.string(forKey: "PlaydateCalendarEvent_\(id ?? "")")
        }
        set {
            guard let id = id else { return }
            
            if let newValue = newValue {
                // Save the event ID to UserDefaults
                UserDefaults.standard.set(newValue, forKey: "PlaydateCalendarEvent_\(id)")
            } else {
                // Remove the event ID from UserDefaults
                UserDefaults.standard.removeObject(forKey: "PlaydateCalendarEvent_\(id)")
            }
        }
    }
    
    /// Add this playdate to the user's calendar
    func addToCalendar(
        attendees: [User] = [],
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        // Check if this playdate already has a calendar event
        if let existingEventId = calendarEventIdentifier {
            // Event already exists, ask if user wants to update it
            DispatchQueue.main.async {
                completion(.failure(CalendarIntegrationError.eventAlreadyExists(eventId: existingEventId)))
            }
            return
        }
        
        // Add to calendar
        CalendarService.shared.addPlaydateToCalendar(
            playdate: self,
            attendees: attendees
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let eventIdentifier):
                    // Store the event identifier with the playdate
                    var updatedPlaydate = self
                    updatedPlaydate.calendarEventIdentifier = eventIdentifier
                    
                    // Confirm success
                    completion(.success(true))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Sync changes to this playdate with its calendar event
    func syncWithCalendar(
        attendees: [User] = [],
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        // Check if this playdate has a calendar event
        guard let eventIdentifier = calendarEventIdentifier else {
            // No event to sync with, create a new one
            addToCalendar(attendees: attendees, completion: completion)
            return
        }
        
        // Update the existing event
        CalendarService.shared.updatePlaydateEvent(
            playdate: self,
            eventIdentifier: eventIdentifier,
            attendees: attendees
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(.success(true))
                    
                case .failure(let error):
                    if let calendarError = error as? CalendarService.CalendarError,
                       calendarError == .eventNotFound {
                        // Event was deleted from calendar, create a new one
                        var updatedPlaydate = self
                        updatedPlaydate.calendarEventIdentifier = nil
                        updatedPlaydate.addToCalendar(attendees: attendees, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Remove this playdate from the user's calendar
    func removeFromCalendar(completion: @escaping (Result<Bool, Error>) -> Void) {
        // Check if this playdate has a calendar event
        guard let eventIdentifier = calendarEventIdentifier else {
            // No event to remove
            DispatchQueue.main.async {
                completion(.success(false))
            }
            return
        }
        
        // Delete the event from the calendar
        CalendarService.shared.deletePlaydateEvent(
            eventIdentifier: eventIdentifier
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Clear the event identifier
                    var updatedPlaydate = self
                    updatedPlaydate.calendarEventIdentifier = nil
                    
                    completion(.success(true))
                    
                case .failure(let error):
                    if let calendarError = error as? CalendarService.CalendarError,
                       calendarError == .eventNotFound {
                        // Event was already deleted, clear the identifier
                        var updatedPlaydate = self
                        updatedPlaydate.calendarEventIdentifier = nil
                        completion(.success(true))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}

// MARK: - Calendar-related errors

enum CalendarIntegrationError: Error, LocalizedError {
    case eventAlreadyExists(eventId: String)
    case noCalendarSelected
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .eventAlreadyExists:
            return "This playdate is already in your calendar"
        case .noCalendarSelected:
            return "No calendar selected. Please select a calendar in Settings."
        case .accessDenied:
            return "Calendar access was denied. Please enable in Settings."
        }
    }
}

// MARK: - User Calendar Utilities

extension User {
    /// Send a calendar invitation to this user for a playdate
    func sendCalendarInvite(
        playdate: Playdate,
        sender: User,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        // Check if user has an email
        let trimmedEmail = self.email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "User", code: 1, userInfo: [NSLocalizedDescriptionKey: "User does not have an email address"])))
            }
            return
        }
        
        // For now, this is just a placeholder since we can't actually send calendar invites directly from iOS
        // In a real app, you would use a server-side component to send actual calendar invites
        print("Would send calendar invite to \(name) <\(trimmedEmail)> for playdate \(playdate.title)")
        
        // Simulate success - IMPORTANT: Dispatch to main thread
        DispatchQueue.main.async {
            completion(.success(true))
        }
    }
}
