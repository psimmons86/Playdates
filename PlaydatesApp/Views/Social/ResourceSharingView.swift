import SwiftUI

struct ResourceSharingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ResourceViewModel.shared
    @State private var showingCreateResourceSheet = false
    @State private var searchText = ""
    @State private var selectedResourceType: ResourceType?
    @State private var showingFilterSheet = false
    
    // Simplified filtered resources computed property
    private var filteredResources: [SharedResource] {
        viewModel.filteredResources
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
                        }
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Resource type filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ResourceTypeFilterButton(
                                    type: nil,
                                    selectedType: $selectedResourceType,
                                    label: "All"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .physicalItem,
                                    selectedType: $selectedResourceType,
                                    label: "Items"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .recommendation,
                                    selectedType: $selectedResourceType,
                                    label: "Recommendations"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .educationalResource,
                                    selectedType: $selectedResourceType,
                                    label: "Educational"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .classifiedAd,
                                    selectedType: $selectedResourceType,
                                    label: "Classifieds"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .carpoolOffer,
                                    selectedType: $selectedResourceType,
                                    label: "Carpools"
                                )
                                
                                ResourceTypeFilterButton(
                                    type: .serviceProvider,
                                    selectedType: $selectedResourceType,
                                    label: "Services"
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
                    } else if filteredResources.isEmpty {
                        Spacer()
                        EmptyResourcesView(showingCreateResourceSheet: $showingCreateResourceSheet)
                        Spacer()
                    } else {
                        // Resources list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredResources) { resource in
                                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                        ResourceCard(resource: resource)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Resource Sharing")
            .navigationBarItems(
                leading: Button(action: {
                    showingFilterSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorTheme.primary)
                },
                trailing: Button(action: {
                    showingCreateResourceSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorTheme.primary)
                }
            )
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

struct ResourceTypeFilterButton: View {
    let type: ResourceType?
    @Binding var selectedType: ResourceType?
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

struct ResourceCard: View {
    let resource: SharedResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Resource header with image
            ZStack(alignment: .bottomLeading) {
                if let imageURL = resource.coverImageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(ColorTheme.background)
                                .aspectRatio(2.5, contentMode: .fit)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(2.5, contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(ColorTheme.background)
                                .aspectRatio(2.5, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(ColorTheme.lightText)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(ColorTheme.background)
                                .aspectRatio(2.5, contentMode: .fit)
                        }
                    }
                } else {
                    // Default background for resources without images
                    Rectangle()
                        .fill(resourceTypeGradient)
                        .aspectRatio(2.5, contentMode: .fit)
                        .overlay(
                            Image(systemName: resource.resourceType.icon)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .offset(y: -10)
                        )
                }
                
                // Resource type badge
                Text(resource.resourceType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(resourceTypeColor)
                    .cornerRadius(16)
                    .padding(12)
            }
            .cornerRadius(12)
            
            // Resource info
            VStack(alignment: .leading, spacing: 8) {
                Text(resource.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.text)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .lineLimit(2)
                
                HStack {
                    // Price or free
                    if resource.isFree {
                        Text("Free")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    } else if let price = resource.price {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ColorTheme.text)
                        
                        if resource.isNegotiable {
                            Text("(Negotiable)")
                                .font(.system(size: 12))
                                .foregroundColor(ColorTheme.lightText)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(resource.availabilityStatus == .available ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(resource.availabilityStatus.rawValue.capitalized)
                            .font(.system(size: 12))
                            .foregroundColor(ColorTheme.lightText)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var resourceTypeColor: Color {
        switch resource.resourceType {
        case .physicalItem:
            return .blue
        case .recommendation:
            return .orange
        case .educationalResource:
            return .purple
        case .classifiedAd:
            return .green
        case .carpoolOffer:
            return .red
        case .serviceProvider:
            return ColorTheme.primary
        case .other:
            return ColorTheme.lightText
        }
    }
    
    private var resourceTypeGradient: LinearGradient {
        switch resource.resourceType {
        case .physicalItem:
            return LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.7), .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .recommendation:
            return LinearGradient(
                gradient: Gradient(colors: [.orange.opacity(0.7), .orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .educationalResource:
            return LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.7), .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .classifiedAd:
            return LinearGradient(
                gradient: Gradient(colors: [.green.opacity(0.7), .green]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .carpoolOffer:
            return LinearGradient(
                gradient: Gradient(colors: [.red.opacity(0.7), .red]),
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

struct EmptyResourcesView: View {
    @Binding var showingCreateResourceSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cube.box")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.lightText)
            
            Text("No Resources Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text("Share items, recommendations, or services with other parents in your community")
                .font(.body)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingCreateResourceSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Share a Resource")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Navigate to browse resources
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Browse Resources")
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

struct ResourceFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ResourceViewModel.shared
    
    @State private var selectedResourceTypes: [ResourceType] = []
    @State private var showFreeOnly: Bool = false
    @State private var showAvailableOnly: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Resource Types")) {
                    ForEach(ResourceType.allCases, id: \.self) { type in
                        Button(action: {
                            if selectedResourceTypes.contains(type) {
                                selectedResourceTypes.removeAll { $0 == type }
                            } else {
                                selectedResourceTypes.append(type)
                            }
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(selectedResourceTypes.contains(type) ? ColorTheme.primary : ColorTheme.lightText)
                                
                                Text(type.displayName)
                                    .foregroundColor(ColorTheme.text)
                                
                                Spacer()
                                
                                if selectedResourceTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ColorTheme.primary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Price")) {
                    Toggle("Free Items Only", isOn: $showFreeOnly)
                }
                
                Section(header: Text("Availability")) {
                    Toggle("Available Items Only", isOn: $showAvailableOnly)
                }
                
                Section {
                    Button(action: applyFilters) {
                        Text("Apply Filters")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: resetFilters) {
                        Text("Reset Filters")
                            .foregroundColor(ColorTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ColorTheme.primary, lineWidth: 1)
                            )
                    }
                }
            }
            .navigationTitle("Filter Resources")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Initialize with current filter values
                selectedResourceTypes = viewModel.selectedResourceTypes
                showFreeOnly = viewModel.showFreeOnly
                showAvailableOnly = viewModel.showAvailableOnly
            }
        }
    }
    
    private func applyFilters() {
        // Apply resource type filters
        viewModel.setResourceTypes(selectedResourceTypes)
        
        // Apply free only filter if changed
        if viewModel.showFreeOnly != showFreeOnly {
            viewModel.toggleFreeOnly()
        }
        
        // Apply available only filter if changed
        if viewModel.showAvailableOnly != showAvailableOnly {
            viewModel.toggleAvailableOnly()
        }
        
        // Dismiss the filter sheet
        presentationMode.wrappedValue.dismiss()
    }
    
    private func resetFilters() {
        selectedResourceTypes = []
        showFreeOnly = false
        showAvailableOnly = true
        
        viewModel.resetFilters()
    }
}

// Placeholder for the create resource view
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

// Placeholder for the resource detail view
struct ResourceDetailView: View {
    let resource: SharedResource
    
    var body: some View {
        Text("Resource Detail View for \(resource.title)")
            .navigationTitle(resource.title)
    }
}

struct ResourceSharingView_Previews: PreviewProvider {
    static var previews: some View {
        ResourceSharingView()
            .environmentObject(AuthViewModel())
    }
}
