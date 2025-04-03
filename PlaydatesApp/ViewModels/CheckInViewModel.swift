import Foundation
import SwiftUI
import Firebase
import Combine

@MainActor
class CheckInViewModel: ObservableObject {

    @Published var selectedImages: [UIImage] = []
    @Published var comment: String = ""
    @Published var taggedFriends: [User] = [] // Store tagged User objects
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successfullyCheckedIn: Bool = false

    private let firestoreService = FirestoreService.shared
    private let storageService = FirebaseStorageService.shared
    private var cancellables = Set<AnyCancellable>()

    // Dependency for current user info
    private let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        print("✅ CheckInViewModel initialized.")
    }

    /// Performs the check-in process: uploads photos, then creates the Firestore document.
    func performCheckIn(activity: Activity) {
        guard let currentUser = authViewModel.user, let userId = currentUser.id else {
            errorMessage = "User not logged in."
            print("❌ Check-in failed: User not logged in.")
            return
        }
        guard let activityId = activity.id else {
            errorMessage = "Activity ID is missing."
            print("❌ Check-in failed: Activity ID missing.")
            return
        }

        isLoading = true
        errorMessage = nil
        successfullyCheckedIn = false
        print("🚀 Starting check-in process for activity: \(activity.name)")

        // 1. Upload Photos (if any)
        uploadPhotosIfNeeded(userId: userId, activityId: activityId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let photoURLs):
                print("✅ Photos uploaded successfully (\(photoURLs.count) photos).")
                // 2. Create CheckIn object
                let checkInData = CheckIn(
                    activityID: activityId,
                    activityName: activity.name, // Store activity name for easier display
                    userID: userId,
                    userName: currentUser.name ?? "Unknown User", // Use current user's name
                    userProfileImageURL: currentUser.profileImageURL, // Use current user's image
                    timestamp: Timestamp(date: Date()), // Use current time
                    comment: self.comment.isEmpty ? nil : self.comment,
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    taggedUserIDs: self.taggedFriends.compactMap { $0.id } // Get IDs from User objects
                )

                // 3. Save CheckIn to Firestore
                self.saveCheckIn(checkInData)

            case .failure(let error):
                print("❌ Photo upload failed: \(error.localizedDescription)")
                self.errorMessage = "Failed to upload photos: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Helper to upload photos if selected, otherwise returns success with empty array.
    private func uploadPhotosIfNeeded(userId: String, activityId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        if selectedImages.isEmpty {
            print("ℹ️ No photos selected for upload.")
            completion(.success([])) // No photos to upload, proceed successfully
        } else {
            print("⏳ Uploading \(selectedImages.count) photos...")
            storageService.uploadCheckInPhotos(images: selectedImages, userID: userId, activityID: activityId, completion: completion)
        }
    }

    /// Helper to save the CheckIn object to Firestore.
    private func saveCheckIn(_ checkIn: CheckIn) {
        print("⏳ Saving check-in data to Firestore...")
        firestoreService.createCheckIn(checkIn) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false // Loading finishes here

            switch result {
            case .success(let savedCheckIn):
                print("✅ Check-in saved successfully! ID: \(savedCheckIn.id ?? "N/A")")
                self.successfullyCheckedIn = true
                // Optionally clear fields after successful check-in
                self.clearInputFields()
            case .failure(let error):
                print("❌ Failed to save check-in: \(error.localizedDescription)")
                self.errorMessage = "Failed to save check-in: \(error.localizedDescription)"
            }
        }
    }

    /// Clears the input fields after a successful check-in.
    func clearInputFields() {
        selectedImages = []
        comment = ""
        taggedFriends = []
        errorMessage = nil
        // Keep isLoading = false, successfullyCheckedIn = true until view dismisses
    }

    // --- Friend Tagging Logic (Placeholder - Needs Friend Data) ---

    // This would typically involve fetching the user's friends
    // For now, we'll assume a way to get friend data exists.
    // You might need to inject FriendManagementViewModel or similar.

    func addTaggedFriend(_ friend: User) {
        if !taggedFriends.contains(where: { $0.id == friend.id }) {
            taggedFriends.append(friend)
        }
    }

    func removeTaggedFriend(_ friend: User) {
        taggedFriends.removeAll { $0.id == friend.id }
    }
}
