import SwiftUI

// This file previously contained a duplicate ProfileImageView
// The implementation has been moved to ProfileImageView.swift with iOS 17.0 availability

// MARK: - Rounded Card Component (Moved from GradientCard.swift)

struct RoundedCard<Content: View>: View {
    var content: Content
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var shadowColor: Color
    
    init(
        backgroundColor: Color = ColorTheme.lightBackground, // Default to white
        cornerRadius: CGFloat = 24, // Increased corner radius
        shadowRadius: CGFloat = 5,  // Softer shadow
        shadowColor: Color = Color.black.opacity(0.1), // Softer shadow color
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
    }
    
    var body: some View {
        content
            .background(backgroundColor) // Use solid background color
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
    }
}


// MARK: - Preview Provider

struct SharedComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Shared Components Preview")
            RoundedCard {
                Text("This is inside a RoundedCard")
                    .padding()
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
