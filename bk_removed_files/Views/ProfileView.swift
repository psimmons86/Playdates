import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingEditProfileSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    profileHeader
                    
                    // Stats section
                    statsSection
                    
                    // Children section
                    childrenSection
                    
                    // Account section
                    accountSection
                    
                    // Sign out button
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarItems(
                trailing: Button(action: {
                    showingSettingsSheet = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorTheme.text)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            )
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileView()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .alert(isPresented: $showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                // Debug: Print user object
                print("DEBUG - User: \(String(describing: authViewModel.user))")
                if let user = authViewModel.user {
                    print("DEBUG - User name: \(user.name), type: \(type(of: user.name))")
                    print("DEBUG - User email: \(user.email), type: \(type(of: user.email))")
                    if let profileImageURL = user.profileImageURL {
                        print("DEBUG - profileImageURL: \(profileImageURL), type: \(type(of: profileImageURL))")
                    }
                    if let bio = user.bio {
                        print("DEBUG - bio: \(bio), type: \(type(of: bio))")
                    }
                    if let children = user.children {
                        print("DEBUG - children count: \(children.count), type: \(type(of: children))")
                        for (index, child) in children.enumerated() {
                            print("DEBUG - child[\(index)].name: \(child.name), type: \(type(of: child.name))")
                            print("DEBUG - child[\(index)].age: \(child.age), type: \(type(of: child.age))")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            if let user = authViewModel.user, let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                AsyncImage(url: URL(string: profileImageURL)) { phase in
                    switch phase {
                    case .empty:
                        profileImagePlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        profileImagePlaceholder
                    @unknown default:
                        profileImagePlaceholder
                    }
                }
            } else {
                profileImagePlaceholder
            }
            
            // Name and email
            VStack(spacing: 4) {
                Text(authViewModel.user?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.text)
                
                Text(authViewModel.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.text.opacity(0.6))
            }
            
            // Bio
            if let bio = authViewModel.user?.bio, !bio.isEmpty {
                // Debug: Print bio type
                let _ = print("DEBUG - Using bio in view: \(bio), type: \(type(of: bio))")
                
                Text(bio)
                    .font(.body)
                    .foregroundColor(ColorTheme.text.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Edit profile button
            Button(action: {
                showingEditProfileSheet = true
            }) {
                Text("Edit Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(ColorTheme.primary.opacity(0.1))
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var profileImagePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Text((authViewModel.user?.name.prefix(1).uppercased() ?? "U"))
                    .font(.system(size: 40))
                    .foregroundColor(ColorTheme.text.opacity(0.5))
            )
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(value: "0", label: "Playdates")
            
            Divider()
                .frame(width: 1, height: 40)
                .background(Color.gray.opacity(0.2))
            
            // Debug: Print children count
            let childrenCount = authViewModel.user?.children?.count ?? 0
            let _ = print("DEBUG - Children count: \(childrenCount), type: \(type(of: childrenCount))")
            
            // Convert the count to a string explicitly
            StatItem(value: String(childrenCount), label: "Children")
            
            Divider()
                .frame(width: 1, height: 40)
                .background(Color.gray.opacity(0.2))
            
            StatItem(value: "0", label: "Friends")
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Children")
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                Spacer()
                
                Button(action: {
                    // Add child
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ColorTheme.primary)
                        .padding(6)
                        .background(ColorTheme.primary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            if let children = authViewModel.user?.children, !children.isEmpty {
                ForEach(children) { child in
                    ChildRow(child: child)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.crop.square.stack")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.primary.opacity(0.7))
                    
                    Text("No Children Added")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.text)
                    
                    Text("Add your children to find suitable playdates.")
                        .font(.caption)
                        .foregroundColor(ColorTheme.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        // Add child
                    }) {
                        Text("Add Child")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(ColorTheme.primary)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account")
                .font(.headline)
                .foregroundColor(ColorTheme.text)
            
            VStack(spacing: 0) {
                NavigationLink(destination: NotificationsSettingsView()) {
                    SettingsRow(icon: "bell.fill", title: "Notifications")
                }
                
                Divider()
                    .padding(.leading, 40)
                
                NavigationLink(destination: PrivacySettingsView()) {
                    SettingsRow(icon: "lock.fill", title: "Privacy")
                }
                
                Divider()
                    .padding(.leading, 40)
                
                NavigationLink(destination: HelpSupportView()) {
                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support")
                }
                
                Divider()
                    .padding(.leading, 40)
                
                NavigationLink(destination: AboutView()) {
                    SettingsRow(icon: "info.circle.fill", title: "About")
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            authViewModel.user = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct StatItem: View {
    // Make sure value is always a String
    let value: String
    let label: String
    
    init(value: String, label: String) {
        // Debug: Print value type
        print("DEBUG - StatItem init - value: \(value), type: \(type(of: value))")
        self.value = value
        self.label = label
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text(label)
                .font(.caption)
                .foregroundColor(ColorTheme.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChildRow: View {
    let child: Child
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ColorTheme.primary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(child.name.prefix(1).uppercased())
                        .foregroundColor(ColorTheme.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.text)
                
                Text("\(child.age) years old")
                    .font(.caption)
                    .foregroundColor(ColorTheme.text.opacity(0.6))
            }
            
            Spacer()
            
            if let interests = child.interests, !interests.isEmpty {
                Text(interests.first ?? "")
                    .font(.caption)
                    .foregroundColor(ColorTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.primary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: {
                // Edit child
            }) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(ColorTheme.text.opacity(0.5))
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ColorTheme.primary)
                .frame(width: 28, height: 28)
                .background(ColorTheme.primary.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(ColorTheme.text)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    // Profile image
                    HStack {
                        Spacer()
                        
                        if let user = authViewModel.user, let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                            AsyncImage(url: URL(string: profileImageURL)) { phase in
                                switch phase {
                                case .empty:
                                    profileImagePlaceholder
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                case .failure:
                                    profileImagePlaceholder
                                @unknown default:
                                    profileImagePlaceholder
                                }
                            }
                        } else {
                            profileImagePlaceholder
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Button(action: {
                        // Change profile picture
                    }) {
                        Text("Change Profile Picture")
                            .foregroundColor(ColorTheme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    TextField("Name", text: $name)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                        
                        if bio.isEmpty {
                            Text("Bio (optional)")
                                .foregroundColor(Color.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        saveProfile()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(ColorTheme.primary)
                    .disabled(isLoading || name.isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                if let user = authViewModel.user {
                    name = user.name
                    bio = user.bio ?? ""
                    
                    // Debug: Print bio type
                    print("DEBUG - EditProfileView onAppear - bio: \(bio), type: \(type(of: bio))")
                }
            }
        }
    }
    
    private var profileImagePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(
                Text((authViewModel.user?.name.prefix(1).uppercased() ?? "U"))
                    .font(.system(size: 40))
                    .foregroundColor(ColorTheme.text.opacity(0.5))
            )
    }
    
    private func saveProfile() {
        guard let user = authViewModel.user else { return }
        
        isLoading = true
        
        // Debug: Print bio type before saving
        print("DEBUG - saveProfile - bio: \(bio), type: \(type(of: bio))")
        
        // Use the correct method name: updateUserProfile instead of updateProfile
        authViewModel.updateUserProfile(name: name, bio: bio, profileImageURL: user.profileImageURL) { success in
            isLoading = false
            
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        SettingsRow(icon: "bell.fill", title: "Notifications")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(icon: "lock.fill", title: "Privacy")
                    }
                    
                    NavigationLink(destination: Text("Account Settings")) {
                        SettingsRow(icon: "person.fill", title: "Account")
                    }
                }
                
                Section(header: Text("App")) {
                    NavigationLink(destination: Text("Appearance Settings")) {
                        SettingsRow(icon: "paintbrush.fill", title: "Appearance")
                    }
                    
                    NavigationLink(destination: Text("Language Settings")) {
                        SettingsRow(icon: "globe", title: "Language")
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: HelpSupportView()) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct NotificationsSettingsView: View {
    @State private var playdateReminders = true
    @State private var friendRequests = true
    @State private var playdateInvitations = true
    @State private var messages = true
    @State private var appUpdates = false
    
    var body: some View {
        List {
            Section(header: Text("Playdates")) {
                Toggle("Playdate Reminders", isOn: $playdateReminders)
                Toggle("Playdate Invitations", isOn: $playdateInvitations)
            }
            
            Section(header: Text("Social")) {
                Toggle("Friend Requests", isOn: $friendRequests)
                Toggle("Messages", isOn: $messages)
            }
            
            Section(header: Text("Other")) {
                Toggle("App Updates", isOn: $appUpdates)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PrivacySettingsView: View {
    @State private var profileVisibility = 0
    @State private var locationSharing = true
    @State private var activityVisibility = 0
    
    var body: some View {
        List {
            Section(header: Text("Profile")) {
                Picker("Profile Visibility", selection: $profileVisibility) {
                    Text("Everyone").tag(0)
                    Text("Friends Only").tag(1)
                    Text("Friends of Friends").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Location")) {
                Toggle("Share Location", isOn: $locationSharing)
                
                if locationSharing {
                    Text("Your location will be used to find nearby activities and playdates.")
                        .font(.caption)
                        .foregroundColor(Color.gray)
                }
            }
            
            Section(header: Text("Activities")) {
                Picker("Activity Visibility", selection: $activityVisibility) {
                    Text("Everyone").tag(0)
                    Text("Friends Only").tag(1)
                    Text("Private").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Control who can see your planned activities and playdates.")
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }
        }
        .navigationTitle("Privacy")
    }
}

struct HelpSupportView: View {
    var body: some View {
        List {
            Section(header: Text("Help Center")) {
                NavigationLink(destination: Text("FAQ Content")) {
                    Label("Frequently Asked Questions", systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: Text("Getting Started Guide")) {
                    Label("Getting Started", systemImage: "book.fill")
                }
                
                NavigationLink(destination: Text("Troubleshooting Guide")) {
                    Label("Troubleshooting", systemImage: "wrench.fill")
                }
            }
            
            Section(header: Text("Contact Us")) {
                Button(action: {
                    // Send email
                }) {
                    Label("Email Support", systemImage: "envelope.fill")
                }
                
                Button(action: {
                    // Open website
                }) {
                    Label("Visit Website", systemImage: "globe")
                }
            }
            
            Section(header: Text("Feedback")) {
                Button(action: {
                    // Report a problem
                }) {
                    Label("Report a Problem", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    // Suggest a feature
                }) {
                    Label("Suggest a Feature", systemImage: "lightbulb.fill")
                        .foregroundColor(ColorTheme.primary)
                }
            }
        }
        .navigationTitle("Help & Support")
    }
}

struct AboutView: View {
    let appVersion = "1.0.0"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(ColorTheme.primary)
                    
                    Text("Playdates")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section(header: Text("Information")) {
                NavigationLink(destination: Text("Terms of Service Content")) {
                    Text("Terms of Service")
                }
                
                NavigationLink(destination: Text("Privacy Policy Content")) {
                    Text("Privacy Policy")
                }
                
                NavigationLink(destination: Text("Licenses Content")) {
                    Text("Licenses")
                }
            }
            
            Section(header: Text("Follow Us")) {
                Button(action: {
                    // Open Twitter
                }) {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.blue)
                        Text("Twitter")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    // Open Instagram
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.purple)
                        Text("Instagram")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                Text("© 2025 Playdates App. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("About")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
