import UIKit
import SwiftUI
import Firebase

// This class is now deprecated as we're using the SwiftUI lifecycle with @main in PlaydatesApp.swift
// But we'll keep it here with proper syntax in case the app needs to revert back to UIKit lifecycle
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // ViewModels are now managed by the @main App struct (PlaydatesApp.swift)
    // Remove direct initialization here to prevent premature Firebase access.
    // let authViewModel = AuthViewModel() // REMOVED
    // let locationManager = LocationManager() // REMOVED (Assuming managed in PlaydatesApp)

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // This setup is likely superseded by the @main App struct lifecycle.
        // If the app IS using SceneDelegate, it needs to get ViewModels differently,
        // perhaps from the AppDelegate or another shared source AFTER configuration.
        // For now, assuming @main is primary, we comment out the view setup here too.
        /*
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Note: Firebase is configured in AppDelegate.application(_:didFinishLaunchingWithOptions:)

        // ViewModels should be injected from PlaydatesApp via .environmentObject
        // This ContentView might not even be the one used by @main App.
        // let contentView = ContentView()
        //     .environmentObject(authViewModel) // authViewModel no longer exists here
        //     .environmentObject(locationManager) // locationManager no longer exists here

        // Use a UIHostingController as window root view controller
        let window = UIWindow(windowScene: windowScene)
        // window.rootViewController = UIHostingController(rootView: contentView) // contentView setup removed
        // self.window = window
        // window.makeKeyAndVisible()
        */
        print("⚠️ SceneDelegate.scene(_:willConnectTo:) called - Ensure this isn't conflicting with the @main App lifecycle.")
    }
    // Removed extraneous lines that were outside the comment block

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
