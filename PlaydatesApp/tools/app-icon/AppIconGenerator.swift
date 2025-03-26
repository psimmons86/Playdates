import SwiftUI
import Foundation
import PlaydatesApp

struct AppIconGenerator: View {
    // App color scheme based on the ColorTheme
    let primaryColor = ColorTheme.primary
    let secondaryColor = ColorTheme.secondary
    let accentColor = ColorTheme.accent
    let highlightColor = ColorTheme.highlight
    let textColor = ColorTheme.darkPurple
    
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

// Using ColorTheme for colors instead of local hex implementation

// Preview provider
struct AppIconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        AppIconGenerator()
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
