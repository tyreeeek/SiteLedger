import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showingLogin = false
    @State private var showingSignup = false
    @State private var showingPrivacy = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background (adapts to dark mode)
                LinearGradient(
                    colors: [
                        ModernDesign.Colors.primary.opacity(0.15),
                        ModernDesign.Colors.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // White card in center
                    VStack(spacing: DesignSystem.Spacing.extraLarge) {
                        // Logo + Name
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            SiteLedgerLogoView(.large, showLabel: false)
                            
                            VStack(spacing: DesignSystem.Spacing.small) {
                                Text("SiteLedger")
                                    .font(DesignSystem.TextStyle.title1)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Text("Smart contractor management")
                                    .font(DesignSystem.TextStyle.bodySecondary)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Buttons
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            // Sign In Button
                            Button {
                                HapticsManager.shared.light()
                                showingLogin = true
                            } label: {
                                Text("Sign In")
                                    .font(DesignSystem.TextStyle.buttonLabel)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DesignSystem.Layout.buttonHeight)
                                    .background(ModernDesign.Colors.primary)
                                    .cornerRadius(DesignSystem.Layout.buttonRadius)
                            }
                            
                            // Create Account Button
                            Button {
                                HapticsManager.shared.light()
                                showingSignup = true
                            } label: {
                                Text("Create Account")
                                    .font(DesignSystem.TextStyle.buttonLabel)
                                    .foregroundColor(ModernDesign.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DesignSystem.Layout.buttonHeight)
                                    .background(ModernDesign.Colors.primary.opacity(0.1))
                                    .cornerRadius(DesignSystem.Layout.buttonRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Layout.buttonRadius)
                                            .stroke(ModernDesign.Colors.primary, lineWidth: 1.5)
                                    )
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text("or")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 4)
                            
                            // Apple Sign In Button
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                    request.nonce = UUID().uuidString
                                    request.state = UUID().uuidString
                                },
                                onCompletion: { result in
                                    handleAppleSignIn(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: DesignSystem.Layout.buttonHeight)
                            .cornerRadius(DesignSystem.Layout.buttonRadius)
                        }
                    }
                    .padding(DesignSystem.Spacing.extraLarge)
                    .background(ModernDesign.Colors.cardBackground)
                    .cornerRadius(28)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                    .padding(.horizontal, DesignSystem.Spacing.extraLarge)
                    
                    Spacer()
                    
                    // Privacy link at bottom
                    Button {
                        HapticsManager.shared.light()
                        showingPrivacy = true
                    } label: {
                        Text("Privacy & Terms")
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .padding(.bottom, DesignSystem.Spacing.large)
                }
            }
            .sheet(isPresented: $showingLogin) {
                LoginView(isAuthenticated: .constant(false))
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingSignup) {
                SignupView(isAuthenticated: .constant(false))
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacyPolicyView()
            }
            .alert("Sign-In Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    HapticsManager.shared.light()
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                try await authService.signInWithApple(result)
                HapticsManager.shared.success()
            } catch {
                HapticsManager.shared.error()
                await MainActor.run {
                    // Use the error message already set by AuthService
                    // which includes backend response errors
                    errorMessage = authService.errorMessage ?? error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService())
}
