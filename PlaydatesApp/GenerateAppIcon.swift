import SwiftUI

struct GenerateAppIcon: View {
    // App color scheme based on the theme
    let primaryColor = Color(hex: "91DDCF") // Mint green
    let secondaryColor = Color(hex: "F7F9F2") // Off-white
    let accentColor = Color(hex: "E8C5E5") // Soft lavender
    let highlightColor = Color(hex: "F19ED2") // Pink
    let textColor = Color(hex: "5D4E6D") // Dark Purple
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [primaryColor, primaryColor.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Stylized figures representing parents and children
            HStack(spacing: -10) {
                // Child figure (smaller)
                ZStack {
                    Circle()
                        .fill(secondaryColor)
                        .frame(width: 60, height: 60)
                    
                    // Simple face
                    VStack(spacing: 8) {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(textColor)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(textColor)
                                .frame(width: 8, height: 8)
                        }
                        
                        Capsule()
                            .fill(textColor)
                            .frame(width: 20, height: 6)
                    }
                }
                .offset(y: 10)
                
                // Adult figure (larger)
                ZStack {
                    Circle()
                        .fill(highlightColor)
                        .frame(width: 80, height: 80)
                    
                    // Simple face
                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            Circle()
                                .fill(textColor)
                                .frame(width: 10, height: 10)
                            Circle()
                                .fill(textColor)
                                .frame(width: 10, height: 10)
                        }
                        
                        Capsule()
                            .fill(textColor)
                            .frame(width: 25, height: 8)
                    }
                }
                
                // Child figure (smaller)
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 60, height: 60)
                    
                    // Simple face
                    VStack(spacing: 8) {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(textColor)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(textColor)
                                .frame(width: 8, height: 8)
                        }
                        
                        Capsule()
                            .fill(textColor)
                            .frame(width: 20, height: 6)
                    }
                }
                .offset(y: 10)
            }
            
            // App name at the bottom
            VStack {
                Spacer()
                Text("Playdates")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .padding(.bottom, 20)
            }
            
            // Decorative elements
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 40, height: 40)
                .offset(x: -80, y: -80)
            
            Circle()
                .fill(highlightColor.opacity(0.3))
                .frame(width: 30, height: 30)
                .offset(x: 80, y: -70)
            
            Circle()
                .fill(secondaryColor.opacity(0.3))
                .frame(width: 25, height: 25)
                .offset(x: 70, y: 80)
        }
        .frame(width: 1024, height: 1024)
        .cornerRadius(220)
    }
}

// Helper extension to create colors from hex values
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

// Preview provider
struct GenerateAppIcon_Previews: PreviewProvider {
    static var previews: some View {
        GenerateAppIcon()
    }
}

/*
 HOW TO USE THIS ICON GENERATOR:
 
 1. Add this file to your Xcode project
 2. Run the app in the preview canvas or simulator
 3. Take screenshots of the icon at the following sizes:
    - 1024x1024 (App Store)
    - 180x180 (iPhone @3x)
    - 120x120 (iPhone @2x)
    - 167x167 (iPad Pro)
    - 152x152 (iPad)
    - 76x76 (iPad @1x)
 4. Save these screenshots with the appropriate filenames:
    - playdates-icon-1024.png
    - playdates-icon-180.png
    - playdates-icon-120.png
    - playdates-icon-167.png
    - playdates-icon-152.png
    - playdates-icon-76.png
 5. Add these images to your Assets.xcassets/AppIcon.appiconset folder
 
 The icon design features:
 - A mint green background (primary color)
 - Three stylized figures representing parents and children
 - The app name "Playdates" at the bottom
 - Decorative circular elements
 - Rounded corners for a modern look
 
 This icon visually represents the app's purpose of connecting families for playdates
 and uses the app's established color scheme.
 */
