import Foundation
import SwiftUI

// MARK: - String Extension for Localization
extension String {
    /// Returns a localized string, using self as the key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        let localizedFormat = NSLocalizedString(self, comment: "")
        return String(format: localizedFormat, arguments: arguments)
    }
}

// MARK: - Text Extension for SwiftUI
extension Text {
    /// Creates a Text view that displays localized content identified by a key.
    static func localized(_ key: String) -> Text {
        return Text(key.localized)
    }
    
    /// Creates a Text view that displays localized content with format arguments
    static func localized(_ key: String, with arguments: CVarArg...) -> Text {
        let localizedString = key.localized(with: arguments)
        return Text(localizedString)
    }
}

// MARK: - Localization Constants
public struct L10n {
    // MARK: - Playdate Cards
    public struct Playdate {
        public static let completed = "playdate.status.completed"
        public static let inProgress = "playdate.status.inProgress"
        public static let unknownLocation = "playdate.location.unknown"
        public static let participants = "playdate.participants"
        public static let activity = "playdate.activity"
        public static let invitation = "playdate.invitation"
        public static let accept = "playdate.invitation.accept"
        public static let decline = "playdate.invitation.decline"
    }
    
    // MARK: - Activity Cards
    public struct Activity {
        public static let featured = "activity.featured"
    }
    
    // MARK: - Common UI Components
    public struct Common {
        public static let user = "common.user"
    }
    
    // MARK: - Empty States
    public struct EmptyState {
        public static let title = "emptystate.title.default"
        public static let message = "emptystate.message.default"
    }
}
