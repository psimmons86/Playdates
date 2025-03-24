import SwiftUI
import FirebaseCore

@main
struct PlaydatesApp: App {
    // Apply the AppDelegate to handle Firebase initialization properly
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        print("🚀 PlaydatesApp: init")
        
        // Setup crash reporting (additional safety)
        setupCrashReporting()
    }
    
    var body: some Scene {
        WindowGroup {
            let authViewModel = AuthViewModel()
            let locationManager = LocationManager()
            
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(locationManager)
                .onAppear {
                    print("🚀 ContentView: onAppear")
                    // Initial check for authentication state
                    authViewModel.checkAuthState()
                }
                .onLoad {
                    print("🚀 PlaydatesApp: Creating WindowGroup")
                    print("🚀 PlaydatesApp: ViewModels initialized")
                }
        }
    }
    
    // Additional crash reporting setup (optional but recommended)
    private func setupCrashReporting() {
        // Monitor for uncaught Swift exceptions
        NSSetUncaughtExceptionHandler { exception in
            print("⚠️ UNCAUGHT EXCEPTION: \(exception)")
            print("⚠️ Reason: \(exception.reason ?? "Unknown")")
            print("⚠️ Name: \(exception.name)")
            print("⚠️ Stack trace:")
            for symbol in exception.callStackSymbols {
                print("  \(symbol)")
            }
        }
    }
}

// Helper extension to execute code when a view appears for the first time
extension View {
    func onLoad(perform action: @escaping () -> Void) -> some View {
        modifier(ViewDidLoadModifier(perform: action))
    }
}

// Modifier that will be called only once when view is loaded
struct ViewDidLoadModifier: ViewModifier {
    @State private var didLoad = false
    private let action: () -> Void
    
    init(perform action: @escaping () -> Void) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content.onAppear {
            if didLoad == false {
                didLoad = true
                action()
            }
        }
    }
}
