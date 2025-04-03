import Foundation
import Firebase
import FirebaseAuth

class FirebaseAuthService {
    static let shared = FirebaseAuthService()

    // Private initializer
    private init() {
        print("FirebaseAuthService: Initialized.")
        // Initialization logic moved to lazy var auth or configure()
    }

    // Provide direct access, using lazy initialization
    lazy var auth: Auth = {
        print("FirebaseAuthService: Initializing Auth instance (lazy).")
        // This should now be safe as it's accessed after AppDelegate setup.
        return Auth.auth()
    }()

    // Explicit configure method to be called AFTER FirebaseApp.configure()
    func configure() {
        print("FirebaseAuthService: Explicit configure() called.")
        // Accessing auth here triggers the lazy initialization safely.
        _ = self.auth
        print("FirebaseAuthService: Auth instance accessed via configure().")
    }

    // Convenience property for current user
    var currentUser: FirebaseAuth.User? {
        return auth.currentUser
    }
}
