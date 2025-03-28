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
                Button(action: retryAction) {
                    Text("Try Again")
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
