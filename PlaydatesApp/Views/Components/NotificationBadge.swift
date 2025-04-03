import SwiftUI

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        // Only show the badge if the count is greater than 0
        if count > 0 {
            ZStack {
                Circle()
                    .fill(Color.red)
                
                Text("\(count)")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
            // Adjust size based on whether count is > 9 to avoid large circles
            .frame(width: count > 9 ? 22 : 18, height: 18)
            // Add a subtle shadow
            .shadow(radius: 1)
            // Ensure it doesn't break layout if count becomes very large (optional)
            // .fixedSize(horizontal: true, vertical: false)
        } else {
            // If count is 0, show nothing
            EmptyView()
        }
    }
}

// Preview Provider
struct NotificationBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NotificationBadge(count: 0) // No badge
            NotificationBadge(count: 3) // Small badge
            NotificationBadge(count: 15) // Slightly larger badge
            
            // Example usage on a button
            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.title)
                    .padding()
                    .overlay(
                        NotificationBadge(count: 5)
                            .offset(x: 15, y: -10), // Adjust position
                        alignment: .topTrailing
                    )
            }
        }
        .padding()
    }
}
