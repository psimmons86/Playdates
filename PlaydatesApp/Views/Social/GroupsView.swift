import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GroupViewModel.shared
    @State private var showingCreateGroupSheet = false
    @State private var searchText = ""
    @State private var selectedGroupType: GroupType?
    
    private var filteredGroups: [Group] {
        var groups = viewModel.userGroups
        
        // Apply search filter
        if !searchText.isEmpty {
            groups = groups.filter { group in
                group.name.lowercased().contains(searchText.lowercased()) ||
                group.description.lowercased().contains(searchText.lowercased()) ||
                group.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
        
        // Apply group type filter
        if let groupType = selectedGroupType {
            groups = groups.filter { $0.groupType == groupType }
        }
        
        return groups
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search and filter bar
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ColorTheme.lightText)
                            
                            TextField("Search groups", text: $searchText)
                                .foregroundColor(ColorTheme.text)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ColorTheme.lightText)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Group type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                GroupTypeFilterButton(
                                    type: nil,
                                    selectedType: $selectedGroupType,
                                    label: "All"
                                )
                                
                                GroupTypeFilterButton(
                                    type: .neighborhood,
                                    selectedType: $selectedGroupType,
                                    label: "Neighborhood"
                                )
                                
                                GroupTypeFilterButton(
                                    type: .ageBased,
                                    selectedType: $selectedGroupType,
                                    label: "Age-Based"
                                )
                                
                                GroupTypeFilterButton(
                                    type: .interestBased,
                                    selectedType: $selectedGroupType,
                                    label: "Interest-Based"
                                )
                                
                                GroupTypeFilterButton(
                                    type: .school,
                                    selectedType: $selectedGroupType,
                                    label: "School"
                                )
                                
                                GroupTypeFilterButton(
                                    type: .other,
                                    selectedType: $selectedGroupType,
                                    label: "Other"
                                )
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if filteredGroups.isEmpty {
                        Spacer()
                        EmptyGroupsView(showingCreateGroupSheet: $showingCreateGroupSheet)
                        Spacer()
                    } else {
                        // Groups list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupCard(group: group)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("My Groups")
            .navigationBarItems(trailing: Button(action: {
                showingCreateGroupSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ColorTheme.primary)
            })
            .sheet(isPresented: $showingCreateGroupSheet) {
                CreateGroupView()
            }
            .onAppear {
                if let userID = authViewModel.currentUser?.id {
                    viewModel.fetchUserGroups(userID: userID)
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct GroupTypeFilterButton: View {
    let type: GroupType?
    @Binding var selectedType: GroupType?
    let label: String
    
    var body: some View {
        Button(action: {
            if selectedType == type {
                selectedType = nil // Deselect if already selected
            } else {
                selectedType = type // Select new type
            }
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedType == type ? ColorTheme.primary : Color.white)
                .foregroundColor(selectedType == type ? .white : ColorTheme.text)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedType == type ? ColorTheme.primary : ColorTheme.lightText.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct GroupCard: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group header with image
            ZStack(alignment: .bottomLeading) {
                if let imageURL = group.coverImageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(ColorTheme.secondaryLight)
                                .aspectRatio(2.5, contentMode: .fit)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(2.5, contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(ColorTheme.secondaryLight)
                                .aspectRatio(2.5, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(ColorTheme.lightText)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(ColorTheme.secondaryLight)
                                .aspectRatio(2.5, contentMode: .fit)
                        }
                    }
                } else {
                    // Default background for groups without images
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [ColorTheme.primary.opacity(0.7), ColorTheme.accent]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(2.5, contentMode: .fit)
                }
                
                // Group type badge
                Text(group.groupType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(ColorTheme.primary)
                    .cornerRadius(16)
                    .padding(12)
            }
            .cornerRadius(12)
            
            // Group info
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(2)
                
                HStack {
                    // Member count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text("\(group.memberIDs.count) members")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(ColorTheme.lightText)
                    
                    Spacer()
                    
                    // Privacy badge
                    HStack(spacing: 4) {
                        Image(systemName: group.privacyType == .public ? "globe" : (group.privacyType == .private ? "lock" : "envelope"))
                            .font(.system(size: 12))
                        Text(group.privacyType.rawValue.capitalized)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(ColorTheme.lightText)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct EmptyGroupsView: View {
    @Binding var showingCreateGroupSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.lightText)
            
            Text("No Groups Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text("Join existing groups or create your own to connect with other parents in your community")
                .font(.body)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingCreateGroupSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create a Group")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Navigate to discover groups
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Discover Groups")
                    }
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ColorTheme.primary, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
        }
        .padding()
    }
}

struct CreateGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GroupViewModel.shared
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var groupType: GroupType = .neighborhood
    @State private var privacyType: GroupPrivacyType = .public
    @State private var tags = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Group name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Name")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            TextField("Enter group name", text: $groupName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Group description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            TextEditor(text: $groupDescription)
                                .frame(minHeight: 100)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Group type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Type")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            Picker("Group Type", selection: $groupType) {
                                Text("Neighborhood").tag(GroupType.neighborhood)
                                Text("Age-Based").tag(GroupType.ageBased)
                                Text("Interest-Based").tag(GroupType.interestBased)
                                Text("School").tag(GroupType.school)
                                Text("Other").tag(GroupType.other)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Privacy settings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            Picker("Privacy", selection: $privacyType) {
                                Text("Public").tag(GroupPrivacyType.public)
                                Text("Private").tag(GroupPrivacyType.private)
                                Text("Invite Only").tag(GroupPrivacyType.inviteOnly)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Text(privacyDescription)
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                                .padding(.top, 4)
                        }
                        
                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (comma separated)")
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                            
                            TextField("e.g. toddlers, outdoor activities, downtown", text: $tags)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Create button
                        Button(action: createGroup) {
                            Text("Create Group")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? ColorTheme.primary : ColorTheme.lightText)
                                .cornerRadius(12)
                        }
                        .disabled(!isFormValid)
                        .padding(.top, 16)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Group")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !groupName.isEmpty && !groupDescription.isEmpty
    }
    
    private var privacyDescription: String {
        switch privacyType {
        case .public:
            return "Anyone can find and join this group"
        case .private:
            return "Group is visible but members must be approved"
        case .inviteOnly:
            return "Group is hidden and members must be invited"
        }
    }
    
    private func createGroup() {
        guard let currentUser = authViewModel.currentUser, let userID = currentUser.id else {
            viewModel.errorMessage = "You must be logged in to create a group"
            return
        }
        
        let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        
        let newGroup = Group(
            name: groupName,
            description: groupDescription,
            groupType: groupType,
            privacyType: privacyType,
            memberIDs: [userID],
            adminIDs: [userID],
            tags: tagArray,
            createdBy: userID,
            allowMemberPosts: true,
            requirePostApproval: privacyType != .public,
            allowEvents: true,
            allowResourceSharing: true
        )
        
        viewModel.createGroup(group: newGroup) { result in
            switch result {
            case .success(_):
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// This is a placeholder for the group detail view
struct GroupDetailView: View {
    let group: Group
    
    var body: some View {
        Text("Group Detail View for \(group.name)")
            .navigationTitle(group.name)
    }
}

struct GroupsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupsView()
            .environmentObject(AuthViewModel())
    }
}
