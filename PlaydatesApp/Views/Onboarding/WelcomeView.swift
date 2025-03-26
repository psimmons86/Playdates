import SwiftUI

public struct WelcomeView: View {
    private var onGetStarted: () -> Void
    private var onSignIn: () -> Void
    
    public init(onGetStarted: @escaping () -> Void, onSignIn: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
        self.onSignIn = onSignIn
    }
    
    public var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                ZStack {
                    Circle()
                        .fill(ColorTheme.primary)
                        .frame(width: 128, height: 128)
                    
                    // Playdate logo - stylized people icons
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .offset(x: -18, y: -15)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                            .offset(x: 18, y: -15)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .offset(y: 0)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: -24, y: 18)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: 24, y: 18)
                    }
                }
                .padding(.bottom, 32)
                
                Text("Playdates")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(ColorTheme.darkPurple)
                    .padding(.bottom, 8)
                
                Text("Connect • Play • Explore")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primary)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)
                
                Text("Find and create fun activities for your children in your community")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.primary)
                            .cornerRadius(28)
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
                
                Spacer()
                
                // Terms
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(ColorTheme.lightText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
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
