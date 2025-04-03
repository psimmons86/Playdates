import SwiftUI

struct HomeCalendarView: View {
    @EnvironmentObject var playdateViewModel: PlaydateViewModel
    @State private var selectedDate: Date? = nil // For potential interaction later
    
    // Get the current calendar week
    private var currentWeek: [Date] {
        Calendar.current.currentWeekDays()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Week's Playdates")
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
                .padding(.horizontal)
            
            HStack(spacing: 8) { // Reduced spacing for compactness
                ForEach(currentWeek, id: \.self) { day in
                    DayCell(date: day, playdates: playdatesForDay(day))
                        .onTapGesture {
                            selectedDate = day
                            // TODO: Add action, e.g., show playdates for this day
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10) // Keep vertical padding for internal spacing
        // Removed background, cornerRadius, and shadow modifiers as RoundedCard in HomeView handles this.
    }
    
    // Helper to get playdates for a specific day
    private func playdatesForDay(_ day: Date) -> [Playdate] {
        playdateViewModel.playdates.filter { playdate in
            Calendar.current.isDate(playdate.startDate, inSameDayAs: day)
        }
    }
}

// Represents a single day cell in the calendar
struct DayCell: View {
    let date: Date
    let playdates: [Playdate]
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // e.g., "Mon"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // e.g., "15"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
            
            Text(dateFormatter.string(from: date))
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(isToday ? .white : ColorTheme.darkText)
                .frame(width: 35, height: 35) // Fixed size circle
                .background(backgroundCircle)
            
            // Indicator dot if there are playdates
            if !playdates.isEmpty {
                Circle()
                    .fill(ColorTheme.highlight)
                    .frame(width: 6, height: 6)
            } else {
                // Placeholder to maintain layout consistency
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity) // Allow cells to expand
    }
    
    // Background circle for the date number
    @ViewBuilder
    private var backgroundCircle: some View {
        if isToday {
            Circle().fill(ColorTheme.primary)
        } else {
            Circle().fill(Color.clear)
        }
    }
    
    // Check if the date is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// Extension to get current week days
extension Calendar {
    func currentWeekDays() -> [Date] {
        let today = startOfDay(for: Date()) // Get the start of today (non-optional)
        guard let weekInterval = dateInterval(of: .weekOfYear, for: today) else { // Only check the optional interval
            return []
        }
        
        var weekDays: [Date] = []
        enumerateDates(startingAfter: weekInterval.start, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            if date >= weekInterval.end {
                stop = true
            } else {
                weekDays.append(date)
            }
        }
        // Ensure we get exactly 7 days, starting from Sunday/Monday depending on locale
        // This simple approach might need refinement based on locale start day
        if weekDays.count < 7, let firstDay = weekDays.first {
             let daysToAdd = 7 - weekDays.count
             for i in 1...daysToAdd {
                 if let nextDay = date(byAdding: .day, value: i, to: weekDays.last!) {
                     weekDays.append(nextDay)
                 }
             }
        } else if weekDays.count > 7 {
            weekDays = Array(weekDays.prefix(7))
        }
        
        // Adjust if week starts on Sunday but calendar starts on Monday etc.
        // For simplicity, this example assumes the week starts correctly based on system calendar.
        
        return weekDays
    }
}

#if DEBUG
struct HomeCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = PlaydateViewModel()
        // Add some mock playdates for preview
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        mockViewModel.playdates = [
            Playdate(id: "1", hostID: "user1", title: "Park Fun", description: "", activityType: "park", location: nil, address: "123 Park St", startDate: today.addingTimeInterval(3600*2), endDate: today.addingTimeInterval(3600*4), attendeeIDs: [], isPublic: true),
            Playdate(id: "2", hostID: "user2", title: "Museum Visit", description: "", activityType: "museum", location: nil, address: "456 Museum Ave", startDate: tomorrow.addingTimeInterval(3600*10), endDate: tomorrow.addingTimeInterval(3600*12), attendeeIDs: [], isPublic: false)
        ]
        
        return HomeCalendarView()
            .environmentObject(mockViewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
