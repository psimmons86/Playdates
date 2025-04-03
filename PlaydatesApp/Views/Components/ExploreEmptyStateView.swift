import SwiftUI

struct ExploreEmptyStateView: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // Explicit initializer
    init(message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.lightText)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) { // Use simple title init
                    action()
                }
                .primaryStyle() // Apply primary style
                // Adjust padding if needed
                .padding(.vertical, -4) // Reduce vertical padding slightly
                .fixedSize(horizontal: true, vertical: false) // Prevent stretching full width
            }
        }
        .padding()
    }
}
