import Foundation
import SwiftUI

public enum ColorTheme {
    // MARK: - Main Colors
    
    // Primary colors using hex values
    public static let primary = Color(hexString: "5F8B4C")      // Green (New Palette)
    public static let secondary = Color(hexString: "FFDDAB")    // Beige (New Palette - reusing background)
    public static let accent = Color(hexString: "FF9A9A")       // Pink (New Palette)
    public static let highlight = Color(hexString: "FF9A9A")    // Pink (New Palette - reusing accent)
    public static let darkPurple = Color(hexString: "945034")   // Brown (New Palette - replacing text role)
    public static let text = Color(hexString: "945034")         // Brown (New Palette - main text)
    public static let darkText = Color(hexString: "945034")     // Brown (New Palette - main text alias)
    public static let lightText = Color(hexString: "5F8B4C")    // Green (New Palette - secondary text)
    public static let background = Color(hexString: "FFDDAB")   // Beige (New Palette - background)
    public static let lightBackground = Color(hexString: "FFFFFF") // White background for UI elements
    
    // MARK: - Additional Shades
    
    // Additional shades and variations
    public static let primaryLight = Color(hexString: "B5E8DF")
    public static let primaryDark = Color(hexString: "6DB9AD")
    public static let secondaryLight = Color(hexString: "FBFCF8")
    public static let secondaryDark = Color(hexString: "E9EBE4")
    public static let accentLight = Color(hexString: "F2DAEF")
    public static let accentDark = Color(hexString: "D1A9CE")
    public static let highlightLight = Color(hexString: "F7BFE2")
    public static let highlightDark = Color(hexString: "E07DBB")
    
    // MARK: - Semantic Colors
    
    // Semantic colors
    public static let success = Color(hexString: "4CAF50")
    public static let warning = Color(hexString: "FFC107")
    public static let error = Color(hexString: "F44336")
    public static let info = Color(hexString: "2196F3")
    
    // MARK: - Status Colors
    
    // Status colors
    public static let scheduled = primary
    public static let inProgress = highlight
    public static let completed = accent
    public static let cancelled = Color(hexString: "9E9E9E")
}

// MARK: - Color Extension for UIKit Compatibility

extension ColorTheme {
    public static func uiColor(_ color: Color) -> UIColor {
        UIColor(color)
    }
}

// MARK: - Color Extension for Hex Initialization and SwiftUI Modifiers

extension Color {
    // Static properties referencing ColorTheme
    public static var primaryColor: Color { ColorTheme.primary }
    public static var accentColor: Color { ColorTheme.accent }
    public static var highlightColor: Color { ColorTheme.highlight }
    public static var textColor: Color { ColorTheme.text }
    public static var lightTextColor: Color { ColorTheme.lightText }
    public static var darkPurpleColor: Color { ColorTheme.darkPurple }
    public static var backgroundColor: Color { ColorTheme.background }
    
    // Renamed initializer to avoid conflicts
    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            (a, r, g, b) = (1, 1, 1, 0) // Default to black with alpha 0
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
