import Foundation

enum ActivityType: String, Codable, CaseIterable {
    case park
    case themePark = "theme_park"
    case beach
    case museum
    case summerCamp = "summer_camp"
    case zoo
    case aquarium
    case library
    case playground
    case sportingEvent = "sporting_event"
    case movieTheater = "movie_theater"
    case swimmingPool = "swimming_pool"
    case hikingTrail = "hiking_trail"
    case indoorPlayArea = "indoor_play_area"
    case other

    var title: String {
        switch self {
        case .park: return "Park"
        case .themePark: return "Theme Park"
        case .beach: return "Beach"
        case .museum: return "Museum"
        case .summerCamp: return "Summer Camp"
        case .zoo: return "Zoo"
        case .aquarium: return "Aquarium"
        case .library: return "Library"
        case .playground: return "Playground"
        case .sportingEvent: return "Sporting Event"
        case .movieTheater: return "Movie Theater"
        case .swimmingPool: return "Swimming Pool"
        case .hikingTrail: return "Hiking Trail"
        case .indoorPlayArea: return "Indoor Play Area"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .park: return "leaf"
        case .themePark: return "ferriswheel"
        case .beach: return "sun.max"
        case .museum: return "building.columns"
        case .summerCamp: return "tent"
        case .zoo: return "pawprint"
        case .aquarium: return "drop"
        case .library: return "book"
        case .playground: return "figure.play"
        case .sportingEvent: return "sportscourt"
        case .movieTheater: return "film"
        case .swimmingPool: return "figure.pool.swim"
        case .hikingTrail: return "mountain.2"
        case .indoorPlayArea: return "square.grid.3x3"
        case .other: return "questionmark.circle"
        }
    }

    var iconName: String {
        return icon
    }
}
