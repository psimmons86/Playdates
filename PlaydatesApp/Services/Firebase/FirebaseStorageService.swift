import Foundation
import Firebase
import FirebaseStorage
import SwiftUI
import UIKit

class FirebaseStorageService {
    static let shared = FirebaseStorageService()

    // Provide direct access, using lazy initialization
    private lazy var storage: Storage = {
        print("FirebaseStorageService: Initializing Storage instance (lazy).")
        // This should now be safe as it's accessed after AppDelegate setup.
        return Storage.storage()
    }()

    // Private initializer
    private init() {
        print("FirebaseStorageService: Initialized.")
        // Initialization logic moved to lazy var storage or configure()
    }

    // Explicit configure method to be called AFTER FirebaseApp.configure()
    func configure() {
        print("FirebaseStorageService: Explicit configure() called.")
        // Accessing storage here triggers the lazy initialization safely.
        _ = self.storage
        print("FirebaseStorageService: Storage instance accessed via configure().")
    }

    // Provide access to the storage reference using the configured instance
    var storageRef: StorageReference {
        return storage.reference()
    }

    // --- Methods inside the class ---
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "FirebaseStorageService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }

        // Use the configured storage instance via the computed property
        let imageRef = storageRef.child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseStorageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }

                completion(.success(downloadURL.absoluteString))
            }
        }
    }

    func uploadProfileImage(_ image: UIImage, userID: String, completion: @escaping (Result<String, Error>) -> Void) {
        let path = "profile_images/\(userID)/\(UUID().uuidString).jpg"
        uploadImage(image, path: path, completion: completion)
    }

    /// Uploads multiple photos for a check-in and returns their download URLs.
    /// - Parameters:
    ///   - images: An array of UIImages to upload.
    ///   - userID: The ID of the user performing the check-in.
    ///   - activityID: The ID of the activity being checked into.
    ///   - completion: A closure called with the result (either an array of photo URLs or an error).
    func uploadCheckInPhotos(images: [UIImage], userID: String, activityID: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !images.isEmpty else {
            // If no images, return success with an empty array immediately.
            completion(.success([]))
            return
        }

        var uploadedURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var firstError: Error? = nil // To capture the first error that occurs

        for image in images {
            dispatchGroup.enter() // Enter group for each upload task

            let photoID = UUID().uuidString
            let path = "checkin_photos/\(userID)/\(activityID)/\(photoID).jpg"

            // Use the existing single image upload logic
            uploadImage(image, path: path) { result in
                // Ensure thread safety when modifying shared resources
                DispatchQueue.global().async(flags: .barrier) {
                    switch result {
                    case .success(let urlString):
                        // Only append if no error has occurred yet
                        if firstError == nil {
                            uploadedURLs.append(urlString)
                        }
                    case .failure(let error):
                        // Capture the first error encountered
                        if firstError == nil {
                            firstError = error
                            print("❌ Error uploading check-in photo: \(error.localizedDescription)")
                        }
                    }
                    dispatchGroup.leave() // Leave group when this upload completes or fails
                }
            }
        }

        // Notify on the main queue when all uploads are done
        dispatchGroup.notify(queue: .main) {
            if let error = firstError {
                // If any error occurred, report failure with the first error
                completion(.failure(error))
            } else {
                // If all uploads succeeded, report success with the URLs
                print("✅ Successfully uploaded \(uploadedURLs.count) check-in photos.")
                completion(.success(uploadedURLs))
            }
        }
    }
    // --- End of methods ---
} // Correct closing brace for the class
