import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showingResetPassword = false
    @State private var showingSignup = false
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.extraLarge) {
                        Spacer(minLength: 40)
                        
                        // Logo Section
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            SiteLedgerLogoView(.medium, showLabel: false)
                            
                            Text("Welcome Back")
                                .font(DesignSystem.TextStyle.title1)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Sign in to continue")
                                .font(DesignSystem.TextStyle.bodySecondary)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding(.bottom, DesignSystem.Spacing.medium)
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            InfoBanner(style: .error, message: errorMessage)
                                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        }
                    
                        // Email & Password Section
                        VStack(spacing: DesignSystem.Spacing.standard) {
                            CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                                .autocapitalization(.none)
                                .disabled(authService.isLoading)
                            
                            CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                                .disabled(authService.isLoading)
                            
                            // Sign In Button
                            Button {
                                HapticsManager.shared.medium()
                                signIn()
                            } label: {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(DesignSystem.TextStyle.buttonLabel)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Layout.buttonHeight)
                            .background(DesignSystem.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.Layout.buttonRadius)
                            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                            .opacity(authService.isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                            
                            // Forgot Password
                            Button {
                                HapticsManager.shared.light()
                                showingResetPassword = true
                            } label: {
                                Text("Forgot Password?")
                                    .font(DesignSystem.TextStyle.bodySecondary)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .disabled(authService.isLoading)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.2))
                            Text("OR")
                                .font(DesignSystem.TextStyle.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.2))
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        
                        // Create Account Button
                        Button {
                            HapticsManager.shared.light()
                            showingSignup = true
                        } label: {
                            Text("Create Account")
                                .font(DesignSystem.TextStyle.buttonLabel)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignSystem.Layout.buttonHeight)
                                .background(DesignSystem.Colors.primary.opacity(0.1))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .cornerRadius(DesignSystem.Layout.buttonRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Layout.buttonRadius)
                                        .stroke(DesignSystem.Colors.primary, lineWidth: 1.5)
                                )
                        }
                        .disabled(authService.isLoading)
                        .opacity(authService.isLoading ? 0.6 : 1.0)
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .sheet(isPresented: $showingSignup) {
                SignupView(isAuthenticated: $isAuthenticated)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingResetPassword) {
                ResetPasswordView()
                    .environmentObject(authService)
            }
            .onChange(of: authService.isAuthenticated) {
                isAuthenticated = authService.isAuthenticated
            }
            .onAppear {
                // Clear any previous error messages when returning to login screen
                authService.errorMessage = nil
            }
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                HapticsManager.shared.success()
                email = ""
                password = ""
            } catch {
                HapticsManager.shared.error()
            }
        }
    }
}
