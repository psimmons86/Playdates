import Foundation
import EventKit
import Combine

/// Service for handling calendar integration with the device calendar
class CalendarService: ObservableObject {
    // Singleton instance for access throughout the app
    static let shared = CalendarService()
    
    // EventKit event store for accessing calendar
    private let eventStore = EKEventStore()
    
    // Published properties for observing in views
    @Published var hasCalendarAccess = false
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var availableCalendars: [EKCalendar] = []
    @Published var selectedCalendarIdentifier: String? = nil
    
    private init() {
        // Check access status on initialization
        checkCalendarAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current authorization status and update hasCalendarAccess
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                self.hasCalendarAccess = true
                self.loadAvailableCalendars()
            case .denied, .restricted:
                self.hasCalendarAccess = false
            case .notDetermined:
                // Will need to request access
                self.hasCalendarAccess = false
            @unknown default:
                self.hasCalendarAccess = false
            }
        }
    }
    
    /// Request calendar access from the user
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error.localizedDescription
                    completion(false)
                    return
                }
                
                self?.hasCalendarAccess = granted
                
                if granted {
                    self?.loadAvailableCalendars()
                }
                
                completion(granted)
            }
        }
    }
    
    // MARK: - Calendar Management
    
    /// Load available calendars from the device
    private func loadAvailableCalendars() {
        guard hasCalendarAccess else { return }
        
        // Get all calendars that allow event creation
        let calendars = eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
        
        DispatchQueue.main.async {
            self.availableCalendars = calendars
            
            // Set default calendar if none selected
            if self.selectedCalendarIdentifier == nil && !calendars.isEmpty {
                // Try to use the primary calendar first
                if let primaryCalendar = calendars.first(where: { $0.isImmutable == false && $0.type == .calDAV }) {
                    self.selectedCalendarIdentifier = primaryCalendar.calendarIdentifier
                } else {
                    // Fall back to the first available calendar
                    self.selectedCalendarIdentifier = calendars.first?.calendarIdentifier
                }
            }
        }
    }
    
    /// Set the default calendar for adding events
    func setDefaultCalendar(identifier: String) {
        self.selectedCalendarIdentifier = identifier
        
        // Save preference to UserDefaults
        UserDefaults.standard.set(identifier, forKey: "PlaydatesDefaultCalendarIdentifier")
    }
    
    // MARK: - Event Operations
    
    /// Add a playdate to the calendar
    func addPlaydateToCalendar(
        playdate: Playdate,
        attendees: [User] = [],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        isLoading = true
        error = nil
        
        guard hasCalendarAccess else {
            requestCalendarAccess { [weak self] granted in
                if granted {
                    // Try again after access granted
                    self?.addPlaydateToCalendar(playdate: playdate, attendees: attendees, completion: completion)
                } else {
                    self?.isLoading = false
                    completion(.failure(CalendarError.accessDenied))
                }
            }
            return
        }
        
        // Get the selected calendar
        guard let calendarIdentifier = selectedCalendarIdentifier,
              let calendar = availableCalendars.first(where: { $0.calendarIdentifier == calendarIdentifier }) else {
            isLoading = false
            completion(.failure(CalendarError.noCalendarSelected))
            return
        }
        
        // Create the event
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        
        // Set event properties
        event.title = playdate.title
        event.notes = playdate.description
        event.startDate = playdate.startDate
        event.endDate = playdate.endDate
        event.isAllDay = false
        
        // Set location if available
        if let location = playdate.location {
            event.location = location.name + ", " + location.address
            
            // Set coordinates if supported by device
            if #available(iOS 16.0, *) {
                let structuredLocation = EKStructuredLocation(title: location.name)
                structuredLocation.geoLocation = CLLocation(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                event.structuredLocation = structuredLocation
            }
        } else if let address = playdate.address {
            event.location = address
        }
        
        // Add attendees if available
        for attendee in attendees {
            // Since attendee.email is non-optional, we don't need optional chaining
            let email = attendee.email.trimmingCharacters(in: .whitespaces)
            if !email.isEmpty {
                let attendeeObject = EKParticipant()
                // Due to limitations of EventKit, we need to use private API to set attendees
                // This is just a placeholder since Apple doesn't provide public API for this
                // In a real app, you would use CalendarKit or another approach for attendees
                print("Would add \(attendee.name) <\(email)> as attendee")
            }
        }
        
        // Set alert if needed (30 minutes before by default)
        let alarm = EKAlarm(relativeOffset: -30 * 60) // 30 minutes before
        event.addAlarm(alarm)
        
        // Save the event
        do {
            try eventStore.save(event, span: .thisEvent)
            
            // Store the event identifier with the playdate for future reference
            guard let eventIdentifier = event.eventIdentifier else {
                isLoading = false
                completion(.failure(CalendarError.failedToSaveEvent))
                return
            }
            
            isLoading = false
            completion(.success(eventIdentifier))
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            completion(.failure(error))
        }
    }
    
    /// Update an existing calendar event for a playdate
    func updatePlaydateEvent(
        playdate: Playdate,
        eventIdentifier: String,
        attendees: [User] = [],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isLoading = true
        error = nil
        
        guard hasCalendarAccess else {
            isLoading = false
            completion(.failure(CalendarError.accessDenied))
            return
        }
        
        // Try to find the existing event
        guard let existingEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            isLoading = false
            completion(.failure(CalendarError.eventNotFound))
            return
        }
        
        // Update event properties
        existingEvent.title = playdate.title
        existingEvent.notes = playdate.description
        existingEvent.startDate = playdate.startDate
        existingEvent.endDate = playdate.endDate
        
        // Update location if available
        if let location = playdate.location {
            existingEvent.location = location.name + ", " + location.address
            
            // Set coordinates if supported by device
            if #available(iOS 16.0, *) {
                let structuredLocation = EKStructuredLocation(title: location.name)
                structuredLocation.geoLocation = CLLocation(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                existingEvent.structuredLocation = structuredLocation
            }
        } else if let address = playdate.address {
            existingEvent.location = address
        }
        
        // Save the updated event
        do {
            try eventStore.save(existingEvent, span: .thisEvent)
            isLoading = false
            completion(.success(()))
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            completion(.failure(error))
        }
    }
    
    /// Delete a calendar event for a playdate
    func deletePlaydateEvent(
        eventIdentifier: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isLoading = true
        error = nil
        
        guard hasCalendarAccess else {
            isLoading = false
            completion(.failure(CalendarError.accessDenied))
            return
        }
        
        // Try to find the existing event
        guard let existingEvent = eventStore.event(withIdentifier: eventIdentifier) else {
            isLoading = false
            completion(.failure(CalendarError.eventNotFound))
            return
        }
        
        // Delete the event
        do {
            try eventStore.remove(existingEvent, span: .thisEvent)
            isLoading = false
            completion(.success(()))
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            completion(.failure(error))
        }
    }
    
    // MARK: - Availability Checking
    
    /// Check user availability for a given time period
    func checkAvailability(
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard hasCalendarAccess else {
            completion(.failure(CalendarError.accessDenied))
            return
        }
        
        // Create a predicate for the time period
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: availableCalendars
        )
        
        // Fetch events within the time period
        let events = eventStore.events(matching: predicate)
        
        // User is available if there are no events in the time period
        let isAvailable = events.isEmpty
        
        completion(.success(isAvailable))
    }
    
    // MARK: - Calendar Errors
    
    enum CalendarError: Error, LocalizedError {
        case accessDenied
        case noCalendarSelected
        case eventNotFound
        case failedToSaveEvent
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Calendar access is required. Please enable in Settings."
            case .noCalendarSelected:
                return "No calendar selected. Please select a calendar in Settings."
            case .eventNotFound:
                return "The calendar event could not be found."
            case .failedToSaveEvent:
                return "Failed to save the event to your calendar."
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }
}
