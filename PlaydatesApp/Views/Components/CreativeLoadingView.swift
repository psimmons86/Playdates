import SwiftUI

struct CreativeLoadingView: View {
    var body: some View {
        ZStack {
            // Background Color (The storyboard handles the initial flash,
            // this ensures the view itself matches if shown longer)
            Color.infoBlue.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                // App Icon with Activity Icons
                ZStack {
                    // Use the actual AppIcon from Asset Catalog
                    Image("AppIcon") // Reference the asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140) // Make it a bit larger
                        // AppIcon asset has its own colors, no foregroundColor needed

                    // Tree Icon (Adjust offset slightly if needed relative to AppIcon)
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color.highlight) // Pink
                        .offset(x: -45, y: -40) // Adjusted offset

                    // Museum Icon (Adjust offset slightly if needed relative to AppIcon)
                    Image(systemName: "building.columns.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color.darkPurple) // Dark Purple
                        .offset(x: 45, y: -40) // Adjusted offset

                    // Playground Icon (Adjust offset slightly if needed relative to AppIcon)
                    Image(systemName: "figure.play")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color.highlight) // Pink
                        .offset(y: 45) // Adjusted offset
                }

                // Loading Text
                Text("Loading Playdates...")
                    .font(.headline)
                    .foregroundColor(Color.darkPurple) // Dark Purple
            }
        }
    }
}

// Add a preview provider for easy visualization in Xcode Canvas
struct CreativeLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        CreativeLoadingView()
    }
}

// Helper extension to access ColorTheme colors easily (assuming ColorTheme.swift exists)
extension Color {
    static var infoBlue: Color { Color(hexString: "2196F3") } // ColorTheme.info
    // Add other colors if needed, or ensure ColorTheme is accessible
    static var accent: Color { ColorTheme.accent } // Uncommented
    static var highlight: Color { ColorTheme.highlight } // Uncommented
    static var darkPurple: Color { ColorTheme.darkPurple } // Uncommented
}
