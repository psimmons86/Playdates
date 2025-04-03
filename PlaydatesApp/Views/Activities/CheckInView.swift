import SwiftUI
import PhotosUI // For PHPickerViewController

struct CheckInView: View {
    let activity: Activity
    @StateObject private var viewModel: CheckInViewModel
    // AuthViewModel is needed by the CheckInViewModel initializer
    // It will be passed in via the init(activity:authViewModel:)
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var friendManagementViewModel: FriendManagementViewModel // Receive FriendManagementViewModel
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    // State for Image Picker
    @State private var showingImagePicker = false

    // State for Friend Tagging
    @State private var showingFriendSelector = false
    // Remove the local availableFriends state, we'll use friendManagementViewModel.friends

    // Computed property to check if check-in is possible
    private var canCheckIn: Bool {
        // Check if viewModel is initialized and user is logged in
        !viewModel.isLoading && authViewModel.user != nil && activity.id != nil
    }

     // Designated initializer: Requires AuthViewModel to be passed
     init(activity: Activity, authViewModel: AuthViewModel) {
         self.activity = activity
         // Initialize the ViewModel, passing the necessary AuthViewModel
         _viewModel = StateObject(wrappedValue: CheckInViewModel(authViewModel: authViewModel))
     }

    // MARK: - Corrected Body Content
    var body: some View {
        NavigationView {
            Form {
                // Section: Activity Info
                Section(header: Text("Checking In To")) {
                    HStack {
                        // You might want a small icon or image for the activity type
                        Image(systemName: activity.type.iconName) // Assuming ActivityType has an iconName
                            .foregroundColor(ColorTheme.primary)
                        Text(activity.name).font(.headline)
                    }
                }

                // Section: Photos (Restored)
                Section(header: Text("Add Photos")) {
                    // Display selected images
                    if !viewModel.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                                    Image(uiImage: viewModel.selectedImages[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            // Button to remove image
                                            Button {
                                                viewModel.selectedImages.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Circle().fill(Color.white.opacity(0.7)))
                                                    .padding(4)
                                            }
                                            .buttonStyle(BorderlessButtonStyle()), // Keep Borderless here as it worked before
                                            alignment: .topTrailing
                                        )
                                }
                            }
                        }
                        .frame(height: 90) // Adjust height as needed
                    }

                    // Button to add photos
                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(viewModel.selectedImages.isEmpty ? "Select Photos" : "Add More Photos")
                        }
                    }
                }

                // Section: Comment (Restored)
                Section(header: Text("Comment (Optional)")) {
                    TextEditor(text: $viewModel.comment)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.2)) // Subtle border
                }

                // Section: Tag Friends (Restored, but NO ScrollView)
                Section(header: Text("Tag Friends (Optional)")) {
                    if !viewModel.taggedFriends.isEmpty {
                        // Using HStack directly instead of ScrollView
                        HStack {
                            ForEach(viewModel.taggedFriends) { friend in
                                // Restoring original HStack with Button
                                HStack {
                                    Text(friend.name ?? "Unknown")
                                    Button {
                                        viewModel.removeTaggedFriend(friend)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    // Keep BorderlessButtonStyle removed
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            } // End ForEach
                        } // End Outer HStack
                    } // End if !viewModel.taggedFriends.isEmpty
                    // Button to open friend selector
                    Button {
                        showingFriendSelector = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Tag Friends")
                        }
                    }
                }

                // Section: Check In Button
                Section {
                    Button {
                        viewModel.performCheckIn(activity: activity)
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Check In")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canCheckIn) // Disable if loading or not logged in
                }

                // Display Error Messages (Restored)
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Activity Check-In")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        // Attaching sheets to NavigationView
        .sheet(isPresented: $showingImagePicker) {
             MultiImagePicker(selectedImages: $viewModel.selectedImages)
        }
        .sheet(isPresented: $showingFriendSelector) {
            // Pass the actual friends list from the view model
            FriendSelectorView(availableFriends: friendManagementViewModel.friends, taggedFriends: $viewModel.taggedFriends)
        }
        .onChange(of: viewModel.successfullyCheckedIn) { success in // Keeping onChange on NavigationView
            // Dismiss view on successful check-in
            if success {
                presentationMode.wrappedValue.dismiss()
                // Optionally show a success banner/toast via another mechanism
            }
        }
        // EnvironmentObject for AuthViewModel is expected to be provided by the parent view (ExploreActivityDetailView)
        // .environmentObject(authViewModel) // This modifier isn't needed here if passed down correctly
    }
}

// MARK: - Friend Selector View
struct FriendSelectorView: View {
    let availableFriends: [User] // Now receives the list directly
    @Binding var taggedFriends: [User]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        // Restoring original NavigationView structure for FriendSelectorView
        NavigationView {
            List {
                ForEach(availableFriends) { friend in
                    Button {
                        toggleFriendSelection(friend)
                    } label: {
                        HStack {
                            Text(friend.name ?? "Unknown Friend")
                            Spacer()
                            if taggedFriends.contains(where: { $0.id == friend.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Tag Friends") // Restore title
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            // Remove the onAppear block that generated mock data
        }
    }

    private func toggleFriendSelection(_ friend: User) {
        if let index = taggedFriends.firstIndex(where: { $0.id == friend.id }) {
            taggedFriends.remove(at: index)
        } else {
            taggedFriends.append(friend)
        }
    }
}

// MARK: - Preview
struct CheckInView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy activity for preview
        let dummyActivity = Activity(
            id: "previewActivity123",
            name: "Central Park Playground",
            description: "A fun place for kids.",
            type: .playground,
            location: Location(name: "Central Park", address: "123 Park Lane", latitude: 40.78, longitude: -73.96)
        )

        // Create dummy AuthViewModel state
        let authVM = AuthViewModel()
        authVM.user = User(id: "previewUser123", name: "Preview User", email: "preview@test.com")

        // Create dummy FriendManagementViewModel state for preview
        let friendVM = FriendManagementViewModel(authViewModel: authVM) // Needs AuthViewModel
        friendVM.friends = [
            User(id: "friend1", name: "Friend One", email: "f1@test.com"),
            User(id: "friend2", name: "Friend Two", email: "f2@test.com")
        ]

        // Use the init that accepts AuthViewModel for preview consistency
        return CheckInView(activity: dummyActivity, authViewModel: authVM)
            .environmentObject(authVM) // Provide AuthViewModel
            .environmentObject(friendVM) // Provide FriendManagementViewModel
    }
}

// MARK: - MultiImagePicker (Optional - using PHPicker)
struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Only allow images
        config.selectionLimit = 0 // 0 means no limit
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker

        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            // Clear previous selections if you want replacement behavior, otherwise append
            // parent.selectedImages.removeAll()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, _) in
                        if let image = image as? UIImage {
                            // Append images on the main thread
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}
