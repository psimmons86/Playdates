import SwiftUI

// This file previously contained a duplicate ProfileImageView
// The implementation has been moved to ProfileImageView.swift with iOS 17.0 availability

// MARK: - Preview Provider

struct SharedComponents_Previews: PreviewProvider {
    static var previews: some View {
        Text("Shared Components")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
