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
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
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
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Group type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                CategoryButton(
                                    title: "All",
                                    isSelected: selectedGroupType == nil,
                                    action: { selectedGroupType = nil }
                                )
                                
                                CategoryButton(
                                    title: "Neighborhood",
                                    isSelected: selectedGroupType == .neighborhood,
                                    action: { selectedGroupType = .neighborhood }
                                )
                                
                                CategoryButton(
                                    title: "Age-Based",
                                    isSelected: selectedGroupType == .ageBased,
                                    action: { selectedGroupType = .ageBased }
                                )
                                
                                CategoryButton(
                                    title: "Interest",
                                    isSelected: selectedGroupType == .interestBased,
                                    action: { selectedGroupType = .interestBased }
                                )
                                
                                CategoryButton(
                                    title: "School",
                                    isSelected: selectedGroupType == .school,
                                    action: { selectedGroupType = .school }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(.top, 40)
                    } else if filteredGroups.isEmpty {
                        // Empty state
                        SectionBox(title: "Your Groups") {
                            EmptyStateBox(
                                icon: "person.3",
                                title: "No Groups Yet",
                                message: "Join existing groups or create your own to connect with other parents",
                                buttonTitle: "Create a Group",
                                buttonAction: {
                                    showingCreateGroupSheet = true
                                }
                            )
                        }
                        
                        // Recommended groups
                        SectionBox(
                            title: "Recommended Groups",
                            viewAllAction: {
                                // View all recommended groups
                            }
                        ) {
                            if viewModel.recommendedGroups.isEmpty {
                                Text("No recommended groups yet")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.recommendedGroups) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                EnhancedGroupCard(group: group)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Nearby groups
                        SectionBox(
                            title: "Nearby Groups",
                            viewAllAction: {
                                // View all nearby groups
                            }
                        ) {
                            if viewModel.nearbyGroups.isEmpty {
                                Text("No nearby groups found")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.nearbyGroups) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                EnhancedGroupCard(group: group)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // User's groups
                        SectionBox(
                            title: "Your Groups",
                            viewAllAction: filteredGroups.count > 3 ? {
                                // View all user groups
                            } : nil
                        ) {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredGroups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        EnhancedGroupCard(group: group)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Recommended groups
                        if !viewModel.recommendedGroups.isEmpty {
                            SectionBox(
                                title: "Recommended For You",
                                viewAllAction: {
                                    // View all recommended groups
                                }
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.recommendedGroups) { group in
                                            NavigationLink(destination: GroupDetailView(group: group)) {
                                                CompactGroupCard(group: group)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
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

struct EnhancedGroupCard: View {
    let group: Group
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image and gradient
            ZStack(alignment: .bottomLeading) {
                // Background gradient based on group type
                Rectangle()
                    .fill(groupTypeGradient)
                    .frame(height: 100)
                
                // Group icon
                Image(systemName: groupTypeIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 100, y: -20)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Group type badge
                Text(group.groupType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(groupTypeColor)
                    .cornerRadius(16)
                    .padding(12)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Group info
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text(group.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(2)
                
                Divider()
                
                HStack {
                    // Member count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                        Text("\(group.memberIDs.count) members")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(ColorTheme.lightText)
                    
                    Spacer()
                    
                    // Privacy badge
                    HStack(spacing: 4) {
                        Image(systemName: privacyIcon)
                            .font(.system(size: 14))
                        Text(group.privacyType.rawValue.capitalized)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(ColorTheme.lightText)
                }
            }
            .padding(16)
            .frame(height: 120)
            .background(Color.white)
        }
        .frame(width: 300)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            isAnimating = true
        }
    }
    
    private var groupTypeIcon: String {
        switch group.groupType {
        case .neighborhood:
            return "house.fill"
        case .school:
            return "book.fill"
        case .ageBased:
            return "figure.2.and.child.holdinghands"
        case .interestBased:
            return "star.fill"
        case .other:
            return "person.3.fill"
        }
    }
    
    private var privacyIcon: String {
        switch group.privacyType {
        case .public:
            return "globe"
        case .private:
            return "lock"
        case .inviteOnly:
            return "envelope"
        }
    }
    
    private var groupTypeColor: Color {
        switch group.groupType {
        case .neighborhood:
            return Color.blue
        case .school:
            return Color.purple
        case .ageBased:
            return Color.green
        case .interestBased:
            return Color.orange
        case .other:
            return ColorTheme.primary
        }
    }
    
    private var groupTypeGradient: LinearGradient {
        switch group.groupType {
        case .neighborhood:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .school:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ageBased:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .interestBased:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .other:
            return LinearGradient(
                gradient: Gradient(colors: [ColorTheme.primary.opacity(0.7), ColorTheme.primary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct CompactGroupCard: View {
    let group: Group
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Group icon with background
                ZStack {
                    Circle()
                        .fill(groupTypeGradient)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: groupTypeIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text("\(group.memberIDs.count) members")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
            }
            
            Divider()
            
            Text(group.description)
                .font(.subheadline)
                .foregroundColor(ColorTheme.text)
                .lineLimit(2)
            
            Button(action: {
                // Join group action
            }) {
                Text("Join Group")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(groupTypeColor)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .frame(width: 220, height: 200)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }
    
    private var groupTypeIcon: String {
        switch group.groupType {
        case .neighborhood:
            return "house.fill"
        case .school:
            return "book.fill"
        case .ageBased:
            return "figure.2.and.child.holdinghands"
        case .interestBased:
            return "star.fill"
        case .other:
            return "person.3.fill"
        }
    }
    
    private var groupTypeColor: Color {
        switch group.groupType {
        case .neighborhood:
            return Color.blue
        case .school:
            return Color.purple
        case .ageBased:
            return Color.green
        case .interestBased:
            return Color.orange
        case .other:
            return ColorTheme.primary
        }
    }
    
    private var groupTypeGradient: LinearGradient {
        switch group.groupType {
        case .neighborhood:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .school:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ageBased:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .interestBased:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .other:
            return LinearGradient(
                gradient: Gradient(colors: [ColorTheme.primary.opacity(0.7), ColorTheme.primary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// Placeholder for GroupDetailView
struct GroupDetailView: View {
    let group: Group
    
    var body: some View {
        VStack {
            Text("Group Detail View")
                .font(.title)
            
            Text(group.name)
                .font(.headline)
            
            Text(group.description)
                .font(.body)
                .padding()
        }
        .navigationTitle(group.name)
    }
}

// Placeholder for CreateGroupView
struct CreateGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Create Group Form - Coming Soon")
                .navigationTitle("Create Group")
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}
