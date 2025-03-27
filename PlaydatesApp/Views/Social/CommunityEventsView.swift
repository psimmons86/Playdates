import SwiftUI

enum ActiveSheet: Identifiable {
    case createEvent, filter
    
    var id: Int {
        switch self {
        case .createEvent: return 0
        case .filter: return 1
        }
    }
}

struct CommunityEventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = CommunityEventViewModel.shared
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Calendar view mode selector
                    CalendarViewModeSelector(selectedMode: $viewModel.calendarViewMode)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if viewModel.filteredEvents.isEmpty {
                        Spacer()
                        VStack {
                            Text("No Events Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.text)
                            
                            Button("Create an Event") {
                                activeSheet = .createEvent
                            }
                            .padding()
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.filteredEvents) { event in
                                Text(event.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Community Events")
            .navigationBarItems(
                leading: Button(action: {
                    activeSheet = .filter
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filter")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ColorTheme.primary)
                },
                trailing: Button(action: {
                    activeSheet = .createEvent
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorTheme.primary)
                }
            )
            .sheet(item: $activeSheet) { item -> AnyView in
                switch item {
                case .createEvent:
                    return AnyView(CreateEventView())
                case .filter:
                    return AnyView(EventFilterView())
                }
            }
            .onAppear {
                viewModel.fetchUpcomingEvents()
                
                if let userID = authViewModel.currentUser?.id {
                    viewModel.fetchUserEvents(userID: userID)
                }
            }
        }
    }
}

struct CalendarViewModeSelector: View {
    @Binding var selectedMode: CalendarViewMode
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                CalendarModeButton(
                    mode: .day,
                    selectedMode: $selectedMode,
                    icon: "calendar.day.timeline.left",
                    label: "Day"
                )
                
                CalendarModeButton(
                    mode: .week,
                    selectedMode: $selectedMode,
                    icon: "calendar.day.timeline.leading",
                    label: "Week"
                )
                
                CalendarModeButton(
                    mode: .month,
                    selectedMode: $selectedMode,
                    icon: "calendar",
                    label: "Month"
                )
                
                CalendarModeButton(
                    mode: .agenda,
                    selectedMode: $selectedMode,
                    icon: "list.bullet",
                    label: "Agenda"
                )
                
                CalendarModeButton(
                    mode: .map,
                    selectedMode: $selectedMode,
                    icon: "map",
                    label: "Map"
                )
            }
            .padding(.horizontal, 8)
        }
    }
}

struct CalendarModeButton: View {
    let mode: CalendarViewMode
    @Binding var selectedMode: CalendarViewMode
    let icon: String
    let label: String
    
    var body: some View {
        Button(action: {
            selectedMode = mode
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(label)
                    .font(.system(size: 12))
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .foregroundColor(selectedMode == mode ? ColorTheme.primary : ColorTheme.lightText)
            .background(selectedMode == mode ? Color.white : Color.clear)
            .shadow(color: selectedMode == mode ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
            .cornerRadius(8)
            .overlay(
                selectedMode == mode ?
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.primary, lineWidth: 1) :
                    nil
            )
        }
    }
}

// Placeholder for the create event view
struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Create Event Form - Coming Soon")
                .navigationTitle("Create Event")
                .navigationBarItems(leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                })
        }
    }
}

// Placeholder for the event filter view
struct EventFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Event Filter Form - Coming Soon")
                .navigationTitle("Filter Events")
                .navigationBarItems(trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                })
        }
    }
}

struct CommunityEventsView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityEventsView()
            .environmentObject(AuthViewModel())
    }
}
