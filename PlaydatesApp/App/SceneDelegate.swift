import UIKit
import SwiftUI
import Firebase

// This class is now deprecated as we're using the SwiftUI lifecycle with @main in PlaydatesApp.swift
// But we'll keep it here with proper syntax in case the app needs to revert back to UIKit lifecycle
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // Create instances of our view models
    let authViewModel = AuthViewModel()
    let locationManager = LocationManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Note: Firebase is configured in AppDelegate.application(_:didFinishLaunchingWithOptions:)

        // Create the SwiftUI view that provides the window contents
        let contentView = ContentView()
            .environmentObject(authViewModel)
            .environmentObject(locationManager)

        // Use a UIHostingController as window root view controller
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
    }

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
