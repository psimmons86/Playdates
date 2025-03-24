import Foundation
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

class PlaydateViewModel: ObservableObject {
    @Published var playdates: [Playdate] = []
    @Published var userPlaydates: [Playdate] = []
    @Published var nearbyPlaydates: [Playdate] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var playdatesListener: ListenerRegistration?
    private var userPlaydatesListener: ListenerRegistration?
    
    deinit {
        playdatesListener?.remove()
        userPlaydatesListener?.remove()
    }
    
    // MARK: - Fetch Playdates
    
    func fetchPlaydates() {
        isLoading = true
        error = nil
        
        // Remove any existing listener
        playdatesListener?.remove()
        
        // Set up a real-time listener for playdates using Firebase best practices
        playdatesListener = db.collection("playdates")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "startDate", descending: false)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.playdates = []
                    return
                }
                
                // Parse playdates with safe data handling
                self.playdates = self.parsePlaydates(from: documents)
            }
    }
    
    func fetchPlaydates(for userID: String) {
        // Fetch both public playdates and user-specific ones
        fetchPlaydates()
        fetchUserPlaydates(userID: userID)
    }
    
    func fetchUserPlaydates(userID: String) {
        isLoading = true
        error = nil
        
        // Remove any existing listener
        userPlaydatesListener?.remove()
        
        // Set up a real-time listener for user's playdates
        userPlaydatesListener = db.collection("playdates")
            .whereField("hostID", isEqualTo: userID)
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.userPlaydates = []
                    return
                }
                
                // Parse playdates with safe data handling
                self.userPlaydates = self.parsePlaydates(from: documents)
            }
    }
    
    // Add method that accepts CLLocation parameter with throttling
    func fetchNearbyPlaydates(location: CLLocation, radiusInKm: Double = 50.0) {
        isLoading = true
        error = nil
        
        // Convert radius to meters for Google Places API
        let radiusInMeters = Int(radiusInKm * 1000)
        
        // Use regular search for nearby activities that could be playdates
        // We'll implement throttling and caching in the service layer
        GooglePlacesService.shared.searchNearbyActivities(
            location: location,
            radius: radiusInMeters,
            activityType: "family_friendly",
            completion: { [weak self] (result: Result<[ActivityPlace], Error>) in
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let activities):
                    // Convert Google Places activities to our Playdate model
                    let mappedPlaydates = activities.prefix(5).map { place -> Playdate in
                        let location = Location(
                            name: place.location.name,
                            address: place.location.address,
                            latitude: place.location.latitude,
                            longitude: place.location.longitude
                        )
                        
                        // Determine activity type based on place types
                        let activityType = self.determineActivityType(from: place.types)
                        
                        // Create a sample playdate based on this location
                        return Playdate(
                            id: place.id,
                            hostID: "system",
                            title: "Playdate at \(place.name)",
                            description: "A fun playdate at this location",
                            activityType: activityType,
                            location: location,
                            startDate: Date().addingTimeInterval(86400), // Tomorrow
                            endDate: Date().addingTimeInterval(86400 + 7200), // 2 hours after start
                            attendeeIDs: [],
                            isPublic: true
                        )
                    }
                    
                    self.nearbyPlaydates = Array(mappedPlaydates)
                    
                case .failure(let error):
                    self.error = error.localizedDescription
                    
                    // Fallback to Firebase method if Google Places fails
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    self.fetchNearbyPlaydates(latitude: latitude, longitude: longitude, radiusInKm: radiusInKm)
                }
            }
        )
    }
    
    // Helper method to determine activity type from place types
    private func determineActivityType(from placeTypes: [String]) -> String {
        if placeTypes.contains("park") {
            return "park"
        } else if placeTypes.contains("museum") {
            return "museum"
        } else if placeTypes.contains("aquarium") {
            return "aquarium"
        } else if placeTypes.contains("zoo") {
            return "zoo"
        } else if placeTypes.contains("library") {
            return "library"
        } else if placeTypes.contains("amusement_park") {
            return "theme park"
        } else if placeTypes.contains("movie_theater") {
            return "movie theater"
        } else if placeTypes.contains("stadium") || placeTypes.contains("sports_complex") {
            return "sporting event"
        } else {
            return "playdate"
        }
    }
    
    func fetchNearbyPlaydates(latitude: Double, longitude: Double, radiusInKm: Double = 50.0) {
        isLoading = true
        error = nil
        
        // Calculate rough bounding box for initial filtering (not perfect but helps limit data)
        let latRadian = latitude * .pi / 180
        let degreesPerKmLat = 1 / 111.0 // approximately 111km per degree of latitude
        let degreesPerKmLon = 1 / (111.0 * cos(latRadian)) // varies based on latitude
        
        let latDelta = radiusInKm * degreesPerKmLat
        let lonDelta = radiusInKm * degreesPerKmLon
        
        let minLat = latitude - latDelta
        let maxLat = latitude + latDelta
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta
        
        // Fetch playdates within the rough bounding box
        db.collection("playdates")
            .whereField("isPublic", isEqualTo: true)
            .whereField("location.latitude", isGreaterThan: minLat)
            .whereField("location.latitude", isLessThan: maxLat)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.nearbyPlaydates = []
                    return
                }
                
                // Parse playdates and filter by longitude and precise distance
                let playdates = self.parsePlaydates(from: documents)
                
                // Now filter by longitude and actual distance in a second pass
                // Fixed filter implementation to avoid closure passing issue
                self.nearbyPlaydates = playdates.filter { playdate in
                    // Must unwrap the location safely first
                    guard let playdateLoc = playdate.location else {
                        return false
                    }
                    
                    // First check longitude (couldn't be done in the query due to limitations)
                    if playdateLoc.longitude < minLon || playdateLoc.longitude > maxLon {
                        return false
                    }
                    
                    // Calculate actual distance using CLLocation for more accuracy
                    let playdateLocation = CLLocation(latitude: playdateLoc.latitude, longitude: playdateLoc.longitude)
                    let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                    let distanceInMeters = playdateLocation.distance(from: userLocation)
                    
                    return distanceInMeters <= (radiusInKm * 1000) // convert km to meters
                }
            }
    }
    
    private func parsePlaydates(from documents: [QueryDocumentSnapshot]) -> [Playdate] {
        return documents.compactMap { document -> Playdate? in
            do {
                // Try decoding directly - use Firestore's built-in decoding first
                return try document.data(as: Playdate.self)
            } catch {
                // If direct decoding fails, use manual parsing with safety methods
                
                // Get raw data and sanitize it immediately
                let rawData = document.data()
                let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                
                let id = document.documentID
                
                // Extract data using safe methods
                guard 
                    let hostID = FirebaseSafetyKit.getString(from: data, forKey: "hostID"),
                    let title = FirebaseSafetyKit.getString(from: data, forKey: "title")
                else {
                    print("Error parsing playdate: missing required fields")
                    return nil
                }
                
                let description = FirebaseSafetyKit.getString(from: data, forKey: "description")
                let activityType = FirebaseSafetyKit.getString(from: data, forKey: "activityType")
                let address = FirebaseSafetyKit.getString(from: data, forKey: "address")
                let isPublic = FirebaseSafetyKit.getBool(from: data, forKey: "isPublic") 
                
                // Get location if available
                var location: Location? = nil
                if let locationData = data["location"] as? [String: Any] {
                    let sanitizedLocationData = FirebaseSafetyKit.sanitizeData(locationData) ?? [:]
                    
                    // Try to parse location from nested data
                    if let latitude = sanitizedLocationData["latitude"] as? Double,
                       let longitude = sanitizedLocationData["longitude"] as? Double {
                        let name = FirebaseSafetyKit.getString(from: sanitizedLocationData, forKey: "name") ?? "Unknown"
                        let address = FirebaseSafetyKit.getString(from: sanitizedLocationData, forKey: "address") ?? "Unknown"
                        
                        location = Location(name: name, address: address, latitude: latitude, longitude: longitude)
                    }
                }
                
                // Get dates
                var startDate = Date()
                if let timestamp = data["startDate"] as? Timestamp {
                    startDate = timestamp.dateValue()
                }
                
                var endDate = Date(timeIntervalSinceNow: 3600) // Default 1 hour later
                if let timestamp = data["endDate"] as? Timestamp {
                    endDate = timestamp.dateValue()
                }
                
                var createdAt = Date()
                if let timestamp = data["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                }
                
                // Get arrays
                let attendeeIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "attendeeIDs") ?? []
                
                // Age ranges
                let minAge = FirebaseSafetyKit.getInt(from: data, forKey: "minAge")
                let maxAge = FirebaseSafetyKit.getInt(from: data, forKey: "maxAge")
                
                // Create and return the playdate using the full initializer
                return Playdate(
                    id: id,
                    hostID: hostID,
                    title: title,
                    description: description,
                    activityType: activityType,
                    location: location,
                    address: address,
                    startDate: startDate,
                    endDate: endDate,
                    minAge: minAge,
                    maxAge: maxAge,
                    attendeeIDs: attendeeIDs,
                    isPublic: isPublic,
                    createdAt: createdAt
                )
            }
        }
    }
    
    // MARK: - Create/Update Playdates
    
    func createPlaydate(_ playdate: Playdate, completion: @escaping (Result<Playdate, Error>) -> Void) {
        isLoading = true
        error = nil
        
        do {
            // Follow Firebase best practices for adding documents with predefined ID
            var newPlaydate = playdate
            
            // Handle document ID creation if needed
            let docRef: DocumentReference
            if let id = playdate.id {
                docRef = db.collection("playdates").document(id)
                try docRef.setData(from: newPlaydate)
            } else {
                docRef = try db.collection("playdates").addDocument(from: newPlaydate)
            }
            
            // Retrieve the newly created document
            docRef.getDocument { [weak self] document, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let document = document, document.exists else {
                    let error = NSError(domain: "PlaydateViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create playdate"])
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                // Parse the document
                do {
                    // Try to decode the document directly first
                    if let createdPlaydate = try? document.data(as: Playdate.self) {
                        completion(.success(createdPlaydate))
                        return
                    }
                    
                    // Fallback to manual parsing
                    let rawData = document.data() ?? [:]
                    let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
                    
                    // Extract the required fields
                    guard
                        let hostID = FirebaseSafetyKit.getString(from: data, forKey: "hostID"),
                        let title = FirebaseSafetyKit.getString(from: data, forKey: "title")
                    else {
                        throw NSError(domain: "PlaydateViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                    }
                    
                    // Create a minimal playdate
                    let createdPlaydate = Playdate(
                        id: document.documentID,
                        hostID: hostID,
                        title: title
                    )
                    
                    completion(.success(createdPlaydate))
                } catch {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    func updatePlaydate(_ playdate: Playdate, completion: @escaping (Result<Playdate, Error>) -> Void) {
        guard let id = playdate.id else {
            let error = NSError(domain: "PlaydateViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Playdate has no ID"])
            self.error = error.localizedDescription
            completion(.failure(error))
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Update using Firebase's built-in Encodable support
            try db.collection("playdates").document(id).setData(from: playdate)
            
            isLoading = false
            completion(.success(playdate))
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    func deletePlaydate(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        db.collection("playdates").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    // MARK: - Attendee Management
    
    func joinPlaydate(playdateID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let docRef = db.collection("playdates").document(playdateID)
        
        // Use Firebase transaction for atomic updates
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let rawData = document.data() else {
                let error = NSError(domain: "PlaydateViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Playdate not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Sanitize data
            let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
            
            // Get current attendees safely
            let attendeeIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "attendeeIDs") ?? []
            
            // Check if user is already attending
            if attendeeIDs.contains(userID) {
                let error = NSError(domain: "PlaydateViewModel", code: 5, userInfo: [NSLocalizedDescriptionKey: "User is already attending this playdate"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Add user to attendees
            var updatedAttendeeIDs = attendeeIDs
            updatedAttendeeIDs.append(userID)
            
            // Update the document
            transaction.updateData(["attendeeIDs": updatedAttendeeIDs], forDocument: docRef)
            
            return nil
        }) { [weak self] (_, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func leavePlaydate(playdateID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let docRef = db.collection("playdates").document(playdateID)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let rawData = document.data() else {
                let error = NSError(domain: "PlaydateViewModel", code: 6, userInfo: [NSLocalizedDescriptionKey: "Playdate not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Sanitize data
            let data = FirebaseSafetyKit.sanitizeData(rawData) ?? [:]
            
            // Get current attendees safely
            let attendeeIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "attendeeIDs") ?? []
            
            // Check if user is attending
            if !attendeeIDs.contains(userID) {
                let error = NSError(domain: "PlaydateViewModel", code: 7, userInfo: [NSLocalizedDescriptionKey: "User is not attending this playdate"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Remove user from attendees
            var updatedAttendeeIDs = attendeeIDs
            updatedAttendeeIDs.removeAll { $0 == userID }
            
            // Update the document
            transaction.updateData(["attendeeIDs": updatedAttendeeIDs], forDocument: docRef)
            
            return nil
        }) { [weak self] (_, error) in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
}
