import SwiftUI

struct ResultsHeaderView: View {
    let title: String
    let showFilter: Bool
    let filterAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.darkPurple)
            
            Spacer()
            
            if showFilter, let filterAction = filterAction {
                Button(action: filterAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.subheadline)
                        Text("Filter")
                            .font(.subheadline)
                    }
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
