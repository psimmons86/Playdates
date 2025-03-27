import SwiftUI
import EventKit

struct CalendarSettingsView: View {
    @StateObject private var calendarService = CalendarService.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAuthAlert = false
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Calendar Access")) {
                    if calendarService.hasCalendarAccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Calendar access granted")
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Calendar access not granted")
                        }
                        
                        Button(action: {
                            requestAccess()
                        }) {
                            Text("Grant Calendar Access")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if calendarService.hasCalendarAccess {
                    Section(header: Text("Default Calendar")) {
                        if calendarService.availableCalendars.isEmpty {
                            Text("No calendars available")
                                .foregroundColor(.gray)
                        } else {
                            Picker("Calendar", selection: $calendarService.selectedCalendarIdentifier) {
                                Text("None").tag(String?.none)
                                
                                ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                                    HStack {
                                        Circle()
                                            .fill(Color(UIColor(cgColor: calendar.cgColor)))
                                            .frame(width: 12, height: 12)
                                        Text(calendar.title)
                                    }
                                    .tag(calendar.calendarIdentifier as String?)
                                }
                            }
                            .onChange(of: calendarService.selectedCalendarIdentifier) { newValue in
                                if let identifier = newValue {
                                    calendarService.setDefaultCalendar(identifier: identifier)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Notifications")) {
                        // Calendar notifications options would go here
                        Toggle("Send reminder 30 minutes before", isOn: .constant(true))
                        Toggle("Send reminder 1 day before", isOn: .constant(false))
                    }
                    
                    Section(header: Text("Sync Settings")) {
                        Toggle("Automatically add new playdates to calendar", isOn: .constant(false))
                        Toggle("Sync changes with calendar", isOn: .constant(true))
                    }
                }
            }
        }
        .navigationTitle("Calendar Settings")
        .alert(isPresented: $showingAuthAlert) {
            Alert(
                title: Text("Calendar Access Required"),
                message: Text("Please enable calendar access in Settings to use this feature."),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            calendarService.checkCalendarAuthorizationStatus()
        }
    }
    
    private func requestAccess() {
        calendarService.requestCalendarAccess { granted in
            if !granted {
                showingAuthAlert = true
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
struct CalendarSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalendarSettingsView()
        }
    }
}
#endif
