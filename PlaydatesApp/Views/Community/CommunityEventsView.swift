import SwiftUI

// The CalendarViewMode enum is now defined in Models/CalendarViewMode.swift

// Placeholder Views
struct CreateEventView: View {
    var body: some View { Text("Create Event Placeholder") }
}
struct EventFilterView: View {
    var body: some View { Text("Event Filter Placeholder") }
}

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
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory?
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Search and filter
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ColorTheme.lightText)
                            
                            TextField("Search events", text: $searchText)
                                .foregroundColor(ColorTheme.text)
                            
                            if !searchText.isEmpty {
                                Button { // Use trailing closure syntax
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(ColorTheme.lightText) // Keep color
                                }
                                .buttonStyle(PlainButtonStyle()) // Apply plain style
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
                            Button { // Use trailing closure syntax
                                activeSheet = .filter
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "line.3.horizontal.decrease")
                                    Text("Filter")
                                }
                                // Font/color handled by textStyle
                            }
                            .textStyle() // Apply text style
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Calendar view mode selector
                        CalendarViewModeSelector(selectedMode: $viewModel.calendarViewMode)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Event category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // CategoryButton uses PlainButtonStyle internally (defined in HomeComponents)
                            CategoryButton(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            CategoryButton(
                                title: "Playdates",
                                isSelected: selectedCategory == .playdate,
                                action: { selectedCategory = .playdate }
                            )
                            
                            CategoryButton(
                                title: "Workshops",
                                isSelected: selectedCategory == .workshop,
                                action: { selectedCategory = .workshop }
                            )
                            
                            CategoryButton(
                                title: "Education",
                                isSelected: selectedCategory == .education,
                                action: { selectedCategory = .education }
                            )
                            
                            CategoryButton(
                                title: "Outdoors",
                                isSelected: selectedCategory == .outdoors,
                                action: { selectedCategory = .outdoors }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(.top, 40)
                    } else if viewModel.filteredEvents.isEmpty {
                        // Empty state
                        SectionBox(title: "Upcoming Events") {
                            // EmptyStateBox uses primaryStyle internally (defined in HomeComponents)
                            EmptyStateBox(
                                icon: "calendar",
                                title: "No Events Yet",
                                message: "Create an event or find events happening in your community",
                                buttonTitle: "Create Event",
                                buttonAction: {
                                    activeSheet = .createEvent
                                }
                            )
                        }
                        
                        // Join upcoming events
                        SectionBox(
                            title: "Upcoming Community Events",
                            viewAllAction: nil
                        ) {
                            if viewModel.upcomingEvents.isEmpty {
                                Text("No upcoming events in your community")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.upcomingEvents) { event in
                                            EnhancedEventCard(event: event)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Your events
                        if !viewModel.userEvents.isEmpty {
                            SectionBox(
                                title: "Your Events",
                                viewAllAction: viewModel.userEvents.count > 3 ? {
                                    // View all user events
                                } : nil
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.userEvents) { event in
                                            EnhancedEventCard(event: event)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Calendar view
                        SectionBox(title: "Event Calendar") {
                            // Placeholder for calendar view - would be replaced with a real calendar component
                            EventCalendarPlaceholder(viewMode: viewModel.calendarViewMode)
                        }
                        
                        // Upcoming events
                        SectionBox(
                            title: "Upcoming Events",
                            viewAllAction: viewModel.filteredEvents.count > 5 ? {
                                // View all upcoming events
                            } : nil
                        ) {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredEvents.prefix(5)) { event in
                                    CompactEventCard(event: event)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarItems(trailing: Button { // Use trailing closure syntax
            activeSheet = .createEvent
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ColorTheme.primary) // Keep color
        }
        .buttonStyle(PlainButtonStyle())) // Apply plain style
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
        .onChange(of: selectedCategory) { newValue in
            if let category = newValue {
                viewModel.setCategories([category])
            } else {
                viewModel.setCategories([])
            }
            viewModel.applyFilters()
        }
    }
}

struct CalendarViewModeSelector: View {
    @Binding var selectedMode: CalendarViewMode
    
    var body: some View {
        HStack(spacing: 0) {
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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
        .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background/overlay
    }
}

struct EnhancedEventCard: View {
    let event: CommunityEvent
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with date info
            ZStack(alignment: .bottomLeading) {
                // Background gradient based on event category
                Rectangle()
                    .fill(categoryGradient)
                    .frame(height: 100)
                
                // Event themed icon
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                    .offset(x: 120, y: -20)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Date box
                HStack(spacing: 16) {
                    // Day and month
                    VStack(spacing: 0) {
                        Text(formatDayOfWeek(event.startDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(formatDayOfMonth(event.startDate))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(formatMonth(event.startDate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Time and category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(event.startDate))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(event.category.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding(12)
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Event info
            VStack(alignment: .leading, spacing: 10) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text(event.location?.name ?? "Unknown Location")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                        .lineLimit(1)
                }
                
                // Attendees
                HStack {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                        .foregroundColor(ColorTheme.lightText)
                    
                    Text("\(event.attendeeIDs.count) attending")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                    
                    Spacer()
                    
                    if event.isAtMaxCapacity {
                        Text("Full")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    } else {
                        Text("\(event.remainingSpots) spots left")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .frame(width: 300, height: 220)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            isAnimating = true
        }
    }
    
    private var categoryIcon: String {
        switch event.category {
        case .playdate:
            return "figure.2.and.child.holdinghands"
        case .workshop:
            return "hammer.fill"
        case .education:
            return "book.fill"
        case .outdoors:
            return "leaf.fill"
        // Add default case to make switch exhaustive
        default:
             return "calendar" // Default icon
        }
    }
    
    private var categoryGradient: LinearGradient {
        switch event.category {
        case .playdate:
            return LinearGradient(
                gradient: Gradient(colors: [ColorTheme.primary.opacity(0.7), ColorTheme.primary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .workshop:
            return LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .education:
            return LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.7), Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .outdoors:
            return LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        // Add default case to make switch exhaustive
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CompactEventCard: View {
    let event: CommunityEvent
    
    var body: some View {
        HStack(spacing: 16) {
            // Date box
            VStack(spacing: 0) {
                Text(formatDayOfMonth(event.startDate))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(formatMonth(event.startDate))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 50, height: 50)
            .background(categoryColor)
            .cornerRadius(8)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text(event.location?.name ?? "Unknown Location")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                
                HStack {
                    Text(formatTime(event.startDate))
                        .font(.caption)
                        .foregroundColor(ColorTheme.text)
                    
                    Spacer()
                    
                    Text("\(event.attendeeIDs.count) attending")
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                }
            }
            
            Spacer()
            
            // Category indicator
            Image(systemName: categoryIcon)
                .foregroundColor(categoryColor)
                .font(.system(size: 20))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var categoryIcon: String {
        switch event.category {
        case .playdate:
            return "figure.2.and.child.holdinghands"
        case .workshop:
            return "hammer.fill"
        case .education:
            return "book.fill"
        case .outdoors:
            return "leaf.fill"
        // Add default case to make switch exhaustive
        default:
            return "calendar" // Default icon
        }
    }
    
    private var categoryColor: Color {
        switch event.category {
        case .playdate:
            return ColorTheme.primary
        case .workshop:
            return Color.orange
        case .education:
            return Color.purple
        case .outdoors:
            return Color.green
        // Add default case to make switch exhaustive
        default:
            return Color.gray
        }
    }
    
    private func formatDayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct EventCalendarPlaceholder: View {
    let viewMode: CalendarViewMode
    
    var body: some View {
        VStack(spacing: 16) {
            // Calendar header
            HStack {
                Text("March 2025")
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button { // Use trailing closure syntax
                        // Action for previous
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(ColorTheme.primary) // Keep color
                    }
                    .buttonStyle(PlainButtonStyle()) // Apply plain style
                    
                    Button { // Use trailing closure syntax
                        // Action for next
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(ColorTheme.primary) // Keep color
                    }
                    .buttonStyle(PlainButtonStyle()) // Apply plain style
                }
            }
            
            // Display different calendar views based on mode
            switch viewMode {
            case .day:
                dayCalendarView
            case .week:
                weekCalendarView
            case .month:
                monthCalendarView
            case .agenda:
                agendaView
            case .map:
                mapView
            }
        }
        .padding()
    }
    
    // Day view
    private var dayCalendarView: some View {
        VStack(spacing: 8) {
            Text("Thursday, March 27")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Time slots
            ForEach(8..<18) { hour in
                HStack(alignment: .top, spacing: 12) {
                    // Time
                    Text("\(hour % 12 == 0 ? 12 : hour % 12):00 \(hour < 12 ? "AM" : "PM")")
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .frame(width: 60, alignment: .leading)
                    
                    // Time slot
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 30)
                        .cornerRadius(4)
                }
            }
        }
    }
    
    // Week view
    private var weekCalendarView: some View {
        VStack(spacing: 8) {
            // Days of week
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(day == "Thu" ? ColorTheme.primary : ColorTheme.lightText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Week grid
            HStack(spacing: 0) {
                ForEach(24..<31) { day in
                    VStack(spacing: 4) {
                        Text("\(day)")
                            .font(.subheadline)
                            .foregroundColor(day == 27 ? ColorTheme.primary : ColorTheme.text)
                            .frame(width: 30, height: 30)
                            .background(day == 27 ? ColorTheme.primary.opacity(0.1) : Color.clear)
                            .cornerRadius(15)
                        
                        // Event indicators
                        if [25, 27, 28].contains(day) {
                            Circle()
                                .fill(ColorTheme.primary)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Month view
    private var monthCalendarView: some View {
        VStack(spacing: 16) {
            // Days of week
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Previous month
                ForEach(24..<29) { day in
                    Text("\(day)")
                        .font(.caption)
                        .foregroundColor(ColorTheme.lightText.opacity(0.5))
                        .frame(height: 35)
                }
                
                // Current month
                ForEach(1..<32) { day in
                    ZStack {
                        if day == 27 {
                            Circle()
                                .fill(ColorTheme.primary)
                                .frame(width: 35, height: 35)
                        }
                        
                        Text("\(day)")
                            .font(.caption)
                            .foregroundColor(day == 27 ? .white : ColorTheme.text)
                        
                        // Event indicators
                        if [5, 10, 15, 20, 25, 27].contains(day) {
                            Circle()
                                .fill(day == 27 ? .white : ColorTheme.primary)
                                .frame(width: 4, height: 4)
                                .offset(y: 12)
                        }
                    }
                    .frame(height: 35)
                }
            }
        }
    }
    
    // Agenda view
    private var agendaView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Today's events
            Text("Today - March 27")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.text)
            
            eventListItem(time: "9:00 AM", title: "Playdate at Central Park", category: .playdate)
            eventListItem(time: "2:00 PM", title: "Art Workshop", category: .workshop)
            
            Divider()
            
            // Tomorrow's events
            Text("Tomorrow - March 28")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.text)
            
            eventListItem(time: "10:00 AM", title: "Swimming Lessons", category: .other)
            eventListItem(time: "3:30 PM", title: "Story Time", category: .education)
        }
    }
    
    // Map view
    private var mapView: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    Text("Map View")
                        .foregroundColor(ColorTheme.lightText)
                )
        }
    }
    
    private func eventListItem(time: String, title: String, category: EventCategory) -> some View {
        HStack(spacing: 12) {
            // Time
            Text(time)
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
                .frame(width: 70, alignment: .leading)
            
            // Event dot
            Circle()
                .fill(getCategoryColor(category))
                .frame(width: 8, height: 8)
            
            // Event title
            Text(title)
                .font(.subheadline)
                .foregroundColor(ColorTheme.text)
            
            Spacer()
            
            // Category icon
            Image(systemName: getCategoryIcon(category))
                .font(.system(size: 14))
                .foregroundColor(getCategoryColor(category))
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getCategoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .playdate:
            return ColorTheme.primary
        case .workshop:
            return Color.orange
        case .education:
            return Color.purple
        case .outdoors:
            return Color.green
        // Add default case to make switch exhaustive
        default:
            return Color.gray
        }
    }
    
    private func getCategoryIcon(_ category: EventCategory) -> String {
        switch category {
        case .playdate:
            return "figure.2.and.child.holdinghands"
        case .workshop:
            return "hammer.fill"
        case .education:
            return "book.fill"
        case .outdoors:
            return "leaf.fill"
        // Add default case to make switch exhaustive
        default:
            return "calendar" // Default icon
        }
    }
}
// Add a computed property to CommunityEvent for remaining spots
extension CommunityEvent {
    // Corrected property name from maxAttendees to maxCapacity
    var isAtMaxCapacity: Bool {
        if let capacity = maxCapacity {
            return attendeeIDs.count >= capacity
        }
        return false
    }

    // Corrected property name from maxAttendees to maxCapacity
    var remainingSpots: Int {
        if let capacity = maxCapacity {
            let remaining = capacity - attendeeIDs.count
            return remaining > 0 ? remaining : 0
        }
        // Consider if unlimited should be represented differently, e.g., Int.max or nil
        return Int.max // Represent unlimited spots
    }
}
