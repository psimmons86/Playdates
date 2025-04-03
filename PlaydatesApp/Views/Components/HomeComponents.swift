import SwiftUI
import Foundation

// MARK: - Enhanced Home Header
struct EnhancedHomeHeader: View {
    @Binding var isAnimating: Bool // Keep binding, though animation is removed for now
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // Simplified Header wrapped in RoundedCard
        RoundedCard(backgroundColor: ColorTheme.primaryLight.opacity(0.3)) { // Use a subtle background
            HStack {
                VStack(alignment: .leading) {
                    // Removed "Hello Little" text
                    
                    // User greeting (using parent's name)
                    if let user = authViewModel.user {
                        Text(user.name.components(separatedBy: " ").first ?? "User") // Just first name
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                    } else {
                        Text("User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ColorTheme.darkPurple)
                    }
                }
                
                Spacer()
                
                // Notification Bell Icon (Example)
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(ColorTheme.primary)
                    // TODO: Add badge or action if needed
            }
            .padding() // Add padding inside the card
        }
        .padding(.horizontal) // Keep horizontal padding for the card itself
        // Removed complex ZStacks, gradients, animations, and QuickActionButtons
    }
}

// Removed QuickActionButton struct

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
        .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background
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
        // Use RoundedCard as the container
        RoundedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                // Reverted View All button
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
            .padding() // Add padding inside the card
        }
        .padding(.horizontal) // Keep horizontal padding for the card itself
        .padding(.bottom, 16) // Keep bottom padding
        // Removed direct background, cornerRadius, shadow modifiers
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
            
            // Reverted Action button
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
