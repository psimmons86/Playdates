import SwiftUI

struct ExploreErrorView: View {
    let errorMessage: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(ColorTheme.error)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(ColorTheme.darkPurple)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if let retryAction = retryAction {
                Button("Try Again") { // Use simple title init
                    retryAction()
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
