import Foundation
import SwiftUI

struct ColorTheme {
    // New Color Scheme based on the design
    static let primary = Color(hex: "91DDCF")      // Mint green
    static let secondary = Color(hex: "F7F9F2")    // Off-white
    static let accent = Color(hex: "E8C5E5")       // Soft lavender
    static let highlight = Color(hex: "F19ED2")    // Pink
    static let darkPurple = Color(hex: "5D4E6D")   // Dark purple for text
    static let text = Color(hex: "333333")         // Dark text
    static let lightText = Color(hex: "666666")    // Secondary text
    static let background = Color(hex: "FAFAFA")   // Very light background
    
    // Additional shades and variations
    static let primaryLight = Color(hex: "B5E8DF")
    static let primaryDark = Color(hex: "6DB9AD")
    static let secondaryLight = Color(hex: "FBFCF8")
    static let secondaryDark = Color(hex: "E9EBE4")
    static let accentLight = Color(hex: "F2DAEF")
    static let accentDark = Color(hex: "D1A9CE")
    static let highlightLight = Color(hex: "F7BFE2")
    static let highlightDark = Color(hex: "E07DBB")
    
    // Semantic colors
    static let success = Color(hex: "4CAF50")
    static let warning = Color(hex: "FFC107")
    static let error = Color(hex: "F44336")
    static let info = Color(hex: "2196F3")
    
    // Status colors
    static let scheduled = primary
    static let inProgress = highlight
    static let completed = accent
    static let cancelled = Color(hex: "9E9E9E")
}

// Extension to create colors from hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
