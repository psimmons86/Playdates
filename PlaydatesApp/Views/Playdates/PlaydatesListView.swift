import SwiftUI

// View to display a list of all playdates
struct PlaydatesListView: View {
     @StateObject private var playdateViewModel = PlaydateViewModel() // Or use shared instance if appropriate

     var body: some View {
         List {
             // Filter out playdates with nil IDs before iterating
             ForEach(playdateViewModel.playdates.filter { $0.id != nil }) { playdate in
                 // Corrected initializer to pass playdateId (String) instead of the whole Playdate object
                 // Force unwrap playdate.id! is safe here due to the filter above.
                 NavigationLink(destination: PlaydateDetailView(playdateId: playdate.id!)) {
                     VStack(alignment: .leading) {
                         Text(playdate.title).font(.headline)
                         Text(playdate.startDate, style: .date) + Text(" at ") + Text(playdate.startDate, style: .time)
                         Text(playdate.location?.name ?? "No location").font(.caption).foregroundColor(.lightTextColor) // Use theme color
                     }
                 }
             }
         }
         .navigationTitle("All Playdates")
         .onAppear {
             // Fetch data if needed
             if playdateViewModel.playdates.isEmpty {
                 playdateViewModel.fetchPlaydates()
             }
         }
     }
}

// Optional: Add a preview provider
#if DEBUG
struct PlaydatesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for preview context
            PlaydatesListView()
        }
    }
}
#endif
