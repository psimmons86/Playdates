import Foundation
import CoreLocation

struct Location: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double

    // Computed property for CoreLocation coordinate (not stored/encoded)
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Full initializer with all parameters
    init(id: String = UUID().uuidString, name: String, address: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }

    // Convenience initializer that only requires coordinates
    init(id: String = UUID().uuidString, latitude: Double, longitude: Double) {
        self.id = id
        self.name = "Unknown Location"
        self.address = "Unknown Address"
        self.latitude = latitude
        self.longitude = longitude
    }

    // Custom decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode ID with fallback
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString

        // Decode name safely
        if let nameString = try? container.decode(String.self, forKey: .name) {
            name = nameString
        } else if let nameNumber = try? container.decode(Int.self, forKey: .name) {
            name = String(nameNumber)
        } else {
            name = "Unknown Location"
        }

        // Decode address safely
        if let addressString = try? container.decode(String.self, forKey: .address) {
            address = addressString
        } else {
            address = "Unknown Address"
        }

        // Decode coordinates safely
        if let latDouble = try? container.decode(Double.self, forKey: .latitude) {
            latitude = latDouble
        } else if let latInt = try? container.decode(Int.self, forKey: .latitude) {
            latitude = Double(latInt)
        } else if let latString = try? container.decode(String.self, forKey: .latitude),
                  let latValue = Double(latString) {
            latitude = latValue
        } else {
            latitude = 0.0 // Default
        }

        if let longDouble = try? container.decode(Double.self, forKey: .longitude) {
            longitude = longDouble
        } else if let longInt = try? container.decode(Int.self, forKey: .longitude) {
            longitude = Double(longInt)
        } else if let longString = try? container.decode(String.self, forKey: .longitude),
                  let longValue = Double(longString) {
            longitude = longValue
        } else {
            longitude = 0.0 // Default
        }
    }

    // Explicit encoder to ensure values are properly encoded
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case latitude
        case longitude
    }

    // Implement Equatable
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.name == rhs.name &&
               lhs.address == rhs.address
    }
}
