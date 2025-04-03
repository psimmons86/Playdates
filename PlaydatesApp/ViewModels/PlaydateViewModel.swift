import Foundation
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

// Assume FirebaseSafetyKit and GooglePlacesService/ActivityPlace are defined elsewhere
// Assume Location, Playdate, ActivityPlace, PlaydateInvitation models are defined
// Assume FirebaseSafetyKit is available
// Assume Array.chunked(into:) is defined elsewhere (e.g., in PlaydateDetailViewModel or a utility file)


class PlaydateViewModel: ObservableObject {

    @Published var playdates: [Playdate] = []
    @Published var userPlaydates: [Playdate] = []
    @Published var nearbyPlaydates: [Playdate] = []
    @Published var isLoading = false
    @Published var error: String?

    // Use service singletons
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private let authService = FirebaseAuthService.shared

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    private var cancellables = Set<AnyCancellable>()
    private var playdatesListener: ListenerRegistration?
    private var userPlaydatesListener: ListenerRegistration?

    deinit {
        playdatesListener?.remove()
        userPlaydatesListener?.remove()
    }

    // MARK: - Fetch Playdates

    func fetchPlaydates() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        playdatesListener?.remove()
        playdatesListener = db.collection("playdates")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "startDate", descending: false)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async { // Ensure UI updates are on main thread
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.error = error.localizedDescription
                        self.playdates = [] // Clear on error
                        print("Error fetching playdates: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        print("Playdates snapshot documents are nil.")
                        self.playdates = []
                        return
                    }
                    // Parse and immediately filter for non-nil IDs before assigning
                    let parsed = self.parsePlaydates(from: documents)
                    self.playdates = parsed.filter { $0.id != nil }
                    if parsed.count != self.playdates.count {
                        print("⚠️ Warning: Filtered out \(parsed.count - self.playdates.count) playdates with nil IDs during fetch.")
                    }
                }
            }
    }

    func fetchPlaydates(for userID: String) {
        fetchPlaydates()
        fetchUserPlaydates(userID: userID)
    }

    func fetchUserPlaydates(userID: String) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        userPlaydatesListener?.remove()
        userPlaydatesListener = db.collection("playdates")
            .whereField("hostID", isEqualTo: userID)
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async { // Ensure UI updates are on main thread
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.error = error.localizedDescription
                        self.userPlaydates = [] // Clear on error
                         print("Error fetching user playdates: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                         print("User playdates snapshot documents are nil.")
                        self.userPlaydates = []
                        return
                    }
                    // Parse and immediately filter for non-nil IDs before assigning
                    let parsed = self.parsePlaydates(from: documents)
                    self.userPlaydates = parsed.filter { $0.id != nil }
                     if parsed.count != self.userPlaydates.count {
                        print("⚠️ Warning: Filtered out \(parsed.count - self.userPlaydates.count) user playdates with nil IDs during fetch.")
                    }
                }
            }
    }

    func fetchNearbyPlaydates(location: CLLocation, radiusInKm: Double = 50.0) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        let radiusInMeters = Int(radiusInKm * 1000)

        GooglePlacesService.shared.searchNearbyActivities(
            location: location,
            radius: radiusInMeters,
            activityType: "family_friendly",
            completion: { [weak self] (result: Result<[ActivityPlace], Error>) in
                DispatchQueue.main.async { // Ensure UI updates are on main thread
                    guard let self = self else { return }
                    self.isLoading = false

                    switch result {
                    case .success(let activities):
                        let mappedPlaydates = activities.prefix(5).map { place -> Playdate in
                            let location = Location(
                                name: place.location.name,
                                address: place.location.address,
                                latitude: place.location.latitude,
                                longitude: place.location.longitude
                            )
                            let activityType = self.determineActivityType(from: place.types)
                            return Playdate(
                                id: place.id, hostID: "system", title: "Playdate at \(place.name)",
                                description: "A fun playdate at this location", activityType: activityType,
                                location: location, address: place.location.address,
                                startDate: Date().addingTimeInterval(86400), endDate: Date().addingTimeInterval(86400 + 7200),
                                attendeeIDs: [], isPublic: true // createdAt is handled by @ServerTimestamp
                            )
                        }
                        self.nearbyPlaydates = Array(mappedPlaydates)

                    case .failure(let error):
                        self.error = error.localizedDescription
                        print("Google Places search failed: \(error.localizedDescription). Falling back to Firebase.")
                        let latitude = location.coordinate.latitude
                        let longitude = location.coordinate.longitude
                        self.fetchNearbyPlaydates(latitude: latitude, longitude: longitude, radiusInKm: radiusInKm)
                    }
                }
            }
        )
    }

    private func determineActivityType(from placeTypes: [String]) -> String {
        if placeTypes.contains("park") { return "park" }
        if placeTypes.contains("museum") { return "museum" }
        if placeTypes.contains("playground") { return "playground" }
        return "playdate"
    }

    func fetchNearbyPlaydates(latitude: Double, longitude: Double, radiusInKm: Double = 50.0) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        let latRadian = latitude * .pi / 180
        let degreesPerKmLat = 1 / 111.0
        let degreesPerKmLon = 1 / (111.0 * cos(latRadian))

        let latDelta = radiusInKm * degreesPerKmLat
        let lonDelta = radiusInKm * degreesPerKmLon

        let minLat = latitude - latDelta
        let maxLat = latitude + latDelta
        let minLon = longitude - lonDelta
        let maxLon = longitude + lonDelta

        db.collection("playdates")
            .whereField("isPublic", isEqualTo: true)
            .whereField("location.latitude", isGreaterThan: minLat)
            .whereField("location.latitude", isLessThan: maxLat)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async { // Ensure UI updates are on main thread
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.error = error.localizedDescription
                        self.nearbyPlaydates = []
                        print("Error fetching nearby playdates from Firebase: \(error.localizedDescription)")
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        print("Nearby playdates snapshot documents are nil.")
                        self.nearbyPlaydates = []
                        return
                    }

                    let playdates = self.parsePlaydates(from: documents)
                    self.nearbyPlaydates = playdates.filter { playdate in
                        guard let playdateLoc = playdate.location else { return false }
                        if playdateLoc.longitude < minLon || playdateLoc.longitude > maxLon { return false }
                        let playdateLocation = CLLocation(latitude: playdateLoc.latitude, longitude: playdateLoc.longitude)
                        let userLocation = CLLocation(latitude: latitude, longitude: longitude)
                        let distanceInMeters = playdateLocation.distance(from: userLocation)
                        return distanceInMeters <= (radiusInKm * 1000)
                    }
                }
            }
    }

    private func parsePlaydates(from documents: [QueryDocumentSnapshot]) -> [Playdate] {
        return documents.compactMap { document -> Playdate? in
            do {
                return try document.data(as: Playdate.self)
            } catch {
                print("Error decoding playdate \(document.documentID): \(error).")
                return nil
            }
        }
    }

    // MARK: - Create/Update Playdates

    func createPlaydate(_ playdate: Playdate, completion: @escaping (Result<Playdate, Error>) -> Void) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        do {
            // Ensure createdAt is not manually assigned when using @ServerTimestamp
            var newPlaydate = playdate
            // createdAt is handled by @ServerTimestamp, no need to set it here.

            let docRef: DocumentReference
            let collectionRef = db.collection("playdates")

            if let id = playdate.id, !id.isEmpty {
                 docRef = collectionRef.document(id)
                 try docRef.setData(from: newPlaydate) { error in
                     DispatchQueue.main.async {
                         if let error = error {
                             self.isLoading = false
                             self.error = error.localizedDescription
                             completion(.failure(error))
                         } else {
                             self.fetchAndComplete(docRef: docRef, completion: completion)
                         }
                     }
                 }
            } else {
                 // Create document synchronously, get reference
                 docRef = try collectionRef.addDocument(from: newPlaydate)
                 // If addDocument succeeds, fetch the document to confirm and complete
                 self.fetchAndComplete(docRef: docRef, completion: completion)
            }
        } catch {
             DispatchQueue.main.async {
                 self.isLoading = false
                 self.error = error.localizedDescription
                 completion(.failure(error))
             }
        }
    }

    private func fetchAndComplete(docRef: DocumentReference, completion: @escaping (Result<Playdate, Error>) -> Void) {
        docRef.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                guard let document = document, document.exists else {
                    let fetchError = NSError(domain: "PlaydateViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch created/updated playdate"])
                    self.error = fetchError.localizedDescription
                    completion(.failure(fetchError))
                    return // Added missing return
                }
                do {
                    let createdPlaydate = try document.data(as: Playdate.self)
                    completion(.success(createdPlaydate))
                } catch let parseError {
                    self.error = parseError.localizedDescription
                    completion(.failure(parseError))
                }
            }
        }
    }


    func updatePlaydate(_ playdate: Playdate, completion: @escaping (Result<Playdate, Error>) -> Void) {
        guard let id = playdate.id else {
            let error = NSError(domain: "PlaydateViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Playdate has no ID for update"])
            DispatchQueue.main.async { self.error = error.localizedDescription }
            completion(.failure(error))
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        // Use do-catch as setData(from:) can throw during encoding
        do {
            // Use setData(from: merge: false) or ensure 'playdate' object has all fields
            try db.collection("playdates").document(id).setData(from: playdate) { [weak self] error in
                // This is the Firestore completion handler
                DispatchQueue.main.async { // Ensure completion is on main thread
                    guard let self = self else { return }
                    self.isLoading = false

                    if let error = error {
                        self.error = error.localizedDescription
                        completion(.failure(error))
                    } else {
                        completion(.success(playdate))
                    }
                }
            }
        } catch {
            // This catches errors from the ENCODING process
            DispatchQueue.main.async { [weak self] in
                 guard let self = self else { return }
                 self.isLoading = false
                 self.error = error.localizedDescription
                 completion(.failure(error))
            }
        }
    }

    func deletePlaydate(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        db.collection("playdates").document(id).delete { [weak self] error in
             DispatchQueue.main.async { // Ensure completion is on main thread
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

    // MARK: - Attendee Management

    func joinPlaydate(playdateID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        let docRef = db.collection("playdates").document(playdateID)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            guard let data = document.data() else {
                let error = NSError(domain: "PlaydateViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Playdate not found during transaction"])
                errorPointer?.pointee = error
                return nil
            }

            var attendeeIDs = data["attendeeIDs"] as? [String] ?? []
            if attendeeIDs.contains(userID) { return nil } // Already attending

            attendeeIDs.append(userID)
            transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: docRef)
            return nil
        }) { [weak self] (_, error) in
             DispatchQueue.main.async { // Ensure completion is on main thread
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    func leavePlaydate(playdateID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        let docRef = db.collection("playdates").document(playdateID)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let document: DocumentSnapshot
            do {
                try document = transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            guard let data = document.data() else {
                let error = NSError(domain: "PlaydateViewModel", code: 6, userInfo: [NSLocalizedDescriptionKey: "Playdate not found during transaction"])
                errorPointer?.pointee = error
                return nil
            }

            var attendeeIDs = data["attendeeIDs"] as? [String] ?? []
            if !attendeeIDs.contains(userID) { return nil } // Not attending

            attendeeIDs.removeAll { $0 == userID }
            transaction.updateData(["attendeeIDs": attendeeIDs], forDocument: docRef)
            return nil
        }) { [weak self] (_, error) in
             DispatchQueue.main.async { // Ensure completion is on main thread
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Playdate Invitations

    func sendPlaydateInvitation(playdateId: String, userId: String, message: String?, completion: @escaping (Result<PlaydateInvitation, Error>) -> Void) {
         DispatchQueue.main.async {
             self.isLoading = true
             self.error = nil
         }

        guard let senderID = authService.currentUser?.uid, !senderID.isEmpty else { // Use authService
             let error = NSError(domain: "PlaydateViewModel", code: 10, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
             DispatchQueue.main.async {
                 self.isLoading = false
                 self.error = error.localizedDescription
             }
             completion(.failure(error))
              return
         }

        // Create a dictionary for the new invitation data
        var invitationData: [String: Any] = [
            "playdateID": playdateId,
            "senderID": senderID,
            "recipientID": userId,
            "status": InvitationStatus.pending.rawValue
            // createdAt and updatedAt handled by @ServerTimestamp
        ]
        if let message = message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            invitationData["message"] = message
        }

        // Wrap the async operations in a Task
        Task {
            do {
                // Use addDocument(data:) to let Firestore handle timestamps
                let docRef = try await db.collection("playdateInvitations").addDocument(data: invitationData)

                // Fetch the newly created document to get the full object with timestamps and ID
                let document = try await docRef.getDocument()

                guard document.exists else {
                    let fetchError = NSError(domain: "PlaydateViewModel", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch created invitation \(docRef.documentID)"])
                    // Update UI on main thread before throwing
                    await MainActor.run { [weak self] in
                        self?.isLoading = false
                        self?.error = fetchError.localizedDescription
                    }
                    throw fetchError // Throw error to be caught by the outer catch block
                }

                // Decode the fetched document
                let createdInvitation = try document.data(as: PlaydateInvitation.self)

                // Send notification (can stay in background Task)
                Task.detached { // Use detached Task if notification doesn't need MainActor
                    await NotificationService.shared.notifyPlaydateInvitationSent(
                        senderID: senderID,
                        recipientID: userId,
                        invitationID: createdInvitation.id ?? docRef.documentID, // Use ID from decoded object or docRef
                        playdateTitle: nil // Fetch playdate title if needed
                    )
                }

                // Update UI and call completion on main thread
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    print("✅ Invitation sent and fetched successfully with ID: \(createdInvitation.id ?? "N/A")")
                    completion(.success(createdInvitation)) // Call completion with the object
                }

            } catch {
                 // Update UI and call completion on main thread for any error within the Task
                 await MainActor.run { [weak self] in
                     guard let self = self else { return }
                     self.isLoading = false
                     self.error = error.localizedDescription
                     print("❌ Error in sendPlaydateInvitation Task: \(error.localizedDescription)")
                     completion(.failure(error))
                 }
            } // Closes catch block for Task's do
        } // Closes Task block
    } // Closes sendPlaydateInvitation function
} // Closes PlaydateViewModel class
