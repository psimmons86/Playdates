import SwiftUI

struct EnhancedActivityGrid: View {
    let activities: [Activity]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
            ForEach(activities) { activity in
                EnhancedActivityGridCard(activity: activity)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }
}
