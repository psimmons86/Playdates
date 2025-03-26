import Foundation
import SwiftUI

// MARK: - Helper Functions for Playdate Status Checks

internal func isPlaydateCompleted(_ playdate: Playdate) -> Bool {
    return Date() > playdate.endDate
}

internal func isPlaydateInProgress(_ playdate: Playdate) -> Bool {
    let now = Date()
    return now >= playdate.startDate && now <= playdate.endDate
}

// MARK: - Helper Functions for Optional String Handling

internal func hasBio(_ bio: String?) -> Bool {
    guard let bio = bio else { return false }
    return !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

internal func getBio(_ bio: String?) -> String {
    return bio ?? ""
}

internal func hasAddress(_ address: String?) -> Bool {
    guard let address = address else { return false }
    return !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

internal func hasDescription(_ description: String?) -> Bool {
    guard let description = description else { return false }
    return !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

// MARK: - Helper Functions for Date Formatting

internal func formatDayOfWeek(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date)
}

internal func formatDayOfMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
}

internal func formatMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
}

internal func formatTimeRange(start: Date, end: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

// MARK: - Helper Functions for Status Text and Color

internal func statusText(for status: PlaydateStatus) -> String {
    switch status {
    case .planned:
        return "Upcoming"
    case .inProgress:
        return "In Progress"
    case .completed:
        return "Completed"
    case .cancelled:
        return "Cancelled"
    }
}

@available(iOS 17.0, *)
internal func statusColor(for status: PlaydateStatus) -> Color {
    switch status {
    case .planned:
        return ColorTheme.highlight
    case .inProgress:
        return ColorTheme.primary
    case .completed:
        return ColorTheme.accent
    case .cancelled:
        return ColorTheme.lightText
    }
}

// MARK: - Helper Functions for Activity Type

internal func validActivityType(_ activityType: String?) -> (isValid: Bool, type: ActivityType?) {
    guard let activityType = activityType,
          let type = ActivityType(rawValue: activityType) else {
        return (false, nil)
    }
    return (true, type)
}
