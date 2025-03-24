import SwiftUI
import UIKit

// This is a standalone script to generate app icons
// Run this file in Xcode or using swift command line

@main
struct GenerateAppIconScript {
    static func main() {
        // Create the icon view
        let iconView = GenerateAppIcon()
        
        // Define icon sizes
        let sizes = [
            ("playdates-icon-1024.png", CGSize(width: 1024, height: 1024)),
            ("playdates-icon-180.png", CGSize(width: 180, height: 180)),
            ("playdates-icon-120.png", CGSize(width: 120, height: 120)),
            ("playdates-icon-167.png", CGSize(width: 167, height: 167)),
            ("playdates-icon-152.png", CGSize(width: 152, height: 152)),
            ("playdates-icon-76.png", CGSize(width: 76, height: 76))
        ]
        
        // Get the path to the AppIcon.appiconset directory
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        let projectPath = currentDirectoryPath
        let appIconsetPath = "\(projectPath)/PlaydatesApp/Assets.xcassets/AppIcon.appiconset"
        
        print("Generating app icons to: \(appIconsetPath)")
        
        // Create the directory if it doesn't exist
        if !fileManager.fileExists(atPath: appIconsetPath) {
            do {
                try fileManager.createDirectory(atPath: appIconsetPath, withIntermediateDirectories: true)
                print("Created directory: \(appIconsetPath)")
            } catch {
                print("Error creating directory: \(error)")
                return
            }
        }
        
        // Generate and save each icon size
        for (filename, size) in sizes {
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                // Set the background color
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Create a UIHostingController to render the SwiftUI view
                let hostingController = UIHostingController(rootView: iconView.frame(width: size.width, height: size.height))
                hostingController.view.frame = CGRect(origin: .zero, size: size)
                hostingController.view.backgroundColor = .clear
                
                // Render the view to the context
                hostingController.view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
            
            // Save the image to the AppIcon.appiconset directory
            let filePath = "\(appIconsetPath)/\(filename)"
            if let data = image.pngData() {
                do {
                    try data.write(to: URL(fileURLWithPath: filePath))
                    print("Generated icon: \(filename)")
                } catch {
                    print("Error saving icon \(filename): \(error)")
                }
            }
        }
        
        print("App icons generated successfully!")
    }
}
