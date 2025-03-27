import Foundation
import SwiftUI

public enum ColorTheme {
    // MARK: - Main Colors
    
    // Primary colors using hex values
    public static let primary = Color(hex: "91DDCF")      // Mint green
    public static let secondary = Color(hex: "F7F9F2")    // Off-white
    public static let accent = Color(hex: "E8C5E5")       // Soft lavender
    public static let highlight = Color(hex: "F19ED2")    // Pink
    public static let darkPurple = Color(hex: "5D4E6D")   // Dark purple for text
    public static let text = Color(hex: "333333")         // Dark text
    public static let darkText = Color(hex: "333333")     // Dark text (alias for text)
    public static let lightText = Color(hex: "666666")    // Secondary text
    public static let background = Color(hex: "FAFAFA")   // Very light background
    public static let lightBackground = Color(hex: "F0F0F0") // Light background for UI elements
    
    // MARK: - Additional Shades
    
    // Additional shades and variations
    public static let primaryLight = Color(hex: "B5E8DF")
    public static let primaryDark = Color(hex: "6DB9AD")
    public static let secondaryLight = Color(hex: "FBFCF8")
    public static let secondaryDark = Color(hex: "E9EBE4")
    public static let accentLight = Color(hex: "F2DAEF")
    public static let accentDark = Color(hex: "D1A9CE")
    public static let highlightLight = Color(hex: "F7BFE2")
    public static let highlightDark = Color(hex: "E07DBB")
    
    // MARK: - Semantic Colors
    
    // Semantic colors
    public static let success = Color(hex: "4CAF50")
    public static let warning = Color(hex: "FFC107")
    public static let error = Color(hex: "F44336")
    public static let info = Color(hex: "2196F3")
    
    // MARK: - Status Colors
    
    // Status colors
    public static let scheduled = primary
    public static let inProgress = highlight
    public static let completed = accent
    public static let cancelled = Color(hex: "9E9E9E")
}

// MARK: - Color Extension for UIKit Compatibility

extension ColorTheme {
    public static func uiColor(_ color: Color) -> UIColor {
        UIColor(color)
    }
}

// MARK: - Color Extension for SwiftUI Modifiers

extension Color {
    public static var primaryColor: Color { ColorTheme.primary }
    public static var accentColor: Color { ColorTheme.accent }
    public static var highlightColor: Color { ColorTheme.highlight }
    public static var textColor: Color { ColorTheme.text }
    public static var lightTextColor: Color { ColorTheme.lightText }
    public static var darkPurpleColor: Color { ColorTheme.darkPurple }
    public static var backgroundColor: Color { ColorTheme.background }
    
    // Extension to create colors from hex values
    public init(hex: String) {
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
