import SwiftUI
import Foundation

// MARK: - Enhanced Home Header
struct EnhancedHomeHeader: View {
    @Binding var isAnimating: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        ColorTheme.primary,
                        ColorTheme.accent,
                        ColorTheme.highlight
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Overlay gradient for depth
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Subtle pattern overlay
                ZStack {
                    ForEach(0..<20) { i in
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 20, height: 20)
                            .offset(
                                x: CGFloat.random(in: -150...150),
                                y: CGFloat.random(in: -80...80)
                            )
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal)
            
            // Decorative elements
            ZStack {
                // Floating circles
                HStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .offset(x: isAnimating ? 0 : -10, y: isAnimating ? 0 : 5)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .offset(x: -80, y: -60)
                
                // Floating stars
                ForEach(0..<3) { i in
                    Image(systemName: "star.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: 20 + CGFloat(i * 5)))
                        .offset(
                            x: CGFloat([70, -60, 40][i]),
                            y: CGFloat([-40, 60, 20][i])
                        )
                        .rotationEffect(.degrees(isAnimating ? 30 : -30))
                        .animation(
                            Animation.easeInOut(duration: 3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.3),
                            value: isAnimating
                        )
                }
                
                // Floating shapes
                ForEach(0..<2) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(isAnimating ? 45 : 0))
                        .offset(
                            x: CGFloat([90, -90][i]),
                            y: CGFloat([30, -50][i])
                        )
                        .animation(
                            Animation.easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.5),
                            value: isAnimating
                        )
                }
            }
            
            // Welcome content
            VStack(alignment: .leading, spacing: 12) {
                // User greeting
                if let user = authViewModel.user {
                    Text("Hello, \(user.name.components(separatedBy: " ").first ?? "there")!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("Hello there!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("Let's find fun activities for your kids")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                // Quick action buttons
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "plus",
                        title: "New Playdate",
                        action: {
                            // Create playdate
                        }
                    )
                    
                    QuickActionButton(
                        icon: "magnifyingglass",
                        title: "Find Activities",
                        action: {
                            // Find activities
                        }
                    )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 100, height: 80)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ColorTheme.primary : ColorTheme.primary.opacity(0.1))
                .foregroundColor(isSelected ? .white : ColorTheme.primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Section Box
struct SectionBox<Content: View>: View {
    let title: String
    let viewAllAction: (() -> Void)?
    let content: Content
    
    init(title: String, viewAllAction: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.viewAllAction = viewAllAction
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                if let viewAllAction = viewAllAction {
                    Button(action: viewAllAction) {
                        Text("View All")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.primary)
                    }
                }
            }
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

// MARK: - Empty State Box
struct EmptyStateBox: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(ColorTheme.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(ColorTheme.primary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(ColorTheme.darkPurple)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(ColorTheme.lightText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                        
                        Text(buttonTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(ColorTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: ColorTheme.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
