import SwiftUI

// New struct for the empty state view
struct WishlistEmptyStateView: View {
    var body: some View {
        VStack {
            Image(systemName: "bookmark.slash")
                .resizable() // Correct: Apply to Image
                .scaledToFit()
                .frame(width: 60, height: 60) // Correct: Apply frame after sizing
                .foregroundColor(Color.secondary) // Correct: Use Color.secondary
            Text("Your Wishlist is Empty")
                .font(.title2)
                .foregroundColor(Color.secondary) // Correct: Use Color.secondary
            Text("Add activities you want to try by tapping the bookmark icon.")
                .font(.callout)
                .foregroundColor(Color.secondary) // Correct: Use Color.secondary
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        } // End of VStack
        .padding() // Apply padding to the VStack
    }
}

struct WishlistView: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    // Add other necessary EnvironmentObjects if needed for navigation/actions

    // Use @ViewBuilder to create the conditional content
    @ViewBuilder
    private var contentView: some View {
        // Restore conditional logic
        if activityViewModel.isLoadingWishlist {
            ProgressView { Text("Loading Wishlist...") } // Use explicit label
        } else if activityViewModel.wishlistActivities.isEmpty {
            // Use the extracted empty state view
            WishlistEmptyStateView()
        } else {
            List {
                ForEach(activityViewModel.wishlistActivities) { activity in
                            // TODO: Make this row navigable to ExploreActivityDetailView
                            WishlistRow(activity: activity)
                                .environmentObject(activityViewModel) // Pass down if needed by row actions
                        }
                        .onDelete(perform: removeItems) // Optional: Allow swipe to delete
                    // Removed redundant listStyle here
            }
            .listStyle(PlainListStyle()) // Keep the outer listStyle
            // Optional: Add toolbar items if needed (e.g., Edit button)
        } // End of else
    }

    var body: some View {
        NavigationView {
            contentView // Use the computed property
                .navigationTitle("Want to Do") // Apply title here
        }
        .onAppear {
            // The listener in ActivityViewModel should already be fetching.
            // We might not need an explicit fetch here unless the listener isn't active yet.
            // Consider adding if issues persist:
            // if activityViewModel.wishlistActivities.isEmpty && !activityViewModel.wantToDoActivityIDs.isEmpty {
            //     activityViewModel.fetchWishlistActivities()
            // }
        }
    }

    // Helper function for swipe-to-delete (optional)
    private func removeItems(at offsets: IndexSet) {
        // Get the activities to remove based on the offsets
        let activitiesToRemove = offsets.map { activityViewModel.wishlistActivities[$0] }

        // Call the toggle function for each activity to remove it from Firestore
        Task {
            for activity in activitiesToRemove {
                await activityViewModel.toggleWantToDo(activity: activity)
            }
        }
        // Note: The UI will update automatically when the listener detects the change in wantToDoActivityIDs
        // and subsequently updates wishlistActivities. Direct removal from the array here
        // might cause temporary inconsistencies if the Firestore update fails.
        // The optimistic update within toggleWantToDo handles the immediate UI change.
    }
}

// Simple row view for the list
struct WishlistRow: View {
    @EnvironmentObject var activityViewModel: ActivityViewModel
    let activity: Activity

    var body: some View {
        HStack {
            // Basic Activity Info (Customize as needed)
            VStack(alignment: .leading) {
                Text(activity.name).font(.headline)
                Text(activity.type.title).font(.subheadline).foregroundColor(.gray)
                // Corrected check: address is non-optional, just check if empty
                if !activity.location.address.isEmpty {
                    Text(activity.location.address).font(.caption).foregroundColor(.gray)
                }
            }
            Spacer()
            // Bookmark button to remove from wishlist
            Button {
                Task {
                    await activityViewModel.toggleWantToDo(activity: activity)
                }
            } label: {
                Image(systemName: activityViewModel.isWantToDo(activity: activity) ? "bookmark.fill" : "bookmark")
                    .foregroundColor(activityViewModel.isWantToDo(activity: activity) ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle()) // Prevent the whole row from being tappable if inside NavigationLink
        }
        .padding(.vertical, 4)
    }
}

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data for preview
        let mockViewModel = ActivityViewModel.shared // Use shared for simplicity, or create a new mock instance
        let sampleLocation = Location(name: "Preview Park", address: "123 Preview St", latitude: 37.7749, longitude: -122.4194)
        mockViewModel.wishlistActivities = [
            Activity(id: "preview1", name: "Fun Park Visit", type: .park, location: sampleLocation),
            Activity(id: "preview2", name: "Museum Day", type: .museum, location: sampleLocation)
        ]
        mockViewModel.wantToDoActivityIDs = ["preview1", "preview2"]
        mockViewModel.isLoadingWishlist = false

        return WishlistView()
            .environmentObject(mockViewModel)
    }
}
