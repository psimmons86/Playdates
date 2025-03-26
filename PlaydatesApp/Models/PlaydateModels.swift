import Foundation

// MARK: - Playdate Status

public enum PlaydateStatus {
    case planned
    case inProgress
    case completed
    case cancelled
}

// MARK: - Playdate Extensions

extension Playdate {
    public var currentStatus: PlaydateStatus {
        if isCompleted {
            return .completed
        } else if isInProgress {
            return .inProgress
        } else {
            return .planned
        }
    }
    
    public var isInProgress: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
    
    public var isCompleted: Bool {
        let now = Date()
        return endDate < now
    }
    
    public var isPlanned: Bool {
        let now = Date()
        return startDate > now
    }
}
