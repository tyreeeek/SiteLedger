import SwiftUI

struct ConfirmPasswordResetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var token = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateIcon = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    let email: String
    
    // Fresh color palette - Teal & Coral accent
    private let gradientColors = [
        Color(red: 0.0, green: 0.6, blue: 0.7),  // Teal
        Color(red: 0.0, green: 0.5, blue: 0.6)   // Darker teal
    ]
    private let accentColor = Color(red: 1.0, green: 0.45, blue: 0.4) // Coral
    private let cardBackground = Color(red: 0.98, green: 0.98, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: -50)
                
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 200)
            }
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Main card
                VStack(spacing: 28) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(accentColor.opacity(0.25))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(accentColor)
                            .rotationEffect(.degrees(animateIcon ? 5 : -5))
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
                    }
                    .onAppear { animateIcon = true }
                    
                    // Title & subtitle
                    VStack(spacing: 10) {
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                        
                        Text("Enter the reset code from your email and choose a new password.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Email display
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    // Token input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Code")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(width: 20)
                            
                            TextField("Enter code from email", text: $token)
                                .font(.system(size: 16, design: .monospaced))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.asciiCapable)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // New password input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(width: 20)
                            
                            if showPassword {
                                TextField("Min. 6 characters", text: $newPassword)
                                    .font(.system(size: 16))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Min. 6 characters", text: $newPassword)
                                    .font(.system(size: 16))
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Confirm password input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .frame(width: 20)
                            
                            if showConfirmPassword {
                                TextField("Re-enter password", text: $confirmPassword)
                                    .font(.system(size: 16))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Re-enter password", text: $confirmPassword)
                                    .font(.system(size: 16))
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Reset button
                    Button(action: confirmReset) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Reset Password")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.45, blue: 0.4),
                                    Color(red: 1.0, green: 0.35, blue: 0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoading || token.isEmpty || newPassword.isEmpty)
                    .opacity((isLoading || token.isEmpty || newPassword.isEmpty) ? 0.6 : 1)
                    
                    // Success/Error messages
                    if showSuccess {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Password reset successfully!")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if showError {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.vertical, 32)
                .background(cardBackground)
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    private func confirmReset() {
        guard !token.isEmpty else {
            errorMessage = "Please enter the reset code"
            withAnimation { showError = true }
            return
        }
        
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            withAnimation { showError = true }
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            withAnimation { showError = true }
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match"
            withAnimation { showError = true }
            return
        }
        
        isLoading = true
        withAnimation {
            showError = false
            showSuccess = false
        }
        
        Task {
            do {
                try await authService.confirmResetPassword(token: token, newPassword: newPassword)
                await MainActor.run {
                    withAnimation { showSuccess = true }
                    HapticsManager.shared.success()
                }
                
                // Dismiss after showing success
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    withAnimation { showError = true }
                    HapticsManager.shared.error()
                }
            }
            await MainActor.run { isLoading = false }
        }
    }
}
