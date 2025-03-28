import SwiftUI

struct EnhancedActivityList: View {
    let activities: [Activity]
    var title: String? = nil
    var showFilter: Bool = false
    var filterAction: (() -> Void)? = nil
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(ColorTheme.text)
                    
                    Spacer()
                    
                    if showFilter && filterAction != nil {
                        Button(action: { filterAction?() }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(ColorTheme.primary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            
            ForEach(activities) { activity in
                EnhancedActivityListCard(activity: activity)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }
}
