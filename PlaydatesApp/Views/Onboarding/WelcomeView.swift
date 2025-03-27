import SwiftUI

public struct WelcomeView: View {
    private var onGetStarted: () -> Void
    private var onSignIn: () -> Void
    
    // Animation states
    @State private var animateBackground = false
    @State private var animateLogo = false
    @State private var animateTitle = false
    @State private var animateContent = false
    @State private var animateButtons = false
    
    public init(onGetStarted: @escaping () -> Void, onSignIn: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
        self.onSignIn = onSignIn
    }
    
    public var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    ColorTheme.primaryLight.opacity(0.3),
                    ColorTheme.background,
                    ColorTheme.accentLight.opacity(0.2)
                ]),
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .edgesIgnoringSafeArea(.all)
            .animation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
            
            // Decorative elements
            ZStack {
                // Decorative circles
                Circle()
                    .fill(ColorTheme.primaryLight.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .offset(x: -150, y: -300)
                    .blur(radius: 8)
                
                Circle()
                    .fill(ColorTheme.accentLight.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .offset(x: 170, y: -250)
                    .blur(radius: 10)
                
                Circle()
                    .fill(ColorTheme.highlightLight.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .offset(x: -170, y: 350)
                    .blur(radius: 8)
                
                Circle()
                    .fill(ColorTheme.primaryLight.opacity(0.2))
                    .frame(width: 220, height: 220)
                    .offset(x: 150, y: 400)
                    .blur(radius: 10)
            }
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Enhanced logo
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(ColorTheme.primary.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .blur(radius: 15)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [ColorTheme.primary, ColorTheme.primaryDark]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 128, height: 128)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Playdate logo - stylized people icons with colors
                    ZStack {
                        // Adult figures
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 24, height: 24)
                            .offset(x: -18, y: -15)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 24, height: 24)
                            .offset(x: 18, y: -15)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        // Child figure (center, slightly larger)
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [ColorTheme.highlight.opacity(0.9), ColorTheme.highlight]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 30, height: 30)
                            .offset(y: 0)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        // Child figures (smaller)
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [ColorTheme.accent.opacity(0.9), ColorTheme.accent]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 20, height: 20)
                            .offset(x: -24, y: 18)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [ColorTheme.accent.opacity(0.9), ColorTheme.accent]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 20, height: 20)
                            .offset(x: 24, y: 18)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                .scaleEffect(animateLogo ? 1.0 : 0.8)
                .opacity(animateLogo ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateLogo)
                .padding(.bottom, 32)
                
                // Title with shadow and gradient
                Text("Playdates")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [ColorTheme.darkPurple, ColorTheme.primary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    .padding(.bottom, 8)
                    .scaleEffect(animateTitle ? 1.0 : 0.8)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateTitle)
                
                // Tagline with dot separators
                HStack(spacing: 8) {
                    Text("Connect")
                        .foregroundColor(ColorTheme.primary)
                    
                    Circle()
                        .fill(ColorTheme.highlight)
                        .frame(width: 6, height: 6)
                    
                    Text("Play")
                        .foregroundColor(ColorTheme.primary)
                    
                    Circle()
                        .fill(ColorTheme.highlight)
                        .frame(width: 6, height: 6)
                    
                    Text("Explore")
                        .foregroundColor(ColorTheme.primary)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 16)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeIn.delay(0.3), value: animateContent)
                
                // Description with improved styling
                Text("Find and create fun activities for your children in your community")
                    .font(.system(size: 16))
                    .foregroundColor(ColorTheme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeIn.delay(0.4), value: animateContent)
                
                // Enhanced buttons
                VStack(spacing: 16) {
                    Button(action: onGetStarted) {
                        HStack {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [ColorTheme.primary, ColorTheme.primaryDark]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: ColorTheme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.lightText)
                        
                        Button(action: onSignIn) {
                            Text("Sign In")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.primary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .opacity(animateButtons ? 1.0 : 0.0)
                .offset(y: animateButtons ? 0 : 20)
                .animation(.easeInOut.delay(0.5), value: animateButtons)
                
                Spacer()
                
                // Terms with improved styling
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .opacity(animateButtons ? 0.8 : 0.0)
                    .animation(.easeIn.delay(0.6), value: animateButtons)
            }
        }
        .onAppear {
            // Start animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateBackground = true
                animateLogo = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateTitle = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                animateButtons = true
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            onGetStarted: {},
            onSignIn: {}
        )
    }
}
