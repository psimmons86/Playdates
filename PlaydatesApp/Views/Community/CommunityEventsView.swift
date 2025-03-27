import SwiftUI

struct CommunityEventsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: CommunityEventViewModel
    @State private var showingCreateEventSheet = false
    @State private var showingFilterSheet = false
    
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
                    
                    // Calendar or event list based on selected mode
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if viewModel.filteredEvents.isEmpty {
                        Spacer()
                        EmptyEventsView(showingCreateEventSheet: $showingCreateEventSheet)
                        Spacer()
                    } else {
                        SwiftUI.Group {
                            switch viewModel.calendarViewMode {
                            case .day:
                                DayCalendarView(events: viewModel.filteredEvents)
                            case .week:
                                WeekCalendarView(events: viewModel.filteredEvents)
                            case .month:
                                MonthCalendarView(events: viewModel.filteredEvents)
                            case .agenda:
                                AgendaView(events: viewModel.filteredEvents)
                            case .map:
                                MapEventsView(events: viewModel.filteredEvents)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Community Events")
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
                    showingCreateEventSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ColorTheme.primary)
                }
            )
            .sheet(isPresented: $showingCreateEventSheet) {
                CreateEventView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                EventFilterView()
                    .environmentObject(viewModel)
            }
            .onAppear {
                viewModel.fetchUpcomingEvents()
                
                if let userID = authViewModel.currentUser?.id {
                    viewModel.fetchUserEvents(userID: userID)
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
            .background(
                selectedMode == mode ?
                    Color.white.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2) :
                    Color.clear
            )
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

// Placeholder views for different calendar modes
struct DayCalendarView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today, \(formattedDate)")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(hoursOfDay, id: \.self) { hour in
                    HourRow(hour: hour, events: eventsForHour(hour))
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
    
    private var hoursOfDay: [Int] {
        return Array(0..<24)
    }
    
    private func eventsForHour(_ hour: Int) -> [CommunityEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            let eventHour = calendar.component(.hour, from: event.startDate)
            return eventHour == hour
        }
    }
}

struct HourRow: View {
    let hour: Int
    let events: [CommunityEvent]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Hour label
            Text(formattedHour)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 50, alignment: .trailing)
                .foregroundColor(ColorTheme.lightText)
            
            // Divider
            Rectangle()
                .fill(ColorTheme.lightBackground)
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // Events
            if events.isEmpty {
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(events) { event in
                        EventCard(event: event)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var formattedHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hour)"
    }
}

