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
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(ColorTheme.primary)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
    }
}
