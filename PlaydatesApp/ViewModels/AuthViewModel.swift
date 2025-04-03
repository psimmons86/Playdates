import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isLoading = false // General loading indicator for sign-in/up etc.
    @Published var isInitialAuthCheckComplete = false // Tracks if the very first check is done
    @Published var error: String?

    // Access Firebase services via simplified singletons
    private var authService = FirebaseAuthService.shared // Use the singleton
    private var firestoreService = FirestoreService.shared // Hold the service instance
    private var cancellables = Set<AnyCancellable>()
    private var isFetchingProfile = false // Track profile fetching state

    // Computed property to access db safely after configuration
    private var db: Firestore {
        firestoreService.db // Access the lazy var when needed
    }

    var currentUser: User? {
        return user
    }

    // Init calls setup methods directly
    init() {
        print("🔍 AuthViewModel initialized.")
        // Don't call checkAuthState immediately, let the listener handle the first state.
        // checkAuthState()
        setupAuthStateListener() // Listener will trigger the first profile fetch if needed.
    }

    // Method to start Firebase interactions AFTER initialization and view appearance
    // func start() { ... } // Removed start() method

    // Removed checkAuthState as listener handles initial state

    private func setupAuthStateListener() {
        print("🔍 Setting up auth state listener (addStateDidChangeListener)")
        // Use the auth instance from the service singleton
        authService.auth.addStateDidChangeListener { [weak self] _, authUser in
            guard let self = self else { return }
            print("🔍 Auth state changed, user: \(authUser?.uid ?? "nil")")

            let wasAlreadyChecked = self.isInitialAuthCheckComplete
            // Store authUser details temporarily
            let authUserID = authUser?.uid

            // Refined Logic v3 (with delay for sign-out clearing):
            if let currentAuthUserID = authUserID { // User is signed in according to Firebase Auth
                // Don't set isSignedIn immediately, wait for profile fetch result
                // Check if we need to fetch the profile AND are not already fetching
                if (self.user == nil || self.user?.id != currentAuthUserID) && !self.isFetchingProfile {
                    print("🔍 Auth state: User signed in (\(currentAuthUserID)). Needs profile fetch.")
                    // Don't clear self.user here. Fetch will set it on success.
                    self.fetchUserProfile(for: currentAuthUserID) { success in
                        // Set isSignedIn ONLY after successful fetch
                        if success {
                            self.isSignedIn = true
                        } else {
                            // If fetch fails, treat as signed out state locally
                            self.isSignedIn = false
                            self.user = nil
                        }
                        // Handle completion, including setting isInitialAuthCheckComplete
                        if !wasAlreadyChecked {
                            self.isInitialAuthCheckComplete = true
                            print("✅ Initial auth check marked complete (signed in, fetch attempt completed: \(success)). Fetch success: \(success)")
                        }
                    }
                } else if self.user != nil && self.user?.id == currentAuthUserID {
                    // User is signed in, and the correct profile is already loaded.
                    // Ensure isSignedIn is true if it wasn't already (e.g., app start)
                    if !self.isSignedIn { self.isSignedIn = true }
                    print("🔍 Auth state: User signed in (\(currentAuthUserID)). Profile already loaded.")
                    if !wasAlreadyChecked {
                        self.isInitialAuthCheckComplete = true
                        print("✅ Initial auth check marked complete (signed in, profile already loaded).")
                    }
                } else if self.isFetchingProfile {
                     print("🔍 Auth state: User signed in (\(currentAuthUserID)). Profile fetch already in progress.")
                     // Don't change state or mark initial check complete here, wait for fetch to finish.
                }
            } else { // User is signed out according to Firebase Auth
                let wasSignedIn = self.isSignedIn // Check previous state
                // Add a small delay before clearing the user, in case this is a transient nil state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self, self.authService.auth.currentUser == nil else { // Double-check auth state directly
                        print(" M Sign-out logic cancelled: Firebase user exists after delay.")
                        return
                    }
                    // Only proceed if Firebase *still* reports no user
                    self.isSignedIn = false // Set signed out state definitively
                    if self.user != nil { // Only clear if there was a user loaded
                        print("🔍 Auth state: User signed out (wasSignedIn=\(wasSignedIn)). Clearing local user profile after delay.")
                        self.user = nil
                    } else {
                        print("🔍 Auth state: User signed out (wasSignedIn=\(wasSignedIn)). No local profile to clear after delay.")
                    }
                }
                // Mark initial check complete immediately if it wasn't already
                if !wasAlreadyChecked {
                    self.isInitialAuthCheckComplete = true
                    print("✅ Initial auth check marked complete (received signed out state).")
                }
            }
        } // End addStateDidChangeListener closure
    } // End setupAuthStateListener func


    func signIn(email: String, password: String) {
        self.isLoading = true // Use self
        self.error = nil // Use self

        // Use the auth instance from the service singleton
        self.authService.auth.signIn(withEmail: email, password: password) { [weak self] (authResult: AuthDataResult?, error: Error?) in // Add types
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                print("❌ SignIn Error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                return
            }
            print("✅ SignIn Successful for email: \(email)")

            // User is signed in, the auth state listener will handle updating the user
        }
    }

    func signUp(name: String, email: String, password: String) {
        self.isLoading = true // Use self
        self.error = nil // Use self

        // Use the auth instance from the service singleton
        self.authService.auth.createUser(withEmail: email, password: password) { [weak self] (authResult: AuthDataResult?, error: Error?) in // Add types
            guard let self = self else { return }

            // Ensure isLoading is set to false eventually, regardless of path
            defer { self.isLoading = false }

            if let error = error {
                print("❌ SignUp Error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                return
            }

            guard let authUser = authResult?.user else {
                print("❌ SignUp Error: Failed to get user from auth result.")
                self.error = "Failed to create user account." // More specific error
                return
            }
            print("✅ SignUp Successful for email: \(email), UID: \(authUser.uid). Creating profile...")

            // Create user profile in Firestore
            let newUser = User(
                id: authUser.uid, // Explicitly set ID here
                name: name,
                email: email,
                createdAt: Date(),
                lastActive: Date()
            )

            // Use the modified saveUserProfile which now uses updateData for new users too
            // Note: isLoading is handled by the defer statement above
            self.saveUserProfile(newUser, isNewUser: true) { success in
                // No need to set isLoading here again
                if !success {
                    // Error is already set within saveUserProfile if it fails
                    print("❌ SignUp Error: Failed to save user profile after account creation.")
                    // Optionally: Consider deleting the auth user if profile save fails critically? (Complex)
                } else {
                    print("✅ User profile saved successfully for new user: \(authUser.uid)")
                }
                // Auth state listener should automatically trigger and fetch the profile.
            }
        }
    }

    func signOut() {
        do {
            // Use the auth instance from the service singleton
            try self.authService.auth.signOut() // Use self
            print("✅ SignOut Successful.")
            // Auth state listener will handle updating the user state and clearing local user object.
        } catch let signOutError { // Catch specific error
            print("❌ SignOut Error: \(signOutError.localizedDescription)")
            self.error = signOutError.localizedDescription
        }
    }

    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        self.isLoading = true // Use self
        self.error = nil // Use self

        // Use the auth instance from the service singleton
        self.authService.auth.sendPasswordReset(withEmail: email) { [weak self] (error: Error?) in // Add type
            guard let self = self else {
                completion(false) // Ensure completion is called even if self is nil
                return
            }

            self.isLoading = false

            if let error = error {
                print("❌ ResetPassword Error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                completion(false)
                return
            }
            print("✅ Password reset email sent successfully to: \(email)")
            completion(true)
        }
    }

    // Updated to include children
    func updateUserProfile(name: String, bio: String?, profileImageURL: String?, children: [PlaydateChild]? = nil, completion: @escaping (Bool) -> Void) {
        guard let user = self.user, let id = user.id else { // Use self.user
            print("❌ UpdateProfile Error: User not signed in.")
            self.error = "User not signed in" // Use self
            completion(false)
            return
        }

        self.isLoading = true // Use self
        self.error = nil // Use self

        var updatedUser = user // Creates a mutable copy
        var dataToUpdate: [String: Any] = [:]

        // Check which fields have actually changed or are being set
        if updatedUser.name != name {
            updatedUser.name = name
            dataToUpdate["name"] = name
        }
        if updatedUser.bio != bio {
            updatedUser.bio = bio
            dataToUpdate["bio"] = bio ?? FieldValue.delete() // Use delete if nil
        }
        if updatedUser.profileImageURL != profileImageURL {
            updatedUser.profileImageURL = profileImageURL
            dataToUpdate["profileImageURL"] = profileImageURL ?? FieldValue.delete() // Use delete if nil
        }
        // Only update children if a non-nil value is passed
        if let newChildren = children {
             // Convert children to dictionary format for Firestore update
            let childrenData = newChildren.map { $0.toDictionary() }
            updatedUser.children = newChildren // Update local model
            dataToUpdate["children"] = childrenData // Add to update dictionary
        }
        
        // Always update lastActive timestamp
        let now = Date()
        updatedUser.lastActive = now
        dataToUpdate["lastActive"] = Timestamp(date: now)


        // Only call save if there's something to update
        if !dataToUpdate.isEmpty {
            // Pass the mutable copy `updatedUser` and the changes `dataToUpdate`
            self.saveUserProfile(updatedUser, dataToUpdate: dataToUpdate) { [weak self] success in
                // Ensure UI updates happen on the main thread
                DispatchQueue.main.async {
                    guard let self = self else {
                        completion(false) // Ensure completion is called
                        return
                    }

                    self.isLoading = false // Update isLoading on main thread

                    if success {
                        print("✅ User profile updated successfully in Firestore for user: \(id)")
                        self.user = updatedUser // Update local user state ONLY on success
                        self.error = nil // Clear error on success
                    } else {
                        // Error should have been set within saveUserProfile
                        print("❌ UpdateProfile Error: saveUserProfile failed.")
                        // Don't update self.user if save failed
                    }
                    completion(success) // Call completion handler
                }
            }
        } else {
             // Nothing changed, complete immediately
             print(" M UpdateProfile: No changes detected, skipping Firestore update.")
             self.isLoading = false // Use self
             completion(true)
        }
    }


    // Modified to accept completion handler and manage isFetchingProfile state
    private func fetchUserProfile(for userID: String, completion: ((Bool) -> Void)? = nil) {
        guard !isFetchingProfile else {
            print(" M fetchUserProfile skipped for \(userID): Already fetching.")
            completion?(false) // Indicate fetch didn't happen here
            return
        }
        isFetchingProfile = true // Mark as fetching
        print("🔍 fetchUserProfile started for userID: \(userID)")
        // Use general isLoading for profile fetch indication
        DispatchQueue.main.async {
            // Don't set self.isLoading = true here, as it might conflict with sign-in/up loading
            self.error = nil // Clear previous error
        }

        // Use self.db
        self.db.collection("users").document(userID).getDocument { [weak self] (snapshot: DocumentSnapshot?, error: Error?) in // Add types
            // Perform all completion logic on the main thread
            DispatchQueue.main.async {
                var success = false // Track success for completion handler
                guard let self = self else {
                    print("❌ fetchUserProfile Error: self is nil before processing snapshot for \(userID)")
                    completion?(false) // Indicate failure if self is nil
                    return
                }

                // Set isLoading and isFetchingProfile to false *after* processing is done on main thread
                // Call completion handler within the defer block to ensure it's always called
                defer {
                    // self.isLoading = false // Don't manage general isLoading here
                    self.isFetchingProfile = false // Mark fetching as complete
                    print(" M fetchUserProfile finished for \(userID). Success: \(success)")
                    completion?(success)
                }

                if let error = error {
                    print("❌ fetchUserProfile Firestore Error: \(error.localizedDescription) for \(userID)")
                    print("🔍 fetchUserProfile error: \(error.localizedDescription)")
                    self.error = "Failed to fetch profile: \(error.localizedDescription)"
                    // success remains false
                    return
                }

                // Add log to check snapshot existence before the guard
                print("🔍 fetchUserProfile: Received snapshot callback. Snapshot exists: \(snapshot?.exists ?? false), Error: \(error?.localizedDescription ?? "None")")

                guard let snapshot = snapshot, snapshot.exists else {
                    print("⚠️ fetchUserProfile Warning: User profile document not found for \(userID)")
                    self.error = "User profile not found." // Keep error message concise
                    // success remains false
                    return
                }

                print("🔍 fetchUserProfile: Got snapshot, attempting direct decoding using data(as: User.self)")
                do {
                    // Use Firestore's Codable support directly
                    // Important: Ensure the User model conforms to Codable and handles potential mismatches gracefully.
                    var decodedUser = try snapshot.data(as: User.self) // Decode as mutable
                    decodedUser.id = snapshot.documentID // *** Manually assign the ID ***
                    print("✅ User profile decoded successfully for \(userID)")
                    self.user = decodedUser // Update property directly on main thread
                    print("✅ fetchUserProfile: Set self.user to: \(self.user?.name ?? "nil name") with ID: \(self.user?.id ?? "nil ID")") // Log should now show ID
                    self.error = nil // Clear error on success
                    success = true // Mark as success
                } catch let decodingError as DecodingError { // Catch specific DecodingError
                    print("❌ fetchUserProfile Decoding Error: \(decodingError.localizedDescription) for \(userID)")
                    // Print detailed context for debugging
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("   TypeMismatch Error: Type '\(type)' mismatch. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), Debug Description: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   ValueNotFound Error: No value found for type '\(type)'. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), Debug Description: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                        print("   KeyNotFound Error: Key '\(key.stringValue)' not found. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), Debug Description: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("   DataCorrupted Error: Data corrupted. Path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")), Debug Description: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown DecodingError: \(decodingError)")
                    }
                    // Also log the raw data that failed to decode
                    print("   Problematic Firestore Data: \(snapshot.data() ?? [:])")
                    self.error = "Failed to process user profile data." // Keep user-facing error simple
                    // success remains false
                } catch { // Catch any other non-decoding errors
                    print("❌ fetchUserProfile Non-Decoding Error: \(error.localizedDescription) for \(userID)")
                    self.error = "An unexpected error occurred fetching the profile."
                    // success remains false
                }
            } // End of DispatchQueue.main.async
        } // End of getDocument completion
    } // End fetchUserProfile func

    // Overload for saving a new user (uses setData)
    private func saveUserProfile(_ user: User, isNewUser: Bool = false, completion: @escaping (Bool) -> Void) {
        guard let id = user.id else {
            completion(false)
            return
        }

        do {
            // Use setData for new users to create the document
            try self.db.collection("users").document(id).setData(from: user) // Use self.db
            print("✅ New user profile saved successfully using setData for \(id).")
            completion(true)
        } catch let error { // Catch specific error
            print("❌ Error saving new user profile with setData: \(error.localizedDescription) for \(id)")
            // Ensure error is set on the main thread if this func could be called from background
            DispatchQueue.main.async {
                 self.error = "Failed to save profile: \(error.localizedDescription)"
            }
            completion(false)
        }
    } // End saveUserProfile (new user) func

    // Overload for updating existing user (uses updateData)
    private func saveUserProfile(_ user: User, dataToUpdate: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let id = user.id else {
            completion(false)
            return
        }
        
        guard !dataToUpdate.isEmpty else {
            print("⚠️ saveUserProfile called with empty dataToUpdate dictionary. Skipping Firestore update.")
            completion(true) // Nothing to update, technically successful.
            return
        }

        // Use self.db
        self.db.collection("users").document(id).updateData(dataToUpdate) { [weak self] (error: Error?) in // Add type
            DispatchQueue.main.async { // Ensure completion runs on main thread
                guard let self = self else {
                    completion(false) // Ensure completion is called
                    return
                }
                if let error = error {
                    print("❌ Error updating user profile with updateData: \(error.localizedDescription) for \(id)")
                    self.error = "Update failed: \(error.localizedDescription)"
                    completion(false)
                } else {
                    print("✅ User profile updated successfully using updateData for \(id).")
                    // Don't update self.user here; it's handled in the calling function (updateUserProfile)
                    completion(true)
                }
            }
        }
    } // End saveUserProfile (update) func


    // MARK: - Children Management

    // Note: addChild, updateChild, removeChild now implicitly use the updateData mechanism
    // via the updateUserProfile -> saveUserProfile(dataToUpdate:) flow, which correctly uses self.

    func addChild(name: String, age: Int, interests: [String]? = nil, completion: @escaping (Bool) -> Void) {
        guard var user = self.user, let id = user.id else { // Use self.user
            print("❌ AddChild Error: User not signed in.")
            self.error = "User not signed in" // Use self
            completion(false)
            return
        }

        // Ensure parentID matches the current user's ID
        let newChild = PlaydateChild(name: name, age: age, interests: interests ?? [], parentID: id)
        var currentChildren = user.children ?? []
        currentChildren.append(newChild)

        // Call updateUserProfile to handle the update correctly
        // Pass the existing user details along with the updated children array
        print(" M Calling updateUserProfile to add child for user \(id)")
        updateUserProfile(name: user.name, bio: user.bio, profileImageURL: user.profileImageURL, children: currentChildren, completion: completion)
    }

    func updateChild(childID: String, name: String, age: Int, interests: [String]? = nil, completion: @escaping (Bool) -> Void) {
        guard var user = self.user, let id = user.id, var children = user.children else { // Use self.user
            print("❌ UpdateChild Error: User not signed in or no children found.")
            self.error = "User not signed in or no children found" // Use self
            completion(false)
            return
        }

        guard let index = children.firstIndex(where: { $0.id == childID }) else {
            print("❌ UpdateChild Error: Child with ID \(childID) not found for user \(id).")
            self.error = "Child not found" // Use self
            completion(false)
            return
        }

        // Ensure parentID matches the current user's ID
        let updatedChild = PlaydateChild(id: childID, name: name, age: age, interests: interests ?? [], parentID: id)
        children[index] = updatedChild

        // Call updateUserProfile to handle the update correctly
        print(" M Calling updateUserProfile to update child \(childID) for user \(id)")
        updateUserProfile(name: user.name, bio: user.bio, profileImageURL: user.profileImageURL, children: children, completion: completion)
    }

    func removeChild(childID: String, completion: @escaping (Bool) -> Void) {
        guard var user = self.user, let id = user.id, var children = user.children else { // Use self.user
            print("❌ RemoveChild Error: User not signed in or no children found.")
            self.error = "User not signed in or no children found" // Use self
            completion(false)
            return
        }

        let initialCount = children.count
        children.removeAll { $0.id == childID }

        // Check if a child was actually removed
        if children.count < initialCount {
            // Call updateUserProfile to handle the update correctly
            print(" M Calling updateUserProfile to remove child \(childID) for user \(id)")
            updateUserProfile(name: user.name, bio: user.bio, profileImageURL: user.profileImageURL, children: children, completion: completion)
        } else {
            print("⚠️ RemoveChild Warning: Child with ID \(childID) not found for user \(id). No changes made.")
            // No child was removed, complete with success as the state is already correct
            completion(true)
        }
    }
} // End AuthViewModel class

// Helper extension to convert PlaydateChild to Dictionary for Firestore update
extension PlaydateChild {
    func toDictionary() -> [String: Any] {
        return [
            "id": id ?? UUID().uuidString,
            "name": name,
            "age": age,
            "gender": gender ?? NSNull(), // Use NSNull for optional fields that might be nil
            "interests": interests,
            "parentID": parentID
        ]
    }
}
