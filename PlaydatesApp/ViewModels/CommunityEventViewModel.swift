import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class CommunityEventViewModel: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = CommunityEventViewModel()
    
    // Published properties for UI updates
    @Published var upcomingEvents: [CommunityEvent] = []
    @Published var userEvents: [CommunityEvent] = []
    @Published var nearbyEvents: [CommunityEvent] = []
    @Published var selectedEvent: CommunityEvent?
    @Published var filteredEvents: [CommunityEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Filter state
    @Published var selectedCategories: [EventCategory] = []
    @Published var showFreeOnly: Bool = false
    @Published var ageRangeFilter: ClosedRange<Int>? = nil
    @Published var dateRangeFilter: ClosedRange<Date>? = nil
    
    // Calendar view state
    @Published var calendarViewMode: CalendarViewMode = .month
    
    // Firestore references
    private let db = Firestore.firestore()
    private var eventsRef: CollectionReference {
        return db.collection("community_events")
    }
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Event Operations
    
    /// Fetch upcoming events
    func fetchUpcomingEvents() {
        isLoading = true
        errorMessage = nil
        
        let now = Date()
        
        eventsRef.whereField("isPublic", isEqualTo: true)
            .whereField("startDate", isGreaterThan: Timestamp(date: now))
            .order(by: "startDate", descending: false)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.upcomingEvents = []
                    return
                }
                
                self.upcomingEvents = documents.compactMap { document -> CommunityEvent? in
                    try? document.data(as: CommunityEvent.self)
                }
                
                // Apply any active filters
                self.applyFilters()
            }
    }
    
    /// Fetch events where the user is an attendee or organizer
    func fetchUserEvents(userID: String) {
        isLoading = true
        errorMessage = nil
        
        // First fetch events where user is an attendee
        eventsRef.whereField("attendeeIDs", arrayContains: userID)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch user events: \(error.localizedDescription)"
                    return
                }
                
                var events: [CommunityEvent] = []
                
                if let documents = snapshot?.documents {
                    events = documents.compactMap { document -> CommunityEvent? in
                        try? document.data(as: CommunityEvent.self)
                    }
                }
                
                // Then fetch events where user is the organizer
                self.eventsRef.whereField("organizerID", isEqualTo: userID)
                    .getDocuments { [weak self] snapshot, error in
                        guard let self = self else { return }
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = "Failed to fetch organized events: \(error.localizedDescription)"
                            return
                        }
                        
                        if let documents = snapshot?.documents {
                            let organizedEvents = documents.compactMap { document -> CommunityEvent? in
                                try? document.data(as: CommunityEvent.self)
                            }
                            
                            // Combine both sets of events and remove duplicates
                            let allEvents = events + organizedEvents
                            let uniqueEvents = Array(Set(allEvents.map { $0.id }).compactMap { id in
                                allEvents.first { $0.id == id }
                            })
                            
                            // Sort by start date
                            self.userEvents = uniqueEvents.sorted { $0.startDate < $1.startDate }
                        } else {
                            self.userEvents = events
                        }
                    }
            }
    }
    
    /// Fetch events based on location proximity
    func fetchNearbyEvents(location: Location, radiusInKm: Double = 10.0) {
        isLoading = true
        errorMessage = nil
        
        let now = Date()
        
        // In a real implementation, this would use geoqueries
        // For now, we'll simulate by fetching public events
        eventsRef.whereField("isPublic", isEqualTo: true)
            .whereField("startDate", isGreaterThan: Timestamp(date: now))
            .order(by: "startDate", descending: false)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch nearby events: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.nearbyEvents = []
                    return
                }
                
                let events = documents.compactMap { document -> CommunityEvent? in
                    try? document.data(as: CommunityEvent.self)
                }
                
                // In a real implementation, we would filter by distance here
                // For now, we'll just return all results
                self.nearbyEvents = events
            }
    }
    
    /// Create a new event
    func createEvent(event: CommunityEvent, completion: @escaping (Result<CommunityEvent, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = eventsRef.document()
            var newEvent = event
            newEvent.id = docRef.documentID
            
            try docRef.setData(from: newEvent) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to create event: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Add to appropriate arrays
                if newEvent.isFuture {
                    self.upcomingEvents.append(newEvent)
                    self.upcomingEvents.sort { $0.startDate < $1.startDate }
                }
                
                self.userEvents.append(newEvent)
                self.userEvents.sort { $0.startDate < $1.startDate }
                
                // Apply filters to update filtered events
                self.applyFilters()
                
                completion(.success(newEvent))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode event: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Update an existing event
    func updateEvent(event: CommunityEvent, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let id = event.id else {
            completion(.failure(NSError(domain: "CommunityEventViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Event ID is missing"])))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try eventsRef.document(id).setData(from: event) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to update event: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Update in local arrays
                if let index = self.upcomingEvents.firstIndex(where: { $0.id == id }) {
                    self.upcomingEvents[index] = event
                }
                
                if let index = self.userEvents.firstIndex(where: { $0.id == id }) {
                    self.userEvents[index] = event
                }
                
                if let index = self.nearbyEvents.firstIndex(where: { $0.id == id }) {
                    self.nearbyEvents[index] = event
                }
                
                if self.selectedEvent?.id == id {
                    self.selectedEvent = event
                }
                
                // Apply filters to update filtered events
                self.applyFilters()
                
                completion(.success(()))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode event: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// RSVP to an event
    func rsvpToEvent(eventID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let eventRef = eventsRef.document(eventID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let eventDocument: DocumentSnapshot
            do {
                try eventDocument = transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var event = try? eventDocument.data(as: CommunityEvent.self) else {
                let error = NSError(domain: "CommunityEventViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode event"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Check if user is already attending
            if event.attendeeIDs.contains(userID) {
                return nil // Already attending, no action needed
            }
            
            // Check if event is at capacity
            if event.isAtCapacity {
                // Add to waitlist instead
                if !event.waitlistIDs.contains(userID) {
                    event.waitlistIDs.append(userID)
                }
            } else {
                // Add to attendees
                event.attendeeIDs.append(userID)
                
                // Remove from waitlist if they were on it
                event.waitlistIDs.removeAll { $0 == userID }
            }
            
            // Update the event
            do {
                try transaction.setData(from: event, forDocument: eventRef)
                return event
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to RSVP to event: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedEvent = result as? CommunityEvent {
                // Update local arrays
                if let index = self.upcomingEvents.firstIndex(where: { $0.id == eventID }) {
                    self.upcomingEvents[index] = updatedEvent
                }
                
                if let index = self.nearbyEvents.firstIndex(where: { $0.id == eventID }) {
                    self.nearbyEvents[index] = updatedEvent
                }
                
                // Add to user's events if not already there
                if !self.userEvents.contains(where: { $0.id == eventID }) {
                    self.userEvents.append(updatedEvent)
                    self.userEvents.sort { $0.startDate < $1.startDate }
                } else if let index = self.userEvents.firstIndex(where: { $0.id == eventID }) {
                    self.userEvents[index] = updatedEvent
                }
                
                if self.selectedEvent?.id == eventID {
                    self.selectedEvent = updatedEvent
                }
                
                // Apply filters to update filtered events
                self.applyFilters()
                
                completion(.success(()))
            } else {
                completion(.success(()))  // No changes needed
            }
        }
    }
    
    /// Cancel RSVP to an event
    func cancelRSVP(eventID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let eventRef = eventsRef.document(eventID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let eventDocument: DocumentSnapshot
            do {
                try eventDocument = transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var event = try? eventDocument.data(as: CommunityEvent.self) else {
                let error = NSError(domain: "CommunityEventViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode event"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Remove user from attendees
            let wasAttending = event.attendeeIDs.contains(userID)
            event.attendeeIDs.removeAll { $0 == userID }
            
            // Remove from waitlist too if they were on it
            event.waitlistIDs.removeAll { $0 == userID }
            
            // If the event was at capacity and someone cancels, move the first person from waitlist to attendees
            if wasAttending && event.isAtCapacity && !event.waitlistIDs.isEmpty {
                let nextAttendee = event.waitlistIDs.removeFirst()
                event.attendeeIDs.append(nextAttendee)
            }
            
            // Update the event
            do {
                try transaction.setData(from: event, forDocument: eventRef)
                return event
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to cancel RSVP: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedEvent = result as? CommunityEvent {
                // Update local arrays
                if let index = self.upcomingEvents.firstIndex(where: { $0.id == eventID }) {
                    self.upcomingEvents[index] = updatedEvent
                }
                
                if let index = self.nearbyEvents.firstIndex(where: { $0.id == eventID }) {
                    self.nearbyEvents[index] = updatedEvent
                }
                
                // Remove from user's events if they're not the organizer
                if updatedEvent.organizerID != userID {
                    self.userEvents.removeAll { $0.id == eventID }
                } else if let index = self.userEvents.firstIndex(where: { $0.id == eventID }) {
                    self.userEvents[index] = updatedEvent
                }
                
                if self.selectedEvent?.id == eventID {
                    self.selectedEvent = updatedEvent
                }
                
                // Apply filters to update filtered events
                self.applyFilters()
                
                completion(.success(()))
            } else {
                completion(.success(()))  // No changes needed
            }
        }
    }
    
    // MARK: - Filtering and Sorting
    
    /// Apply all current filters to the events
    func applyFilters() {
        var filtered = upcomingEvents
        
        // Filter by categories if any are selected
        if !selectedCategories.isEmpty {
            filtered = filtered.filter { event in
                selectedCategories.contains(event.category)
            }
        }
        
        // Filter by free only
        if showFreeOnly {
            filtered = filtered.filter { $0.isFree }
        }
        
        // Filter by age range
        if let ageRange = ageRangeFilter {
            filtered = filtered.filter { event in
                // If event has no age restrictions, include it
                if event.ageMin == nil && event.ageMax == nil {
                    return true
                }
                
                // Check if the age range overlaps with the event's age range
                let eventMinAge = event.ageMin ?? 0
                let eventMaxAge = event.ageMax ?? 100
                
                return !(eventMinAge > ageRange.upperBound || eventMaxAge < ageRange.lowerBound)
            }
        }
        
        // Filter by date range
        if let dateRange = dateRangeFilter {
            filtered = filtered.filter { event in
                // Check if the event's time range overlaps with the filter date range
                return !(event.endDate < dateRange.lowerBound || event.startDate > dateRange.upperBound)
            }
        }
        
        // Sort by start date
        filtered.sort { $0.startDate < $1.startDate }
        
        filteredEvents = filtered
    }
    
    /// Set category filter
    func setCategories(_ categories: [EventCategory]) {
        selectedCategories = categories
        applyFilters()
    }
    
    /// Toggle free only filter
    func toggleFreeOnly() {
        showFreeOnly.toggle()
        applyFilters()
    }
    
    /// Set age range filter
    func setAgeRange(_ range: ClosedRange<Int>?) {
        ageRangeFilter = range
        applyFilters()
    }
    
    /// Set date range filter
    func setDateRange(_ range: ClosedRange<Date>?) {
        dateRangeFilter = range
        applyFilters()
    }
    
    /// Reset all filters
    func resetFilters() {
        selectedCategories = []
        showFreeOnly = false
        ageRangeFilter = nil
        dateRangeFilter = nil
        applyFilters()
    }
    
    /// Set calendar view mode
    func setCalendarViewMode(_ mode: CalendarViewMode) {
        calendarViewMode = mode
    }
}

// Calendar view mode enum
enum CalendarViewMode {
    case day
    case week
    case month
    case agenda
    case map
}
