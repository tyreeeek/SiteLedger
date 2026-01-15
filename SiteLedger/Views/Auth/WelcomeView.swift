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
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService())
}
