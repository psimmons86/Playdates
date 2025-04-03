import SwiftUI

enum AuthViewMode {
    case signIn
    case signUp
    case resetPassword
}

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var mode: AuthViewMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                ColorTheme.background.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    // Logo and app name
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ColorTheme.primary)
                                .frame(width: 80, height: 80)
                            
                            // Playdate logo - stylized people icons
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                                    .offset(x: -12, y: -10)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                                    .offset(x: 12, y: -10)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                                    .offset(y: 0)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .offset(x: -16, y: 12)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .offset(x: 16, y: 12)
                            }
                        }

                        Text("Playdates")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(ColorTheme.darkPurple)

                        Text("Connect • Play • Explore")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(ColorTheme.lightText)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 20)

                    // Title for current mode
                    Text(modeTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ColorTheme.darkPurple)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 24)

                    // Form fields
                    VStack(spacing: 16) {
                        if mode == .signUp {
                            // Name field (only for sign up)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.darkPurple)
                                
                                TextField("Enter your name", text: $name)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }

                        if mode != .resetPassword {
                            // Password field (not for reset password)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.darkPurple)
                                
                                SecureField("Enter your password", text: $password)
                                    .textContentType(mode == .signUp ? .newPassword : .password)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            if mode == .signUp {
                                // Confirm password field (only for sign up)
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(ColorTheme.darkPurple)
                                    
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)

                    // Error message
                    if let error = authViewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(ColorTheme.error)
                            .padding(.bottom, 16)
                    }

                    // Primary action button
                    Button(action: performAction) {
                        // Label now just contains the text or progress view
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                // Ensure ProgressView doesn't overly expand the button height
                                .frame(height: 20) // Match approx text height
                        } else {
                            Text(actionButtonTitle)
                        }
                    }
                    .primaryStyle() // Apply the primary button style
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .padding(.bottom, 24)

                    // Secondary actions
                    VStack(spacing: 20) {
                        switch mode {
                        case .signIn:
                            Button("Forgot Password?") { mode = .resetPassword }
                                .textStyle() // Apply text button style

                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)

                                Button("Sign Up") { mode = .signUp }
                                    .textStyle() // Apply text button style
                                    .fontWeight(.bold) // Keep bold for emphasis if needed
                            }

                        case .signUp:
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.lightText)

                                Button("Sign In") { mode = .signIn }
                                    .textStyle() // Apply text button style
                                    .fontWeight(.bold) // Keep bold for emphasis if needed
                            }

                        case .resetPassword:
                            Button("Back to Sign In") { mode = .signIn }
                                .textStyle() // Apply text button style
                                .fontWeight(.bold) // Keep bold for emphasis if needed
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 50)
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .signIn:
            return "Sign In"
        case .signUp:
            return "Sign Up"
        case .resetPassword:
            return "Reset Password"
        }
    }

    private var actionButtonTitle: String {
        switch mode {
        case .signIn:
            return "Sign In"
        case .signUp:
            return "Sign Up"
        case .resetPassword:
            return "Reset Password"
        }
    }

    private var isFormValid: Bool {
        switch mode {
        case .signIn:
            return !email.isEmpty && !password.isEmpty
        case .signUp:
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
        case .resetPassword:
            return !email.isEmpty
        }
    }

    private func performAction() {
        switch mode {
        case .signIn:
            signIn()
        case .signUp:
            signUp()
        case .resetPassword:
            resetPassword()
        }
    }

    private func signIn() {
        // Use the completion handler pattern instead of async/await
        authViewModel.signIn(email: email, password: password)
    }

    private func signUp() {
        guard password == confirmPassword else {
            authViewModel.error = "Passwords do not match"
            return
        }

        // Use the completion handler pattern instead of async/await
        authViewModel.signUp(name: name, email: email, password: password)
    }

    private func resetPassword() {
        authViewModel.resetPassword(email: email) { success in
            alertTitle = success ? "Success" : "Error"
            alertMessage = success ? "Password reset instructions have been sent to your email." : "Failed to send password reset email. Please try again."
            showAlert = true

            if success {
                mode = .signIn
            }
        }
    }
}
