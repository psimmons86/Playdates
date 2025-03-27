import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class ResourceViewModel: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = ResourceViewModel()
    
    // Published properties for UI updates
    @Published var availableResources: [SharedResource] = []
    @Published var userResources: [SharedResource] = []
    @Published var nearbyResources: [SharedResource] = []
    @Published var selectedResource: SharedResource?
    @Published var filteredResources: [SharedResource] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        // Load mock data for development
        #if DEBUG
        addMockData()
        #endif
    }
    
    // Filter state
    @Published var selectedResourceTypes: [ResourceType] = []
    @Published var showFreeOnly: Bool = false
    @Published var showAvailableOnly: Bool = true
    @Published var searchQuery: String = ""
    
    // Firestore references
    private let db = Firestore.firestore()
    private var resourcesRef: CollectionReference {
        return db.collection("shared_resources")
    }
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Resource Operations
    
    /// Fetch available resources
    func fetchAvailableResources() {
        isLoading = true
        errorMessage = nil
        
        resourcesRef.whereField("availabilityStatus", isEqualTo: ResourceAvailabilityStatus.available.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch resources: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.availableResources = []
                    return
                }
                
                self.availableResources = documents.compactMap { document -> SharedResource? in
                    try? document.data(as: SharedResource.self)
                }
                
                // Apply any active filters
                self.applyFilters()
            }
    }
    
    /// Fetch resources owned by the user
    func fetchUserResources(userID: String) {
        isLoading = true
        errorMessage = nil
        
        resourcesRef.whereField("ownerID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch user resources: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.userResources = []
                    return
                }
                
                self.userResources = documents.compactMap { document -> SharedResource? in
                    try? document.data(as: SharedResource.self)
                }
            }
    }
    
    /// Fetch resources based on location proximity
    func fetchNearbyResources(location: Location, radiusInKm: Double = 10.0) {
        isLoading = true
        errorMessage = nil
        
        // In a real implementation, this would use geoqueries
        // For now, we'll simulate by fetching available resources
        resourcesRef.whereField("availabilityStatus", isEqualTo: ResourceAvailabilityStatus.available.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to fetch nearby resources: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.nearbyResources = []
                    return
                }
                
                let resources = documents.compactMap { document -> SharedResource? in
                    try? document.data(as: SharedResource.self)
                }
                
                // In a real implementation, we would filter by distance here
                // For now, we'll just return all results
                self.nearbyResources = resources
            }
    }
    
    /// Create a new resource
    func createResource(resource: SharedResource, completion: @escaping (Result<SharedResource, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            let docRef = resourcesRef.document()
            var newResource = resource
            newResource.id = docRef.documentID
            
            try docRef.setData(from: newResource) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to create resource: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Add to appropriate arrays
                if newResource.isAvailable {
                    self.availableResources.insert(newResource, at: 0)
                }
                
                self.userResources.insert(newResource, at: 0)
                
                // Apply filters to update filtered resources
                self.applyFilters()
                
                completion(.success(newResource))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode resource: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Update an existing resource
    func updateResource(resource: SharedResource, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let id = resource.id else {
            completion(.failure(NSError(domain: "ResourceViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Resource ID is missing"])))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try resourcesRef.document(id).setData(from: resource) { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to update resource: \(error.localizedDescription)"
                    completion(.failure(error))
                    return
                }
                
                // Update in local arrays
                if let index = self.availableResources.firstIndex(where: { $0.id == id }) {
                    if resource.isAvailable {
                        self.availableResources[index] = resource
                    } else {
                        self.availableResources.remove(at: index)
                    }
                } else if resource.isAvailable {
                    self.availableResources.append(resource)
                    self.availableResources.sort { $0.createdAt > $1.createdAt }
                }
                
                if let index = self.userResources.firstIndex(where: { $0.id == id }) {
                    self.userResources[index] = resource
                }
                
                if let index = self.nearbyResources.firstIndex(where: { $0.id == id }) {
                    if resource.isAvailable {
                        self.nearbyResources[index] = resource
                    } else {
                        self.nearbyResources.remove(at: index)
                    }
                }
                
                if self.selectedResource?.id == id {
                    self.selectedResource = resource
                }
                
                // Apply filters to update filtered resources
                self.applyFilters()
                
                completion(.success(()))
            }
        } catch {
            isLoading = false
            errorMessage = "Failed to encode resource: \(error.localizedDescription)"
            completion(.failure(error))
        }
    }
    
    /// Reserve a resource
    func reserveResource(resourceID: String, reservation: ResourceReservation, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let resourceRef = resourcesRef.document(resourceID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let resourceDocument: DocumentSnapshot
            do {
                try resourceDocument = transaction.getDocument(resourceRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var resource = try? resourceDocument.data(as: SharedResource.self) else {
                let error = NSError(domain: "ResourceViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode resource"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Check if resource is available
            if resource.availabilityStatus != .available {
                let error = NSError(domain: "ResourceViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Resource is not available"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Add reservation to history
            if resource.reservationHistory == nil {
                resource.reservationHistory = [reservation]
            } else {
                resource.reservationHistory?.append(reservation)
            }
            
            // Update status to reserved
            resource.availabilityStatus = .reserved
            
            // Update the resource
            do {
                try transaction.setData(from: resource, forDocument: resourceRef)
                return resource
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to reserve resource: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedResource = result as? SharedResource {
                // Update local arrays
                if let index = self.availableResources.firstIndex(where: { $0.id == resourceID }) {
                    self.availableResources.remove(at: index)
                }
                
                if let index = self.nearbyResources.firstIndex(where: { $0.id == resourceID }) {
                    self.nearbyResources.remove(at: index)
                }
                
                if let index = self.userResources.firstIndex(where: { $0.id == resourceID }) {
                    self.userResources[index] = updatedResource
                }
                
                if self.selectedResource?.id == resourceID {
                    self.selectedResource = updatedResource
                }
                
                // Apply filters to update filtered resources
                self.applyFilters()
                
                completion(.success(()))
            } else {
                completion(.success(()))  // No changes needed
            }
        }
    }
    
    /// Add a review to a resource
    func addReview(resourceID: String, review: ResourceReview, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let resourceRef = resourcesRef.document(resourceID)
        
        db.runTransaction({ [weak self] (transaction, errorPointer) -> Any? in
            guard let self = self else { return nil }
            
            let resourceDocument: DocumentSnapshot
            do {
                try resourceDocument = transaction.getDocument(resourceRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var resource = try? resourceDocument.data(as: SharedResource.self) else {
                let error = NSError(domain: "ResourceViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode resource"])
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            // Add review
            if resource.reviews == nil {
                resource.reviews = [review]
            } else {
                // Check if user already left a review and update it
                if let index = resource.reviews?.firstIndex(where: { $0.userID == review.userID }) {
                    resource.reviews?[index] = review
                } else {
                    resource.reviews?.append(review)
                }
            }
            
            // Update average rating
            let totalRating = resource.reviews?.reduce(0.0) { $0 + $1.rating } ?? 0.0
            let count = Double(resource.reviews?.count ?? 0)
            resource.rating = count > 0 ? totalRating / count : nil
            
            // Update the resource
            do {
                try transaction.setData(from: resource, forDocument: resourceRef)
                return resource
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }) { [weak self] (result, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to add review: \(error.localizedDescription)"
                completion(.failure(error))
                return
            }
            
            if let updatedResource = result as? SharedResource {
                // Update local arrays
                if let index = self.availableResources.firstIndex(where: { $0.id == resourceID }) {
                    self.availableResources[index] = updatedResource
                }
                
                if let index = self.nearbyResources.firstIndex(where: { $0.id == resourceID }) {
                    self.nearbyResources[index] = updatedResource
                }
                
                if let index = self.userResources.firstIndex(where: { $0.id == resourceID }) {
                    self.userResources[index] = updatedResource
                }
                
                if self.selectedResource?.id == resourceID {
                    self.selectedResource = updatedResource
                }
                
                completion(.success(()))
            } else {
                completion(.success(()))  // No changes needed
            }
        }
    }
    
    // MARK: - Filtering and Searching
    
    /// Apply all current filters to the resources
    func applyFilters() {
        var filtered = availableResources
        
        // Filter by resource types if any are selected
        if !selectedResourceTypes.isEmpty {
            filtered = filtered.filter { resource in
                selectedResourceTypes.contains(resource.resourceType)
            }
        }
        
        // Filter by free only
        if showFreeOnly {
            filtered = filtered.filter { $0.isFree }
        }
        
        // Filter by available only
        if showAvailableOnly {
            filtered = filtered.filter { $0.isAvailable }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { resource in
                resource.title.lowercased().contains(query) ||
                resource.description.lowercased().contains(query) ||
                resource.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        // Sort by creation date (newest first)
        filtered.sort { $0.createdAt > $1.createdAt }
        
        filteredResources = filtered
    }
    
    /// Set resource type filter
    func setResourceTypes(_ types: [ResourceType]) {
        selectedResourceTypes = types
        applyFilters()
    }
    
    /// Toggle free only filter
    func toggleFreeOnly() {
        showFreeOnly.toggle()
        applyFilters()
    }
    
    /// Toggle available only filter
    func toggleAvailableOnly() {
        showAvailableOnly.toggle()
        applyFilters()
    }
    
    /// Set search query
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applyFilters()
    }
    
    /// Reset all filters
    func resetFilters() {
        selectedResourceTypes = []
        showFreeOnly = false
        showAvailableOnly = true
        searchQuery = ""
        applyFilters()
    }
}
