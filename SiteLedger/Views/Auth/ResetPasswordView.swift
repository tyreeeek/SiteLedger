import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateIcon = false
    @State private var resetToken: String? = nil
    @State private var showTokenSheet = false
    @State private var showConfirmView = false
    
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
                        
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(accentColor)
                            .rotationEffect(.degrees(animateIcon ? 5 : -5))
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateIcon)
                    }
                    .onAppear { animateIcon = true }
                    
                    // Title & subtitle
                    VStack(spacing: 10) {
                        Text("Forgot Password?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                        
                        Text("No worries! Enter your email and we'll send you a reset link.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(gradientColors[0])
                                .font(.system(size: 18))
                            
                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 16))
                        }
                        .padding(16)
                        .background(Color(red: 0.95, green: 0.97, blue: 0.98))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(gradientColors[0].opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 4)
                    
                    // Status messages
                    if showSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Reset link sent! Check your email.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(accentColor)
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(accentColor.opacity(0.1))
                        .cornerRadius(10)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Send button
                    Button(action: resetPassword) {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isLoading ? "Sending..." : "Send Reset Link")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [gradientColors[0], gradientColors[1]]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: gradientColors[0].opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading || email.isEmpty)
                    .opacity(email.isEmpty ? 0.7 : 1.0)
                    
                    // Back to login
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back to Login")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(gradientColors[0])
                    }
                    .padding(.top, 8)
                }
                .padding(28)
                .background(cardBackground)
                .cornerRadius(28)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                Text("We'll send you an email with instructions")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 30)
            }
        }
        .animation(.spring(response: 0.4), value: showSuccess)
        .animation(.spring(response: 0.4), value: showError)
        .sheet(isPresented: $showTokenSheet) {
            DevResetTokenView(token: resetToken ?? "", email: email) {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $showConfirmView) {
            ConfirmPasswordResetView(email: email)
                .environmentObject(authService)
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            withAnimation { showError = true }
            return
        }
        
        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
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
                let response = try await authService.resetPassword(email: email)
                await MainActor.run {
                    withAnimation { showSuccess = true }
                    HapticsManager.shared.success()
                    
                    // If development token is returned, show it
                    if let token = response.resetToken {
                        resetToken = token
                        showTokenSheet = true
                    }
                }
                
                // Wait a moment to show success message
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                // Show confirm view to enter token and new password
                await MainActor.run { 
                    showConfirmView = true 
                }
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

// MARK: - Development Token Display
struct DevResetTokenView: View {
    let token: String
    let email: String
    let onDismiss: () -> Void
    @State private var copied = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.95, green: 0.97, blue: 0.98).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.top, 30)
                        
                        // Title
                        VStack(spacing: 8) {
                            Text("Development Mode")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Reset Token Generated")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Info card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text(email)
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.orange)
                                    Text("Reset Token:")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(token)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                // Copy button
                                Button {
                                    UIPasteboard.general.string = token
                                    copied = true
                                    HapticsManager.shared.success()
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copied = false
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                        Text(copied ? "Copied!" : "Copy Token")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(copied ? Color.green : Color.blue)
                                    .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            
                            // Instructions
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Instructions")
                                        .font(.subheadline.bold())
                                }
                                
                                Text("1. Copy the reset token above\n2. Save it securely\n3. Valid for 1 hour\n4. Use it to reset your password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Warning
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Development Only")
                                        .font(.subheadline.bold())
                                }
                                
                                Text("In production, this would be sent via email. Tokens are never displayed to users in production.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Done button
                        Button {
                            onDismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.0, green: 0.6, blue: 0.7))
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AuthService.shared)
}
