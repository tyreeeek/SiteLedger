import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.extraLarge) {
                VStack(spacing: DesignSystem.Spacing.medium) {
                        SiteLedgerLogoView(.medium, showLabel: false)
                        
                        Text("Create Account")
                            .font(DesignSystem.TextStyle.title1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Join SiteLedger today")
                            .font(DesignSystem.TextStyle.bodySecondary)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: DesignSystem.Spacing.standard) {
                            CustomTextField(placeholder: "Full Name", text: $name)
                                .disabled(isLoading)
                            
                            CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(placeholder: "Password", text: $password, isSecure: true)
                                    .disabled(isLoading)
                                
                                Text("Min 8 characters, uppercase, lowercase, and number")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.leading, DesignSystem.Spacing.small)
                            }
                            
                            CustomTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                                .disabled(isLoading)
                            
                            if showError {
                                InfoBanner(style: .error, message: errorMessage)
                            }
                            
                            // Sign Up Button
                            Button {
                                HapticsManager.shared.medium()
                                signUp()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign Up")
                                        .font(DesignSystem.TextStyle.buttonLabel)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Layout.buttonHeight)
                            .background(DesignSystem.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.Layout.buttonRadius)
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.6 : 1.0)
                            
                            Button {
                                HapticsManager.shared.light()
                                dismiss()
                            } label: {
                                Text("Already have an account? Sign In")
                                    .font(DesignSystem.TextStyle.bodySecondary)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticsManager.shared.light()
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(DesignSystem.TextStyle.bodySecondary)
                    }
                }
            }
            .onChange(of: authService.isAuthenticated) {
                if authService.isAuthenticated {
                    isAuthenticated = authService.isAuthenticated
                    dismiss()
                }
            }
        }
    }
    
    private func signUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        guard password == confirmPassword else {
            HapticsManager.shared.error()
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        guard password.count >= 8 else {
            HapticsManager.shared.error()
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }
        
        // Check password complexity
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasUppercase && hasLowercase && hasNumber else {
            HapticsManager.shared.error()
            errorMessage = "Password must contain uppercase, lowercase, and number"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authService.signUp(email: email, password: password, name: name)
                HapticsManager.shared.success()
            } catch {
                HapticsManager.shared.error()
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
