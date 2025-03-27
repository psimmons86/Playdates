import SwiftUI
import Combine
import Firebase

struct FriendsView: View {
    @StateObject var viewModel = FriendshipViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var showingFriendRequests = false
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search friends", text: $searchText)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Friend requests button
                if !viewModel.friendRequests.isEmpty {
                    Button(action: {
                        showingFriendRequests = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(ColorTheme.primary)
                            
                            Text("\(viewModel.friendRequests.count) Friend Request\(viewModel.friendRequests.count > 1 ? "s" : "")")
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Friends list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.friends.isEmpty {
                    emptyStateView
                } else {
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing:
                Button(action: {
                    showingAddFriendSheet = true
                }) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                }
            )
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView(isPresented: $showingAddFriendSheet)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingFriendRequests) {
                FriendRequestsView(isPresented: $showingFriendRequests)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if let userId = authViewModel.user?.id {
                    viewModel.fetchFriends(for: userId)
                    viewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add friends to plan playdates together")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddFriendSheet = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Add Friends")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(ColorTheme.primary)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    private var friendsList: some View {
        List {
            ForEach(filteredFriends) { friend in
                FriendRow(friend: friend)
                    .environmentObject(viewModel)
            }
            .listRowBackground(Color.white)
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return viewModel.friends
        } else {
            return viewModel.friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                ProfileImageView(imageURL: friend.profileImageURL, size: 50)
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                
                if let children = friend.children, !children.isEmpty {
                    Text("\(children.count) \(children.count == 1 ? "Child" : "Children")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Action button
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding(.vertical, 8)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Friend Options"),
                buttons: [
                    .default(Text("Message")) {
                        // Open chat with this friend
                    },
                    .default(Text("Invite to Playdate")) {
                        // Invite to playdate
                    },
                    .destructive(Text("Remove Friend")) {
                        if let friendId = friend.id {
                            viewModel.removeFriendship(friendId: friendId)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct AddFriendView: View {
    @EnvironmentObject var viewModel: FriendshipViewModel
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search by name or email", text: $searchText, onCommit: {
                        searchUsers()
                    })
                    .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text("No users found")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(searchResults) { user in
                            UserSearchRow(user: user)
                                .environmentObject(viewModel)
                        }
                        .listRowBackground(Color.white)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        print("DEBUG: Starting search with query: \(searchText)")
        isSearching = true
        errorMessage = nil
        
        // Create a dispatch group to handle multiple queries
        let dispatchGroup = DispatchGroup()
        var allResults: [User] = []
        
        // Search by name (using Firebase's array-contains-any with name parts)
        dispatchGroup.enter()
        searchByName(searchText) { users in
            print("DEBUG: Name search completed with \(users.count) results")
            allResults.append(contentsOf: users)
            dispatchGroup.leave()
        }
        
        // Search by email
        dispatchGroup.enter()
        searchByEmail(searchText) { users in
            print("DEBUG: Email search completed with \(users.count) results")
            allResults.append(contentsOf: users)
            dispatchGroup.leave()
        }
        
        // When all searches are complete
        dispatchGroup.notify(queue: .main) {
            print("DEBUG: All searches complete, total results: \(allResults.count)")
            
            // Remove duplicates
            var uniqueResults: [User] = []
            var seenIds = Set<String>()
            
            for user in allResults {
                if let id = user.id, !seenIds.contains(id) {
                    seenIds.insert(id)
                    uniqueResults.append(user)
                }
            }
            
            print("DEBUG: After removing duplicates: \(uniqueResults.count) results")
            
            // Filter out the current user
            if let currentUserId = self.viewModel.currentUserId {
                print("DEBUG: Current user ID: \(currentUserId)")
                uniqueResults = uniqueResults.filter { $0.id != currentUserId }
                print("DEBUG: After filtering out current user: \(uniqueResults.count) results")
            }
            
            // Also filter out users who are already friends
            let beforeFriendFilter = uniqueResults.count
            uniqueResults = uniqueResults.filter { user in
                guard let userId = user.id else { return true }
                return !self.viewModel.isFriend(userId: userId)
            }
            print("DEBUG: After filtering out friends: \(uniqueResults.count) results (removed \(beforeFriendFilter - uniqueResults.count))")
            
            self.isSearching = false
            self.searchResults = uniqueResults
            
            if uniqueResults.isEmpty {
                print("DEBUG: No users found after filtering")
                self.errorMessage = "No users found matching '\(self.searchText)'"
            } else {
                self.errorMessage = nil
            }
        }
    }
    
    private func searchByName(_ query: String, completion: @escaping ([User]) -> Void) {
        // Create search terms by splitting the query
        let searchTerms = query.lowercased().split(separator: " ").map(String.init)
        
        print("DEBUG: Searching for name with query: \(query)")
        
        // Firebase can't do case-insensitive searches directly, so we'll use a prefix search
        // This works well for names that start with the search term
        viewModel.db.collection("users")
            .whereField("name_lowercase", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("name_lowercase", isLessThan: query.lowercased() + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG ERROR: Error searching by name: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No documents found in name search")
                    completion([])
                    return
                }
                
                print("DEBUG: Found \(documents.count) documents in name search")
                
                // Debug: Print raw document data to check fields
                for (index, document) in documents.enumerated() {
                    print("DEBUG: Document \(index) data: \(document.data())")
                }
                
                let users = documents.compactMap { document -> User? in
                    do {
                        return try document.data(as: User.self)
                    } catch {
                        print("DEBUG ERROR: Failed to decode user from document \(document.documentID): \(error.localizedDescription)")
                        // Try manual parsing as fallback
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let email = data["email"] as? String {
                            print("DEBUG: Manually parsed user: \(name), \(email)")
                            return User(
                                id: document.documentID,
                                name: name,
                                email: email,
                                createdAt: Date(),
                                lastActive: Date()
                            )
                        }
                        return nil
                    }
                }
                
                print("DEBUG: Successfully decoded \(users.count) users from name search")
                completion(users)
            }
    }
    
    private func searchByEmail(_ query: String, completion: @escaping ([User]) -> Void) {
        print("DEBUG: Searching for email with query: \(query)")
        
        viewModel.db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: query.lowercased())
            .whereField("email", isLessThan: query.lowercased() + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("DEBUG ERROR: Error searching by email: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No documents found in email search")
                    completion([])
                    return
                }
                
                print("DEBUG: Found \(documents.count) documents in email search")
                
                // Debug: Print raw document data to check fields
                for (index, document) in documents.enumerated() {
                    print("DEBUG: Document \(index) email data: \(document.data())")
                }
                
                let users = documents.compactMap { document -> User? in
                    do {
                        return try document.data(as: User.self)
                    } catch {
                        print("DEBUG ERROR: Failed to decode user from email document \(document.documentID): \(error.localizedDescription)")
                        // Try manual parsing as fallback
                        let data = document.data()
                        if let name = data["name"] as? String,
                           let email = data["email"] as? String {
                            print("DEBUG: Manually parsed user from email search: \(name), \(email)")
                            return User(
                                id: document.documentID,
                                name: name,
                                email: email,
                                createdAt: Date(),
                                lastActive: Date()
                            )
                        }
                        return nil
                    }
                }
                
                print("DEBUG: Successfully decoded \(users.count) users from email search")
                completion(users)
            }
    }
}

struct UserSearchRow: View {
    let user: User
    @EnvironmentObject var viewModel: FriendshipViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                ProfileImageView(imageURL: user.profileImageURL, size: 50)
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add button
            Button(action: {
                if let userId = user.id, let currentUserId = Auth.auth().currentUser?.uid {
                    viewModel.sendFriendRequest(from: currentUserId, to: userId) { result in
                        switch result {
                        case .success:
                            // Show success indicator or message
                            print("Friend request sent successfully")
                        case .failure(let error):
                            // Show error
                            print("Error sending friend request: \(error.localizedDescription)")
                        }
                    }
                }
            }) {
                // Get the user ID safely
                let userId = user.id ?? ""
                
                if viewModel.isFriendRequestPending(userId: userId) {
                    Text("Sent")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                } else if viewModel.isFriend(userId: userId) {
                    Text("Friend")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                } else {
                    Text("Add")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(ColorTheme.primary)
                        .cornerRadius(16)
                }
            }
            .disabled(isButtonDisabled)
        }
        .padding(.vertical, 8)
    }
    
    private var isButtonDisabled: Bool {
        let userId = user.id ?? ""
        return viewModel.isFriendRequestPending(userId: userId) || viewModel.isFriend(userId: userId)
    }
}

struct FriendRequestsView: View {
    @EnvironmentObject var viewModel: FriendshipViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.friendRequests.isEmpty {
                    Spacer()
                    Text("No friend requests")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.friendRequests) { request in
                            FriendRequestRow(request: request)
                                .environmentObject(viewModel)
                        }
                        .listRowBackground(Color.white)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Friend Requests")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
            .onAppear {
                if let userId = viewModel.currentUserId {
                    viewModel.fetchFriendRequests(for: userId)
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequestModel
    @EnvironmentObject var viewModel: FriendshipViewModel
    @State private var sender: User?
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            if #available(iOS 17.0, *) {
                if let sender = sender {
                    ProfileImageView(imageURL: sender.profileImageURL, size: 50)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            } else {
                // Fallback for older iOS versions
                Circle()
                    .fill(ColorTheme.primary.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                    )
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(sender?.name ?? "Loading...")
                    .font(.headline)
                
                Text("Wants to be friends")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            if !isLoading {
                HStack(spacing: 8) {
                    // Decline button
                    Button(action: {
                        declineFriendRequest()
                    }) {
                        Text("Decline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(16)
                    }
                    
                    // Accept button
                    Button(action: {
                        acceptFriendRequest()
                    }) {
                        Text("Accept")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.primary)
                            .cornerRadius(16)
                    }
                }
            } else {
                ProgressView()
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            fetchSender()
        }
    }
    
    private func fetchSender() {
        // Check if senderID is not empty
        guard !request.senderID.isEmpty else { return }
        
        // Fetch the actual user data from Firebase
        viewModel.db.collection("users").document(request.senderID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching sender: \(error.localizedDescription)")
                return
            }
            
            guard let document = snapshot, document.exists else {
                print("Sender document not found")
                return
            }
            
            // Try to decode the user
            if let user = try? document.data(as: User.self) {
                DispatchQueue.main.async {
                    self.sender = user
                }
            } else {
                // Manual parsing if decoding fails
                if let data = document.data() {
                    let name = data["name"] as? String ?? "Unknown User"
                    let email = data["email"] as? String ?? "unknown@example.com"
                    let profileImageURL = data["profileImageURL"] as? String
                    
                    // Create a User object without directly setting the @DocumentID property
                    var user = User(
                        id: nil,  // Don't set the ID directly to avoid Firestore warning
                        name: name,
                        email: email,
                        profileImageURL: profileImageURL,
                        createdAt: Date(),
                        lastActive: Date()
                    )
                    // Store the ID separately since we need it for display purposes
                    // but don't want to trigger the @DocumentID warning
                    user.id = request.senderID
                    
                    DispatchQueue.main.async {
                        self.sender = user
                    }
                }
            }
        }
    }
    
    private func acceptFriendRequest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let requestId = request.id {
                viewModel.acceptFriendRequest(requestId: requestId) { success in
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    private func declineFriendRequest() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let requestId = request.id {
                viewModel.declineFriendRequest(requestId: requestId) { success in
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
}

// Add this extension to the FriendshipViewModel to support the interface
extension FriendshipViewModel {
    // Friend status checks
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.id == userId }
    }
    
    func isFriendRequestPending(userId: String) -> Bool {
        return friendRequests.contains { 
            $0.senderID == userId || $0.receiverID == userId
        }
    }
    
    // Friend request actions
    func acceptFriendRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Get the request document
        db.collection("friendRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting friend request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let senderID = data["senderID"] as? String,
                  let receiverID = data["receiverID"] as? String else {
                print("Friend request not found or invalid")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            // Create a FriendRequestModel to pass to respondToFriendRequest
            let request = FriendRequestModel(
                id: requestId,
                senderID: senderID,
                receiverID: receiverID,
                status: .pending
            )
            
            // Use the existing method to accept the request
            self.respondToFriendRequest(request: request, accept: true) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        // Refresh the friend requests list
                        if let currentUserId = self.currentUserId {
                            self.fetchFriendRequests(for: currentUserId)
                            self.fetchFriends(for: currentUserId)
                        }
                        completion(true)
                    case .failure(let error):
                        print("Error accepting friend request: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
        }
    }
    
    func declineFriendRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Get the request document
        db.collection("friendRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting friend request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let senderID = data["senderID"] as? String,
                  let receiverID = data["receiverID"] as? String else {
                print("Friend request not found or invalid")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false)
                }
                return
            }
            
            // Create a FriendRequestModel to pass to respondToFriendRequest
            let request = FriendRequestModel(
                id: requestId,
                senderID: senderID,
                receiverID: receiverID,
                status: .pending
            )
            
            // Use the existing method to decline the request
            self.respondToFriendRequest(request: request, accept: false) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success:
                        // Refresh the friend requests list
                        if let currentUserId = self.currentUserId {
                            self.fetchFriendRequests(for: currentUserId)
                        }
                        completion(true)
                    case .failure(let error):
                        print("Error declining friend request: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
        }
    }
    
    func removeFriendship(friendId: String) {
        guard let currentUserId = currentUserId else { return }
        isLoading = true
        
        // Find the friendship document
        db.collection("friendships")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding friendship: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                // Find the friendship document that contains both users
                let friendshipDoc = snapshot?.documents.first { document in
                    if let participants = document.data()["participants"] as? [String] {
                        return participants.contains(friendId)
                    }
                    return false
                }
                
                if let friendshipDoc = friendshipDoc {
                    // Delete the friendship
                    friendshipDoc.reference.delete { error in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            
                            if let error = error {
                                print("Error removing friendship: \(error.localizedDescription)")
                                return
                            }
                            
                            // Remove the friend from the local list
                            self.friends.removeAll { $0.id == friendId }
                        }
                    }
                } else {
                    self.isLoading = false
                    print("Friendship not found")
                }
            }
    }
}
