import SwiftUI

enum OnboardingStep {
    case welcome
    case onboarding
    case childProfileSetup
    case completed
}

struct OnboardingCoordinator: View {
    @State private var currentStep: OnboardingStep = .welcome
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeView(
                    onGetStarted: {
                        withAnimation {
                            currentStep = .onboarding
                        }
                    },
                    onSignIn: {
                        // Navigate to sign in
                        onComplete()
                    }
                )
                
            case .onboarding:
                OnboardingView(
                    onComplete: {
                        withAnimation {
                            currentStep = .childProfileSetup
                        }
                    },
                    onSkip: {
                        withAnimation {
                            currentStep = .childProfileSetup
                        }
                    }
                )
                
            case .childProfileSetup:
                ChildProfileSetupView(
                    onComplete: {
                        withAnimation {
                            currentStep = .completed
                            onComplete()
                        }
                    },
                    onSkip: {
                        withAnimation {
                            currentStep = .completed
                            onComplete()
                        }
                    }
                )
                
            case .completed:
                // This case should immediately trigger onComplete and not be visible
                Color.clear.onAppear {
                    onComplete()
                }
            }
        }
    }
}

struct OnboardingCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCoordinator(onComplete: {})
    }
}
