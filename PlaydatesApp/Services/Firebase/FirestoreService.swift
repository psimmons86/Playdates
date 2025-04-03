import Foundation
import Firebase
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()

    // Provide direct access, using lazy initialization to ensure FirebaseApp.configure() runs first.
    lazy var db: Firestore = {
        print("FirestoreService: Initializing Firestore instance (lazy).")
        // This should now be safe as it's accessed after AppDelegate setup.
        let firestoreInstance = Firestore.firestore()

        // Apply custom settings if needed (moved from init)
        // let settings = firestoreInstance.settings
        // settings.dispatchQueue = DispatchQueue(label: "com.example.playdates.firestore.access", qos: .userInitiated)
        // firestoreInstance.settings = settings
        // print("FirestoreService: Custom settings potentially applied during lazy initialization.")

        return firestoreInstance
    }()

     // Private initializer - Keep it simple, initialization logic moved to lazy var
    private init() {
        print("FirestoreService: Singleton Initialized (private init).")
        // Initialization logic moved to lazy var db or configure()
    }

    // Explicit configure method to be called AFTER FirebaseApp.configure()
    func configure() {
        print("FirestoreService: Explicit configure() called.")
        // Accessing db here triggers the lazy initialization safely.
        _ = self.db
        print("FirestoreService: Firestore instance accessed via configure().")

        // Apply custom settings here if needed, now that FirebaseApp is configured.
        // print("FirestoreService: Applying settings via configure().")
    //     let settings = db.settings
    //     settings.dispatchQueue = DispatchQueue(label: "com.example.playdates.firestore", qos: .userInitiated)
    //     db.settings = settings
    //     print("FirestoreService: Custom settings applied via configure().")
    }

    // MARK: - Check-In Functions

    /// Creates a new check-in document in Firestore.
    /// - Parameters:
    ///   - checkIn: The CheckIn object to save.
    ///   - completion: A closure called with the result (either the created CheckIn with ID or an error).
    func createCheckIn(_ checkIn: CheckIn, completion: @escaping (Result<CheckIn, Error>) -> Void) {
        // 1. Get a reference to a new document and its ID
        let newDocRef = db.collection("checkIns").document()
        var checkInWithId = checkIn // Create mutable copy
        checkInWithId.id = newDocRef.documentID // Assign the new ID

        // 2. Try to set the data for the new document reference
        do {
            try newDocRef.setData(from: checkInWithId) { error in
                if let error = error {
                    print("❌ Error setting check-in data: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    // Success! The document is created with the correct ID.
                    print("✅ Check-in created successfully with ID: \(newDocRef.documentID)")
                    completion(.success(checkInWithId)) // Return the object with the ID
                }
            }
        } catch {
            // This catch block handles errors from encoding the checkInWithId object
            print("❌ Error encoding check-in for Firestore: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    /// Fetches all check-ins for a specific activity.
    /// - Parameters:
    ///   - activityID: The ID of the activity.
    ///   - completion: A closure called with the result (either an array of CheckIn objects or an error).
    func fetchCheckInsForActivity(activityID: String, completion: @escaping (Result<[CheckIn], Error>) -> Void) {
        db.collection("checkIns")
          .whereField("activityID", isEqualTo: activityID)
          .order(by: "timestamp", descending: true) // Show newest first
          .getDocuments { snapshot, error in
              if let error = error {
                  print("❌ Error fetching check-ins for activity \(activityID): \(error.localizedDescription)")
                  completion(.failure(error))
                  return
              }

              guard let documents = snapshot?.documents else {
                  print("ℹ️ No check-in documents found for activity \(activityID).")
                  completion(.success([]))
                  return
              }

              let checkIns = documents.compactMap { doc -> CheckIn? in
                  do {
                      return try doc.data(as: CheckIn.self)
                  } catch {
                      print("❌ Error decoding check-in document \(doc.documentID): \(error.localizedDescription)")
                      return nil
                  }
              }
              print("✅ Fetched \(checkIns.count) check-ins for activity \(activityID).")
              completion(.success(checkIns))
          }
    }

    /// Fetches all check-ins made by a specific user.
    /// - Parameters:
    ///   - userID: The ID of the user.
    ///   - completion: A closure called with the result (either an array of CheckIn objects or an error).
    func fetchCheckInsForUser(userID: String, completion: @escaping (Result<[CheckIn], Error>) -> Void) {
        db.collection("checkIns")
          .whereField("userID", isEqualTo: userID)
          .order(by: "timestamp", descending: true) // Show newest first
          .getDocuments { snapshot, error in
              if let error = error {
                  print("❌ Error fetching check-ins for user \(userID): \(error.localizedDescription)")
                  completion(.failure(error))
                  return
              }

              guard let documents = snapshot?.documents else {
                  print("ℹ️ No check-in documents found for user \(userID).")
                  completion(.success([]))
                  return
              }

              let checkIns = documents.compactMap { doc -> CheckIn? in
                  do {
                      return try doc.data(as: CheckIn.self)
                  } catch {
                      print("❌ Error decoding check-in document \(doc.documentID): \(error.localizedDescription)")
                      return nil
                  }
              }
              print("✅ Fetched \(checkIns.count) check-ins for user \(userID).")
              completion(.success(checkIns))
          }
    }
}
