import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase
import FirebaseAuth // Add import for FirebaseAuth

// Create Playdate View
public struct NewPlaydateView: View {
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var location = ""
    
    @State private var showingLocationPicker = false
    @State private var selectedLocation: Location?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Playdate Details")) {
                        TextField("Title", text: $title)
                        
                        TextField("Description", text: $description)
                        
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        
                        // Location picker button
                        Button { // Use trailing closure syntax for action
                            showingLocationPicker = true
                        } label: {
                            HStack {
                                Text(selectedLocation?.name ?? "Select Location")
                                    .foregroundColor(selectedLocation == nil ? ColorTheme.lightText : ColorTheme.text) // Use theme colors
                                Spacer()
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(ColorTheme.primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle()) // Make HStack tappable without default styling
                        
                        if let location = selectedLocation {
                            Text(location.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button {
                            // Create playdate
                            // Use FirebaseAuthService singleton as fallback if authViewModel doesn't have user ID yet
                            guard let userID = authViewModel.user?.id ?? FirebaseAuthService.shared.currentUser?.uid else { return }
                            guard let location = selectedLocation else { return }

                            let playdate = Playdate(
                                id: nil, // Let Firestore generate the ID
                                hostID: userID,
                                title: title,
                                description: description,
                                activityType: "playdate",
                                location: location,
                                startDate: date,
                                endDate: date.addingTimeInterval(7200), // 2 hours later
                                attendeeIDs: [userID],
                                isPublic: true
                            )
                            
                            // Try to save to Firebase first
                            playdateViewModel.createPlaydate(playdate) { result in
                                // Ensure UI updates happen on the main thread
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(_):
                                        // Successfully saved to Firebase
                                        print("Playdate saved to Firebase")
                                    case .failure(let error):
                                        // Failed to save to Firebase, add to local array
                                        print("Failed to save to Firebase: \(error.localizedDescription)")
                                        self.playdateViewModel.playdates.append(playdate)
                                    }
                                    
                                    // Reset form
                                    self.title = ""
                                    self.description = ""
                                    self.date = Date()
                                    self.selectedLocation = nil
                                }
                            }
                        } label: {
                            Text("Create Playdate")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(title.isEmpty || selectedLocation == nil)
                    }
                }
                .navigationTitle("Create Playdate")
                .sheet(isPresented: $showingLocationPicker) {
                    // Inline LocationPickerView
                    NavigationView {
                        LocationPickerContent(selectedLocation: $selectedLocation, isPresented: $showingLocationPicker)
                    }
                }
            }
        }
    }
}
