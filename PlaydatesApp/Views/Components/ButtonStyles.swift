import SwiftUI

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity) // Make button expand
            .foregroundColor(Color.white) // Text color
            .background(isEnabled ? ColorTheme.primary : Color.gray.opacity(0.5)) // Use theme color, gray out when disabled
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0) // Subtle press effect
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6) // Dim when disabled
    }
}

// MARK: - Secondary Button Style (Outlined)
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity) // Make button expand
            .foregroundColor(isEnabled ? ColorTheme.primary : Color.gray) // Use theme color for text
            .background(Color.clear) // Transparent background
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEnabled ? ColorTheme.primary : Color.gray.opacity(0.5), lineWidth: 1.5) // Use theme color for border
            )
            .cornerRadius(10) // Ensure corner radius matches overlay
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Text Button Style
struct TextButtonStyle: ButtonStyle {
     @Environment(\.isEnabled) private var isEnabled
     var color: Color = ColorTheme.primary // Default to primary theme color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(isEnabled ? color : Color.gray) // Use specified or default theme color
            .opacity(configuration.isPressed ? 0.7 : 1.0) // Dim slightly on press
            .opacity(isEnabled ? 1.0 : 0.5) // Dim more when disabled
    }
}

// MARK: - Convenience Extension for applying styles
extension Button {
    func primaryStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }

    func secondaryStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }

    func textStyle(color: Color = ColorTheme.primary) -> some View {
        self.buttonStyle(TextButtonStyle(color: color))
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Button("Primary Button") {}
                .primaryStyle()

            Button("Primary Disabled") {}
                .primaryStyle()
                .disabled(true)

            Button("Secondary Button") {}
                .secondaryStyle()

            Button("Secondary Disabled") {}
                .secondaryStyle()
                .disabled(true)

            Button("Text Button (Default)") {}
                .textStyle()
            
            Button("Text Button (Highlight)") {}
                .textStyle(color: ColorTheme.highlight)

            Button("Text Disabled") {}
                .textStyle()
                .disabled(true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
