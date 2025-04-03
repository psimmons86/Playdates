import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase
import FirebaseStorage

// MARK: - Helper Views

struct ProfileHeaderView: View {
    let profileUser: User?
    let isCurrentUser: Bool
    @ObservedObject var authViewModel: AuthViewModel
    let onEditProfile: () -> Void

    init(profileUser: User?, isCurrentUser: Bool, authViewModel: AuthViewModel, onEditProfile: @escaping () -> Void) {
        self.profileUser = profileUser
        self.isCurrentUser = isCurrentUser
        self.authViewModel = authViewModel
        self.onEditProfile = onEditProfile
    }

    private var friendCount: Int { profileUser?.friendIDs?.count ?? 0 }
    private var childrenCount: Int { profileUser?.children?.count ?? 0 }
    private var playdatesHosted: Int = 0 // Placeholder

    var body: some View {
        VStack(spacing: 16) {
            ProfileImageView(imageURL: profileUser?.profileImageURL, size: 100)

            VStack(spacing: 4) {
                Text(profileUser?.name ?? "User Name")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(profileUser?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                if isCurrentUser {
                    Button("Edit Profile") {
                        onEditProfile()
                    }
                    .secondaryStyle()
                } else {
                    Button("Add Friend") {
                        // Action: Send friend request
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Message") {
                        if let friend = profileUser {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenChatWithFriend"),
                                object: nil,
                                userInfo: ["friend": friend]
                            )
                        }
                    }
                    .secondaryStyle()
                }
            }

            HStack {
                Spacer()
                StatItem(value: friendCount, label: "Friends")
                Spacer()
                StatItem(value: childrenCount, label: "Children")
                Spacer()
                StatItem(value: playdatesHosted, label: "Hosted")
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

struct ProfileContentGridView: View {
    let userId: String?
    @EnvironmentObject var activityViewModel: AppActivityViewModel

    init(userId: String?) {
        self.userId = userId
    }

    private var userActivities: [AppActivity] {
        guard let id = userId else { return [] }
        return activityViewModel.activities.filter { $0.userID == id }
    }

    private let gridItems = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            if activityViewModel.isLoading && userActivities.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if userActivities.isEmpty {
                Text("No recent activity to display.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                LazyVGrid(columns: gridItems, spacing: 4) {
                    ForEach(userActivities.prefix(6)) { activity in
                        ActivityGridItemView(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ActivityGridItemView: View {
    let activity: AppActivity

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.gray.opacity(0.1)
                .aspectRatio(1, contentMode: .fill)

            VStack(alignment: .leading) {
                Image(systemName: activity.systemIcon)
                    .foregroundColor(ColorTheme.primary)
                    .font(.title2)
                Text(activity.description)
                    .font(.caption2)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            .padding(6)
        }
        .cornerRadius(8)
        .clipped()
    }
}

struct StatItem: View {
    let value: Int
    let label: String

    init(value: Int, label: String) {
        self.value = value
        self.label = label
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ChildrenSectionView: View {
    let children: [PlaydateChild]
    let isCurrentUser: Bool
    let onAddChild: () -> Void
    let onEditChild: (String) -> Void

    init(children: [PlaydateChild], isCurrentUser: Bool, onAddChild: @escaping () -> Void, onEditChild: @escaping (String) -> Void) {
        self.children = children
        self.isCurrentUser = isCurrentUser
        self.onAddChild = onAddChild
        self.onEditChild = onEditChild
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("profile.children", comment: "Children section header"))
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                if isCurrentUser {
                    Button { onAddChild() } label: {
                        Image(systemName: "plus")
                    }
                    .secondaryStyle()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
            }

            ForEach(children) { child in
                EnhancedChildProfileCard(
                    child: child,
                    onEdit: { onEditChild(child.id ?? "") }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct NoChildrenView: View {
    let onAddChild: () -> Void

    init(onAddChild: @escaping () -> Void) {
        self.onAddChild = onAddChild
    }

    var body: some View {
         VStack(spacing: 16) {
             Image(systemName: "figure.and.child.holdinghands")
                 .font(.system(size: 40))
                 .foregroundColor(ColorTheme.lightText)
             Text(NSLocalizedString("profile.noChildren", comment: "No children message"))
                 .font(.headline)
                 .foregroundColor(ColorTheme.lightText)
             Text(NSLocalizedString("profile.noChildrenMessage", comment: "No children explanation"))
                 .font(.subheadline)
                 .foregroundColor(ColorTheme.lightText)
                 .multilineTextAlignment(.center)
             Button { onAddChild() } label: {
                 Text(NSLocalizedString("profile.addChild", comment: "Add child button"))
             }
             .buttonStyle(PrimaryButtonStyle())
             .padding(.top, 10)
         }
         .padding(30)
         .frame(maxWidth: .infinity)
         .background(Color.white)
         .cornerRadius(12)
         .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct SettingsSectionView: View {
     @ObservedObject var authViewModel: AuthViewModel

     init(authViewModel: AuthViewModel) {
         self.authViewModel = authViewModel
     }

     var body: some View {
         VStack(alignment: .leading, spacing: 0) {
             Text(NSLocalizedString("profile.settings", comment: "Settings section header"))
                 .font(.title3)
                 .fontWeight(.bold)
                 .padding(.bottom, 12)

             SettingsRowButton(icon: "gear", title: "Account Settings", action: {})
             SettingsRowButton(icon: "bell", title: "Notifications", action: {})
             SettingsRowButton(icon: "lock.shield", title: "Privacy", action: {})
             SettingsRowButton(icon: "questionmark.circle", title: "Help & Support", action: {})

             Divider().padding(.vertical, 8)

             Button { authViewModel.signOut() } label: {
                 HStack {
                     Image(systemName: "arrow.right.square")
                     Text(NSLocalizedString("profile.signOut", comment: "Sign out button"))
                     Spacer()
                     Image(systemName: "chevron.right")
                 }
                 .foregroundColor(.red)
             }
             .padding(.vertical, 10)
         }
         .padding()
         .background(Color.white)
         .cornerRadius(12)
         .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
     }
 }

struct SettingsRowButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    init(icon: String, title: String, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(ColorTheme.primary)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(ColorTheme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedChildProfileCard: View {
    let child: PlaydateChild
    let onEdit: () -> Void

    init(child: PlaydateChild, onEdit: @escaping () -> Void) {
        self.child = child
        self.onEdit = onEdit
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [ColorTheme.accent, ColorTheme.highlight.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "figure.child")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(child.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.darkPurple)

                Text("\(child.age) years old")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)

                if !child.interests.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(child.interests.prefix(3), id: \.self) { interest in
                                Text(interest)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.accent.opacity(0.2))
                                    .foregroundColor(ColorTheme.darkPurple)
                                    .cornerRadius(12)
                            }

                            if child.interests.count > 3 {
                                Text("+\(child.interests.count - 3)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.lightBackground)
                                    .foregroundColor(ColorTheme.lightText)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .frame(height: 25)
                }
            }

            Spacer()

            if onEdit != nil {
                 Button { onEdit() } label: {
                     Image(systemName: "pencil.circle.fill")
                         .font(.system(size: 24))
                         .foregroundColor(ColorTheme.primary)
                 }
                 .buttonStyle(PlainButtonStyle())
             }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EditProfileView: View {
    let user: User?
    let onSave: (String, String?, String?) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var bio: String
    @State private var profileImageURL: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isUploading = false
    @State private var uploadError: String?
    
    init(user: User?, onSave: @escaping (String, String?, String?) -> Void, onCancel: @escaping () -> Void) {
        self.user = user
        self.onSave = onSave
        self.onCancel = onCancel
        
        _name = State(initialValue: user?.name ?? "")
        _bio = State(initialValue: user?.bio ?? "")
        _profileImageURL = State(initialValue: user?.profileImageURL ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("profile.edit.info", comment: "Profile information section"))) {
                    TextField(NSLocalizedString("profile.edit.name", comment: "Name field"), text: $name)
                    
                    TextField(NSLocalizedString("profile.edit.bio", comment: "Bio field"), text: $bio)
                        .frame(height: 100, alignment: .top)
                        .multilineTextAlignment(.leading)
                }
                
                Section(header: Text(NSLocalizedString("profile.edit.image", comment: "Profile image section"))) {
                    VStack(spacing: 16) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(ColorTheme.primary, lineWidth: 2))
                                .padding(.vertical, 8)
                        } else if !profileImageURL.isEmpty {
                            ProfileImageView(imageURL: profileImageURL, size: 150)
                                .overlay(Circle().stroke(ColorTheme.primary, lineWidth: 2))
                                .padding(.vertical, 8)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(ColorTheme.primary.opacity(0.7))
                                .frame(width: 150, height: 150)
                                .padding(.vertical, 8)
                        }
                        
                        Button {
                            showingImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Photo")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Text("Or enter image URL:")
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                        
                        TextField(NSLocalizedString("profile.edit.imageUrl", comment: "Image URL field"), text: $profileImageURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if let error = uploadError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(NSLocalizedString("profile.edit.title", comment: "Edit profile title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("common.cancel", comment: "Cancel button")) {
                    onCancel()
                },
                trailing: Button(NSLocalizedString("common.save", comment: "Save button")) {
                    saveProfile()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.white.opacity(0.9)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Uploading image...")
                                .padding(.top, 8)
                        }
                    }
                    .frame(width: 200, height: 100)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
        }
    }
    
    private func saveProfile() {
        if let selectedImage = selectedImage, let userId = user?.id {
            isUploading = true
            uploadError = nil
            
            let storageRef = Storage.storage().reference().child("profile_images/\(userId)/\(UUID().uuidString).jpg")
            
            guard let imageData = selectedImage.jpegData(compressionQuality: 0.75) else {
                uploadError = "Failed to convert image to data"
                isUploading = false
                return
            }
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    DispatchQueue.main.async {
                        isUploading = false
                        uploadError = "Failed to upload image: \(error.localizedDescription)"
                    }
                    return
                }
                
                storageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        isUploading = false
                        
                        if let error = error {
                            uploadError = "Failed to get download URL: \(error.localizedDescription)"
                            return
                        }
                        
                        guard let downloadURL = url else {
                            uploadError = "Failed to get download URL"
                            return
                        }
                        
                        onSave(
                            name,
                            bio.isEmpty ? nil : bio,
                            downloadURL.absoluteString
                        )
                    }
                }
            }
        } else {
            onSave(
                name,
                bio.isEmpty ? nil : bio,
                profileImageURL.isEmpty ? nil : profileImageURL
            )
        }
    }
}

struct EditChildView: View {
    // Make child optional to handle add mode
    let child: PlaydateChild?
    let onSave: (String, Int, [String]) -> Void
    let onCancel: () -> Void
    
    @State private var name: String
    @State private var ageString: String
    @State private var selectedInterests: [String]
    
    let interestOptions = [
        "Sports", "Arts & Crafts", "Music", "Reading",
        "Dance", "Nature", "Science", "Board Games"
    ]

    // Updated initializer to accept optional child
    init(child: PlaydateChild?, onSave: @escaping (String, Int, [String]) -> Void, onCancel: @escaping () -> Void) {
        self.child = child
        self.onSave = onSave
        self.onCancel = onCancel

        // Set initial values based on whether a child was provided (edit mode) or not (add mode)
        _name = State(initialValue: child?.name ?? "")
        _ageString = State(initialValue: child != nil ? String(child!.age) : "")
        _selectedInterests = State(initialValue: child?.interests ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("profile.child.info", comment: "Child information section"))) {
                    TextField(NSLocalizedString("profile.child.name", comment: "Child name field"), text: $name)
                    
                    TextField(NSLocalizedString("profile.child.age", comment: "Child age field"), text: $ageString)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text(NSLocalizedString("profile.child.interests", comment: "Child interests section"))) {
                    ForEach(interestOptions, id: \.self) { interest in
                        Button {
                            toggleInterest(interest)
                        } label: {
                            HStack {
                                Text(interest)
                                    .foregroundColor(ColorTheme.darkText)
                                
                                Spacer()
                                
                                if selectedInterests.contains(interest) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ColorTheme.primary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            // Dynamically set title based on add/edit mode
            .navigationTitle(child == nil ? NSLocalizedString("profile.child.addTitle", comment: "Add child title") : NSLocalizedString("profile.child.editTitle", comment: "Edit child title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("common.cancel", comment: "Cancel button")) {
                    onCancel()
                },
                trailing: Button(NSLocalizedString("common.save", comment: "Save button")) {
                    // Use 0 as default age if string is invalid or empty, especially for add mode
                    let age = Int(ageString) ?? 0
                    onSave(name, age, selectedInterests)
                }
                // Also disable save if age string is empty
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.removeAll { $0 == interest }
        } else {
            selectedInterests.append(interest)
        }
    }
}

// MARK: - Main Profile View

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appActivityViewModel: AppActivityViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    // Removed showingChildSetupSheet as we'll reuse EditChildView for adding
    @State private var showingEditProfileSheet = false
    @State private var showingEditChildSheet = false
    @State private var selectedChildID: String? = nil // nil indicates "add mode" for the sheet
    @State private var profileUser: User?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let userId: String?
    private let isCurrentUser: Bool
    
    init() {
        self.userId = nil
        self.isCurrentUser = true
    }
    
    init(userId: String?, user: User? = nil) {
        self.userId = userId
        self.isCurrentUser = userId == nil
        self._profileUser = State(initialValue: user)
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading profile...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading profile")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("Retry") {
                        if let userId = userId {
                            loadUserProfile(userId: userId)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                profileContent
            }
        }
        .onAppear {
            if let userId = userId, let authUser = authViewModel.user, userId != authUser.id {
                loadUserProfile(userId: userId)
            } else {
                profileUser = authViewModel.user
            }
        }
        // Removed sheet for showingChildSetupSheet
        .sheet(isPresented: $showingEditProfileSheet) {
            EditProfileView(
                user: profileUser, // Use the local profileUser state
                onSave: { name, bio, imageURL in
                    // Use the correct authViewModel instance
                    authViewModel.updateUserProfile(name: name, bio: bio, profileImageURL: imageURL) { success in
                        if success {
                            // Optionally refresh local profileUser if needed, though authViewModel should publish changes
                            self.profileUser = authViewModel.user // Update local state from view model
                        }
                        showingEditProfileSheet = false
                    }
                },
                onCancel: { showingEditProfileSheet = false }
            )
        }
        .sheet(isPresented: $showingEditChildSheet) {
            // Determine if we are adding (selectedChildID is nil) or editing
            let childToEdit = profileUser?.children?.first(where: { $0.id == selectedChildID })

            EditChildView(
                child: childToEdit, // Pass nil for add mode, existing child for edit mode
                onSave: { name, age, interests in
                    if let childId = selectedChildID {
                        // Edit existing child
                        authViewModel.updateChild(childID: childId, name: name, age: age, interests: interests) { success in
                            if success {
                                self.profileUser = authViewModel.user // Update local state
                            }
                            showingEditChildSheet = false
                        }
                    } else {
                        // Add new child
                        authViewModel.addChild(name: name, age: age, interests: interests) { success in
                             if success {
                                 self.profileUser = authViewModel.user // Update local state
                             }
                             showingEditChildSheet = false
                        }
                    }
                },
                onCancel: { showingEditChildSheet = false }
            )
        }
    }
    
    private func loadUserProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    self.errorMessage = "User profile not found"
                    return
                }
                
                do {
                    let user = try snapshot.data(as: User.self)
                    self.profileUser = user
                } catch {
                    self.errorMessage = "Failed to parse user data: \(error.localizedDescription)"
                }
            }
        }
    }

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 0) { // Changed spacing to 0, rely on padding below
                ProfileHeaderView(
                    profileUser: profileUser,
                    isCurrentUser: isCurrentUser,
                    authViewModel: authViewModel,
                    onEditProfile: { showingEditProfileSheet = true }
                )
                .padding(.bottom, 20)

                if let children = profileUser?.children, !children.isEmpty {
                    ChildrenSectionView(
                        children: children,
                        isCurrentUser: isCurrentUser,
                        onAddChild: {
                            selectedChildID = nil // Set to nil for add mode
                            showingEditChildSheet = true
                        },
                        onEditChild: { childId in
                            selectedChildID = childId // Set ID for edit mode
                            showingEditChildSheet = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                 } else if isCurrentUser {
                     NoChildrenView(onAddChild: {
                         selectedChildID = nil // Set to nil for add mode
                         showingEditChildSheet = true
                     })
                     .padding(.horizontal)
                     .padding(.bottom, 20)
                 }

                ProfileContentGridView(userId: profileUser?.id)
                    .padding(.horizontal)
                    .padding(.bottom, 20)

                if isCurrentUser {
                    WantToDoSectionView()
                        .environmentObject(activityViewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }

                if isCurrentUser {
                    SettingsSectionView(authViewModel: authViewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }

                Spacer() // Pushes content up if it doesn't fill the screen
            }
            .padding(.top, 10) // Add padding at the top of the scroll view content
        }
        .background(ColorTheme.background)
        .navigationTitle(isCurrentUser ?
                        NSLocalizedString("profile.title", comment: "Profile screen title") :
                        profileUser?.name ?? "Profile")
        .navigationBarItems(trailing: isCurrentUser ? Button {
             showingEditProfileSheet = true
        } label: {
            Image(systemName: "gearshape.fill")
        } : nil)
    }
} // This should be the closing brace for ProfileView

// MARK: - Want To Do Section View
struct WantToDoSectionView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel

    private var wantToDoActivities: [Activity] {
        let allKnownActivities: [Activity] = activityViewModel.activities + activityViewModel.nearbyActivities + activityViewModel.popularActivities
        var resultActivities: [Activity] = []
        let targetIDs: Set<String> = activityViewModel.wantToDoActivityIDs
        
        for activity: Activity in allKnownActivities {
            if let currentId: String = activity.id {
                if targetIDs.contains(currentId) {
                    resultActivities.append(activity)
                }
            }
        }
        return resultActivities
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Want to Do")
                .font(.title3)
                .fontWeight(.bold)

            if wantToDoActivities.isEmpty {
                Text("No activities saved to your 'Want to Do' list yet.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 50)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(wantToDoActivities) { activity in
                            ExploreActivityCard(activity: activity)
                                .environmentObject(activityViewModel)
                                .frame(width: 200)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
