import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var error: String?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    var currentUser: User? {
        return user
    }

    init() {
        setupAuthStateListener()
    }

    func checkAuthState() {
        print("🔍 checkAuthState called, current user: \(auth.currentUser?.uid ?? "nil")")
        isSignedIn = auth.currentUser != nil
        if let authUser = auth.currentUser {
            print("🔍 User is signed in, fetching profile for: \(authUser.uid)")
            fetchUserProfile(for: authUser.uid)
        } else {
            print("🔍 No user is signed in")
        }
    }

    private func setupAuthStateListener() {
        print("🔍 Setting up auth state listener")
        auth.addStateDidChangeListener { [weak self] _, authUser in
            guard let self = self else { return }
            
            print("🔍 Auth state changed, user: \(authUser?.uid ?? "nil")")
            self.isSignedIn = authUser != nil

            if let authUser = authUser {
                print("🔍 Auth state: User signed in, fetching profile")
                self.fetchUserProfile(for: authUser.uid)
            } else {
                print("🔍 Auth state: User signed out")
                self.user = nil
            }
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        error = nil

        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                self.error = error.localizedDescription
                return
            }

            // User is signed in, the auth state listener will handle updating the user
        }
    }

    func signUp(name: String, email: String, password: String) {
        isLoading = true
        error = nil

        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                return
            }

            guard let authUser = result?.user else {
                self.isLoading = false
                self.error = "Failed to create user"
                return
            }

            // Create user profile in Firestore
            let newUser = User(
                id: authUser.uid,
                name: name,
                email: email,
                createdAt: Date(),
                lastActive: Date()
            )

            self.saveUserProfile(newUser) { success in
                self.isLoading = false

                if !success {
                    self.error = "Failed to save user profile"
                }
            }
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            // Auth state listener will handle updating the user
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resetPassword(email: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        error = nil

        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                self.error = error.localizedDescription
                completion(false)
                return
            }

            completion(true)
        }
    }

    func updateUserProfile(name: String, bio: String?, profileImageURL: String?, completion: @escaping (Bool) -> Void) {
        guard let user = user, let id = user.id else {
            error = "User not signed in"
            completion(false)
            return
        }

        isLoading = true
        error = nil

        var updatedUser = user
        updatedUser.name = name
        updatedUser.bio = bio
        updatedUser.profileImageURL = profileImageURL
        updatedUser.lastActive = Date()

        saveUserProfile(updatedUser) { [weak self] success in
            guard let self = self else { return }

            self.isLoading = false

            if success {
                self.user = updatedUser
            } else {
                self.error = "Failed to update user profile"
            }

            completion(success)
        }
    }

    private func fetchUserProfile(for userID: String) {
        print("🔍 fetchUserProfile started for userID: \(userID)")
        isLoading = true

        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { 
                print("🔍 fetchUserProfile: self is nil")
                return 
            }

            self.isLoading = false

            if let error = error {
                print("🔍 fetchUserProfile error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("🔍 fetchUserProfile: User profile not found")
                self.error = "User profile not found"
                return
            }

            print("🔍 fetchUserProfile: Got snapshot, sanitizing data")
            if var data = snapshot.data() {
                // CRITICAL: Immediately sanitize all data to prevent NSNumber->String crashes
                data = FirebaseSafetyKit.sanitizeData(data) ?? [:]
                print("🔍 Data sanitized successfully")

                // Extract values using safe methods
                let name = FirebaseSafetyKit.getString(from: data, forKey: "name") ?? "User"
                let email = FirebaseSafetyKit.getString(from: data, forKey: "email") ?? ""
                let profileImageURL = FirebaseSafetyKit.getString(from: data, forKey: "profileImageURL")
                let bio = FirebaseSafetyKit.getString(from: data, forKey: "bio")
                print("🔍 Basic user info extracted: \(name), \(email)")

                // Handle dates - these are already Firebase Timestamp objects
                var createdAt = Date()
                if let timestamp = data["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                }

                var lastActive = Date()
                if let timestamp = data["lastActive"] as? Timestamp {
                    lastActive = timestamp.dateValue()
                }

                // Handle arrays
                var children: [PlaydateChild]? = nil
                if let childrenData = data["children"] as? [[String: Any]] {
                    print("🔍 Processing \(childrenData.count) children")
                    children = childrenData.compactMap { childData -> PlaydateChild? in
                        // Safety: Sanitize each child data dictionary
                        let sanitizedData = FirebaseSafetyKit.sanitizeData(childData) ?? [:]

                        guard let name = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "name") else { return nil }
                        let age = FirebaseSafetyKit.getInt(from: sanitizedData, forKey: "age") ?? 0
                        let id = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "id") ?? UUID().uuidString
                        let gender = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "gender")
                        let interests = FirebaseSafetyKit.getStringArray(from: sanitizedData, forKey: "interests") ?? []
                        let parentID = FirebaseSafetyKit.getString(from: sanitizedData, forKey: "parentID") ?? userID

                        return PlaydateChild(id: id, name: name, age: age, gender: gender, interests: interests, parentID: parentID)
                    }
                }

                // Handle string arrays
                let friendIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendIDs")
                let friendRequestIDs = FirebaseSafetyKit.getStringArray(from: data, forKey: "friendRequestIDs")

                // Create user
                let user = User(
                    id: userID,
                    name: name,
                    email: email,
                    profileImageURL: profileImageURL,
                    bio: bio,
                    children: children,
                    friendIDs: friendIDs,
                    friendRequestIDs: friendRequestIDs,
                    createdAt: createdAt,
                    lastActive: lastActive
                )

                print("🔍 User object created, updating on main thread")
                DispatchQueue.main.async {
                    self.user = user
                    print("🔍 User profile updated successfully")
                }
            }
        }
    }

    private func saveUserProfile(_ user: User, completion: @escaping (Bool) -> Void) {
        guard let id = user.id else {
            completion(false)
            return
        }

        do {
            try db.collection("users").document(id).setData(from: user)
            completion(true)
        } catch {
            self.error = error.localizedDescription
            completion(false)
        }
    }

    // MARK: - Children Management

    func addChild(name: String, age: Int, interests: [String]? = nil, completion: @escaping (Bool) -> Void) {
        guard var user = user, let id = user.id else {
            error = "User not signed in"
            completion(false)
            return
        }

        let newChild = PlaydateChild(name: name, age: age, interests: interests ?? [], parentID: id)

        if user.children == nil {
            user.children = [newChild]
        } else {
            user.children?.append(newChild)
        }

        saveUserProfile(user) { [weak self] success in
            guard let self = self else { return }

            if success {
                self.user = user
            } else {
                self.error = "Failed to add child"
            }

            completion(success)
        }
    }

    func updateChild(childID: String, name: String, age: Int, interests: [String]? = nil, completion: @escaping (Bool) -> Void) {
        guard var user = user, let id = user.id, var children = user.children else {
            error = "User not signed in or no children found"
            completion(false)
            return
        }

        guard let index = children.firstIndex(where: { $0.id == childID }) else {
            error = "Child not found"
            completion(false)
            return
        }

        let updatedChild = PlaydateChild(id: childID, name: name, age: age, interests: interests ?? [], parentID: id)
        children[index] = updatedChild
        user.children = children

        saveUserProfile(user) { [weak self] success in
            guard let self = self else { return }

            if success {
                self.user = user
            } else {
                self.error = "Failed to update child"
            }

            completion(success)
        }
    }

    func removeChild(childID: String, completion: @escaping (Bool) -> Void) {
        guard var user = user, let id = user.id, var children = user.children else {
            error = "User not signed in or no children found"
            completion(false)
            return
        }

        children.removeAll { $0.id == childID }
        user.children = children

        saveUserProfile(user) { [weak self] success in
            guard let self = self else { return }

            if success {
                self.user = user
            } else {
                self.error = "Failed to remove child"
            }

            completion(success)
        }
    }
}
