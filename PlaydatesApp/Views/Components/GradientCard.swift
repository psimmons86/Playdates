import SwiftUI

struct GradientCard<Content: View>: View {
    var content: Content
    var gradientColors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat
    var shadowColor: Color
    var animation: Animation?
    
    @State private var isAnimating = false
    
    init(
        gradientColors: [Color] = [ColorTheme.primary, ColorTheme.primary.opacity(0.8)],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        shadowColor: Color = ColorTheme.primary.opacity(0.3),
        animation: Animation? = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.gradientColors = gradientColors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.animation = animation
    }
    
    var body: some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: isAnimating ? startPoint : endPoint,
                    endPoint: isAnimating ? endPoint : startPoint
                )
            )
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
            .onAppear {
                if let animation = animation {
                    withAnimation(animation) {
                        isAnimating = true
                    }
                }
            }
    }
}

// Convenience extension for standard card styles
extension GradientCard {
    static func primary<Content: View>(@ViewBuilder content: () -> Content) -> GradientCard<Content> {
        GradientCard(
            gradientColors: [ColorTheme.primary, ColorTheme.primary.opacity(0.8)],
            content: content
        )
    }
    
    static func accent<Content: View>(@ViewBuilder content: () -> Content) -> GradientCard<Content> {
        GradientCard(
            gradientColors: [ColorTheme.accent, ColorTheme.accent.opacity(0.8)],
            content: content
        )
    }
    
    static func secondary<Content: View>(@ViewBuilder content: () -> Content) -> GradientCard<Content> {
        GradientCard(
            gradientColors: [ColorTheme.secondary, ColorTheme.secondary.opacity(0.8)],
            content: content
        )
    }
    
    static func colorful<Content: View>(@ViewBuilder content: () -> Content) -> GradientCard<Content> {
        GradientCard(
            gradientColors: [ColorTheme.primary, ColorTheme.accent, ColorTheme.secondary],
            content: content
        )
    }
}

struct GradientCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GradientCard.primary {
                Text("Primary Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(height: 100)
            }
            
            GradientCard.accent {
                Text("Accent Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(height: 100)
            }
            
            GradientCard.secondary {
                Text("Secondary Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(height: 100)
            }
            
            GradientCard.colorful {
                Text("Colorful Card")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(height: 100)
            }
        }
        .padding()
    }
}
