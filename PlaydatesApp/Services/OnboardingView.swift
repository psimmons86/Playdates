import SwiftUI

struct OnboardingView: View {
    @State private var currentScreen = 0
    var onComplete: () -> Void
    var onSkip: () -> Void
    
    let screens = [
        OnboardingScreen(
            title: "Find Playdates Near You",
            description: "Discover fun activities and connect with parents in your neighborhood",
            image: "find-playdates"
        ),
        OnboardingScreen(
            title: "Create & Join Activities",
            description: "Organize playdates or join others' events with just a few taps",
            image: "create-activities"
        ),
        OnboardingScreen(
            title: "Connect with Parents",
            description: "Build a community of families with shared interests",
            image: "connect-parents"
        )
    ]
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Illustration
                OnboardingIllustration(type: screens[currentScreen].image)
                    .frame(height: 300)
                    .padding(.bottom, 32)
                
                // Content
                Text(screens[currentScreen].title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.darkPurple)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                
                Text(screens[currentScreen].description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                
                // Pagination dots
                HStack(spacing: 8) {
                    ForEach(0..<screens.count, id: \.self) { index in
                        Circle()
                            .fill(currentScreen == index ? ColorTheme.highlight : ColorTheme.primary.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                
                Spacer()
                
                // Next/Get Started button
                Button(action: {
                    if currentScreen < screens.count - 1 {
                        withAnimation {
                            currentScreen += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentScreen == screens.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentScreen == screens.count - 1 ? ColorTheme.highlight : ColorTheme.primary)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

struct OnboardingScreen {
    let title: String
    let description: String
    let image: String
}

struct OnboardingIllustration: View {
    let type: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 32)
            
            if type == "find-playdates" {
                OnboardingIllustration1()
            } else if type == "create-activities" {
                OnboardingIllustration2()
            } else if type == "connect-parents" {
                OnboardingIllustration3()
            }
        }
    }
}

struct OnboardingIllustration1: View {
    var body: some View {
        ZStack {
            // Location pin
            Circle()
                .fill(ColorTheme.highlight)
                .frame(width: 96, height: 96)
                .offset(x: 60, y: -40)
                .overlay(
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .offset(x: 60, y: -40)
                )
            
            // Person
            Circle()
                .fill(ColorTheme.primary)
                .frame(width: 128, height: 128)
                .offset(x: -40, y: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .offset(x: -40, y: 40)
                )
            
            // Heart
            Circle()
                .fill(ColorTheme.accent)
                .frame(width: 72, height: 72)
                .offset(x: 40, y: 60)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .offset(x: 40, y: 60)
                )
        }
    }
}

struct OnboardingIllustration2: View {
    var body: some View {
        ZStack {
            // Calendar
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.primary)
                .frame(width: 140, height: 140)
                .offset(x: -40, y: -40)
                .overlay(
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .offset(x: -40, y: -40)
                )
            
            // Plus sign
            Circle()
                .fill(ColorTheme.highlight)
                .frame(width: 80, height: 80)
                .offset(x: 60, y: 20)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 60, y: 20)
                )
            
            // People
            Circle()
                .fill(ColorTheme.accent)
                .frame(width: 100, height: 100)
                .offset(x: 0, y: 60)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .offset(x: 0, y: 60)
                )
        }
    }
}

struct OnboardingIllustration3: View {
    var body: some View {
        ZStack {
            // Person 1
            Circle()
                .fill(ColorTheme.primary)
                .frame(width: 110, height: 110)
                .offset(x: -50, y: -20)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .offset(x: -50, y: -20)
                )
            
            // Person 2
            Circle()
                .fill(ColorTheme.highlight)
                .frame(width: 110, height: 110)
                .offset(x: 50, y: -20)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .offset(x: 50, y: -20)
                )
            
            // Chat bubble
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.accent)
                .frame(width: 120, height: 80)
                .offset(x: 0, y: 60)
                .overlay(
                    Image(systemName: "message.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .offset(x: 0, y: 60)
                )
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            onComplete: {},
            onSkip: {}
        )
    }
}
