import SwiftUI

struct ResourceSharingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ResourceViewModel.shared
    @State private var showingCreateResourceSheet = false
    @State private var showingFilterSheet = false
    @State private var searchText = ""
    @State private var selectedResourceType: ResourceType?
    
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
                            
                            TextField("Search resources", text: $searchText)
                                .foregroundColor(ColorTheme.text)
                                .onChange(of: searchText) { newValue in
                                    viewModel.setSearchQuery(newValue)
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    viewModel.setSearchQuery("")
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ColorTheme.lightText)
                                }
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
                            Button(action: {
                                showingFilterSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filter")
                                }
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.primary)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Resource type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                CategoryButton(
                                    title: "All",
                                    isSelected: selectedResourceType == nil,
                                    action: { selectedResourceType = nil }
                                )
                                
                                CategoryButton(
                                    title: "Items",
                                    isSelected: selectedResourceType == .physicalItem,
                                    action: { selectedResourceType = .physicalItem }
                                )
                                
                                CategoryButton(
                                    title: "Recs",
                                    isSelected: selectedResourceType == .recommendation,
                                    action: { selectedResourceType = .recommendation }
                                )
                                
                                CategoryButton(
                                    title: "Educational",
                                    isSelected: selectedResourceType == .educationalResource,
                                    action: { selectedResourceType = .educationalResource }
                                )
                                
                                CategoryButton(
                                    title: "Services",
                                    isSelected: selectedResourceType == .serviceProvider,
                                    action: { selectedResourceType = .serviceProvider }
                                )
                                
                                CategoryButton(
                                    title: "Carpool",
                                    isSelected: selectedResourceType == .carpoolOffer,
                                    action: { selectedResourceType = .carpoolOffer }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Quick filter buttons
                    HStack(spacing: 12) {
                        FilterPillButton(
                            title: "Free Only",
                            isActive: viewModel.showFreeOnly,
                            icon: "tag.fill",
                            action: {
                                viewModel.toggleFreeOnly()
                            }
                        )
                        
                        FilterPillButton(
                            title: "Available Only",
                            isActive: viewModel.showAvailableOnly,
                            icon: "checkmark.circle.fill",
                            action: {
                                viewModel.toggleAvailableOnly()
                            }
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(.top, 40)
                    } else if viewModel.filteredResources.isEmpty {
                        // Empty state
                        SectionBox(title: "Resources") {
                            EmptyStateBox(
                                icon: "cube.box",
                                title: "No Resources Yet",
                                message: "Share items, recommendations, or services with other parents in your community",
                                buttonTitle: "Share a Resource",
                                buttonAction: {
                                    showingCreateResourceSheet = true
                                }
                            )
                        }
                        
                        // Options to browse
                        SectionBox(
                            title: "Browse Resources",
                            viewAllAction: nil
                        ) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ResourceTypeCard(
                                    title: "Items to Borrow",
                                    icon: "backpack.fill",
                                    color: .blue,
                                    description: "Kids gear, toys, books and more",
                                    action: {
                                        selectedResourceType = .physicalItem
                                    }
                                )
                                
                                ResourceTypeCard(
                                    title: "Recommendations",
                                    icon: "star.fill", 
                                    color: .orange,
                                    description: "Places, services and activities",
                                    action: {
                                        selectedResourceType = .recommendation
                                    }
                                )
                                
                                ResourceTypeCard(
                                    title: "Educational",
                                    icon: "book.fill", 
                                    color: .purple,
                                    description: "Learning resources and materials",
                                    action: {
                                        selectedResourceType = .educationalResource
                                    }
                                )
                                
                                ResourceTypeCard(
                                    title: "Services",
                                    icon: "person.fill.checkmark", 
                                    color: ColorTheme.primary,
                                    description: "Babysitters, tutors, and more",
                                    action: {
                                        selectedResourceType = .serviceProvider
                                    }
                                )
                            }
                        }
                    } else {
                        // Your resources
                        if !viewModel.userResources.isEmpty {
                            SectionBox(
                                title: "Your Resources",
                                viewAllAction: viewModel.userResources.count > 2 ? {
                                    // View all user resources
                                } : nil
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.userResources) { resource in
                                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                                EnhancedResourceCard(resource: resource)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Available resources
                        SectionBox(
                            title: "Resources Available",
                            viewAllAction: viewModel.filteredResources.count > 5 ? {
                                // View all resources
                            } : nil
                        ) {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredResources.prefix(5)) { resource in
                                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                        CompactResourceCard(resource: resource)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Free resources highlight
                        if viewModel.filteredResources.contains(where: { $0.isFree }) {
                            SectionBox(
                                title: "Free Resources",
                                viewAllAction: {
                                    viewModel.toggleFreeOnly()
                                }
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.filteredResources.filter { $0.isFree }.prefix(5)) { resource in
                                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                                EnhancedResourceCard(resource: resource)
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
            showingCreateResourceSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary)
        })
        .sheet(isPresented: $showingCreateResourceSheet) {
            CreateResourceView()
        }
        .sheet(isPresented: $showingFilterSheet) {
            ResourceFilterView()
        }
        .onAppear {
            viewModel.fetchAvailableResources()
            
            if let userID = authViewModel.currentUser?.id {
                viewModel.fetchUserResources(userID: userID)
            }
        }
        .onChange(of: selectedResourceType) { newValue in
            if let type = newValue {
                viewModel.setResourceTypes([type])
            } else {
                viewModel.setResourceTypes([])
            }
        }
    }
}

struct FilterPillButton: View {
    let title: String
    let isActive: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? ColorTheme.primary : Color.white)
            .foregroundColor(isActive ? .white : ColorTheme.text)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color.clear : ColorTheme.lightText.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct EnhancedResourceCard: View {
    let resource: SharedResource
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image and gradient
            ZStack(alignment: .bottomLeading) {
                // Background gradient based on resource type
                Rectangle()
                    .fill(resourceTypeGradient)
                    .frame(height: 100)
                
                // Resource type icon
                Image(systemName: resource.resourceType.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 100, y: -20)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Resource price and type
                HStack {
                    if resource.isFree {
                        Text("FREE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    } else if let price = resource.price {
                        HStack(spacing: 4) {
                            Text("$\(String(format: "%.2f", price))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if resource.isNegotiable {
                                Text("OBO")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(resource.resourceType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(12)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Resource info
            VStack(alignment: .leading, spacing: 10) {
                Text(resource.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                    .lineLimit(1)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(2)
                
                HStack {
                    // Location if available
                    if let location = resource.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text(location.name)
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(resource.availabilityStatus == .available ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(resource.availabilityStatus.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .frame(width: 250, height: 220)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            isAnimating = true
        }
    }
    
    private var resourceTypeGradient: LinearGradient {
        switch resource.resourceType {
        case .physicalItem:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .recommendation:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .educationalResource:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .classifiedAd:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .carpoolOffer:
            return LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.7), Color.red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .serviceProvider:
            return LinearGradient(
                gradient: Gradient(colors: [ColorTheme.primary.opacity(0.7), ColorTheme.primary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .other:
            return LinearGradient(
                gradient: Gradient(colors: [ColorTheme.lightText.opacity(0.7), ColorTheme.lightText]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct CompactResourceCard: View {
    let resource: SharedResource
    
    var body: some View {
        HStack(spacing: 16) {
            // Resource icon with type background
            ZStack {
                Circle()
                    .fill(resourceTypeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: resource.resourceType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(resourceTypeColor)
            }
            
            // Resource details
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                    .lineLimit(1)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(1)
                
                HStack {
                    // Price
                    if resource.isFree {
                        Text("Free")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else if let price = resource.price {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.text)
                    }
                    
                    Spacer()
                    
                    // Location if available
                    if let location = resource.location {
                        Text(location.name)
                            .font(.caption)
                            .foregroundColor(ColorTheme.lightText)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Availability indicator
            Circle()
                .fill(resource.isAvailable ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var resourceTypeColor: Color {
        switch resource.resourceType {
        case .physicalItem:
            return Color.blue
        case .recommendation:
            return Color.orange
        case .educationalResource:
            return Color.purple
        case .classifiedAd:
            return Color.green
        case .carpoolOffer:
            return Color.red
        case .serviceProvider:
            return ColorTheme.primary
        case .other:
            return ColorTheme.lightText
        }
    }
}

struct ResourceTypeCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [color.opacity(0.7), color]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                
                // Text
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding()
            .frame(height: 150)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extension to add icon and displayName properties to ResourceType
extension ResourceType {
    var icon: String {
        switch self {
        case .physicalItem:
            return "backpack.fill"
        case .recommendation:
            return "star.fill"
        case .educationalResource:
            return "book.fill"
        case .classifiedAd:
            return "tag.fill"
        case .carpoolOffer:
            return "car.fill"
        case .serviceProvider:
            return "person.fill.checkmark"
        case .other:
            return "square.grid.2x2.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .physicalItem:
            return "Item"
        case .recommendation:
            return "Recommendation"
        case .educationalResource:
            return "Educational"
        case .classifiedAd:
            return "For Sale"
        case .carpoolOffer:
            return "Carpool"
        case .serviceProvider:
            return "Service"
        case .other:
            return "Other"
        }
    }
}

// Placeholder for filter view
struct ResourceFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ResourceViewModel.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Resource Types")) {
                    ForEach(ResourceType.allCases, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { viewModel.selectedResourceTypes.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    if !viewModel.selectedResourceTypes.contains(type) {
                                        viewModel.selectedResourceTypes.append(type)
                                    }
                                } else {
                                    viewModel.selectedResourceTypes.removeAll { $0 == type }
                                }
                                viewModel.applyFilters()
                            }
                        )) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(viewModel.selectedResourceTypes.contains(type) ? ColorTheme.primary : ColorTheme.lightText)
                                
                                Text(type.displayName)
                            }
                        }
                    }
                }
                
                Section(header: Text("Price")) {
                    Toggle("Free Items Only", isOn: Binding(
                        get: { viewModel.showFreeOnly },
                        set: { newValue in
                            viewModel.showFreeOnly = newValue
                            viewModel.applyFilters()
                        }
                    ))
                }
                
                Section(header: Text("Availability")) {
                    Toggle("Available Items Only", isOn: Binding(
                        get: { viewModel.showAvailableOnly },
                        set: { newValue in
                            viewModel.showAvailableOnly = newValue
                            viewModel.applyFilters()
                        }
                    ))
                }
                
                Section {
                    Button(action: {
                        viewModel.resetFilters()
                    }) {
                        Text("Reset Filters")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Filter Resources")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// Placeholder for create resource view
struct CreateResourceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Create Resource Form - Coming Soon")
                .navigationTitle("Share a Resource")
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

// Placeholder for resource detail view
struct ResourceDetailView: View {
    let resource: SharedResource
    
    var body: some View {
        Text("Resource Detail View for \(resource.title)")
            .navigationTitle(resource.title)
    }
}