struct WeekCalendarView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        Text("Week Calendar View - Coming Soon")
            .foregroundColor(ColorTheme.lightText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MonthCalendarView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        Text("Month Calendar View - Coming Soon")
            .foregroundColor(ColorTheme.lightText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AgendaView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedEvents.keys.sorted(), id: \.self) { date in
                    if let dateEvents = groupedEvents[date] {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(formattedDate(date))
                                .font(.headline)
                                .foregroundColor(ColorTheme.text)
                                .padding(.horizontal)
                            
                            ForEach(dateEvents) { event in
                                EventCard(event: event)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var groupedEvents: [Date: [CommunityEvent]] {
        let calendar = Calendar.current
        var result: [Date: [CommunityEvent]] = [:]
        
        for event in events {
            let components = calendar.dateComponents([.year, .month, .day], from: event.startDate)
            if let date = calendar.date(from: components) {
                if result[date] == nil {
                    result[date] = []
                }
                result[date]?.append(event)
            }
        }
        
        // Sort events within each day
        for (date, dateEvents) in result {
            result[date] = dateEvents.sorted { $0.startDate < $1.startDate }
        }
        
        return result
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

struct MapEventsView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        Text("Map View - Coming Soon")
            .foregroundColor(ColorTheme.lightText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EventCard: View {
    let event: CommunityEvent
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: event.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor)
                }
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                        .lineLimit(1)
                    
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                    
                    HStack {
                        // Time
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(formattedTime)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(ColorTheme.lightText)
                        
                        Spacer()
                        
                        // Attendee count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 12))
                            Text("\(event.attendeeIDs.count) attending")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(ColorTheme.lightText)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ColorTheme.lightText)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        switch event.category {
        case .holiday:
            return .red
        case .fundraiser:
            return .green
        case .workshop:
            return .orange
        case .playdate:
            return ColorTheme.primary
        case .sports:
            return .blue
        case .arts:
            return .purple
        case .education:
            return .yellow
        case .outdoors:
            return .green
        case .other:
            return ColorTheme.lightText
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}

struct EmptyEventsView: View {
    @Binding var showingCreateEventSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(ColorTheme.lightText)
            
            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.text)
            
            Text("Create or join community events to connect with other parents and families")
                .font(.body)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button(action: {
                    showingCreateEventSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create an Event")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.primary)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Navigate to discover events
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Discover Events")
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

struct EventFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: CommunityEventViewModel
    
    @State private var selectedCategories: [EventCategory] = []
    @State private var showFreeOnly: Bool = false
    @State private var ageRangeValues: ClosedRange<Double> = 0...18
    @State private var dateRange: ClosedRange<Date> = Date()...Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Categories")) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Button(action: {
                            if selectedCategories.contains(category) {
                                selectedCategories.removeAll { $0 == category }
                            } else {
                                selectedCategories.append(category)
                            }
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(selectedCategories.contains(category) ? ColorTheme.primary : ColorTheme.lightText)
                                
                                Text(category.displayName)
                                    .foregroundColor(ColorTheme.text)
                                
                                Spacer()
                                
                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ColorTheme.primary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Price")) {
                    Toggle("Free Events Only", isOn: $showFreeOnly)
                }
                
                Section(header: Text("Age Range")) {
                    VStack {
                        HStack {
                            Text("\(Int(ageRangeValues.lowerBound))")
                                .foregroundColor(ColorTheme.text)
                            
                            Spacer()
                            
                            Text("\(Int(ageRangeValues.upperBound))")
                                .foregroundColor(ColorTheme.text)
                        }
                        .font(.caption)
                        
                        Slider(value: $ageRangeValues.lowerBound, in: 0...18, step: 1)
                        Slider(value: $ageRangeValues.upperBound, in: 0...18, step: 1)
                    }
                }
                
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $dateRange.lowerBound, displayedComponents: .date)
                    DatePicker("End Date", selection: $dateRange.upperBound, displayedComponents: .date)
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
            .navigationTitle("Filter Events")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Initialize with current filter values
                selectedCategories = viewModel.selectedCategories
                showFreeOnly = viewModel.showFreeOnly
                
                if let ageRange = viewModel.ageRangeFilter {
                    ageRangeValues = Double(ageRange.lowerBound)...Double(ageRange.upperBound)
                }
                
                if let dateRangeFilter = viewModel.dateRangeFilter {
                    dateRange = dateRangeFilter
                }
            }
        }
    }
    
    private func applyFilters() {
        viewModel.setCategories(selectedCategories)
        
        if viewModel.showFreeOnly != showFreeOnly {
            viewModel.toggleFreeOnly()
        }
        
        let intAgeRange = Int(ageRangeValues.lowerBound)...Int(ageRangeValues.upperBound)
        viewModel.setAgeRange(intAgeRange)
        
        viewModel.setDateRange(dateRange)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func resetFilters() {
        selectedCategories = []
        showFreeOnly = false
        ageRangeValues = 0...18
        dateRange = Date()...Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        viewModel.resetFilters()
    }
}

// Placeholder for the create event view
struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Text("Create Event Form - Coming Soon")
                .navigationTitle("Create Event")
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

// Placeholder for the event detail view
struct EventDetailView: View {
    let event: CommunityEvent
    
    var body: some View {
        Text("Event Detail View for \(event.title)")
            .navigationTitle(event.title)
    }
}

struct CommunityEventsView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityEventsView()
            .environmentObject(AuthViewModel())
    }
}
