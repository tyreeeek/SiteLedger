import SwiftUI

struct PrivacySecurityView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    @State private var showingSetPassword = false
    @State private var biometricEnabled = true
    @State private var autoLock = true
    @State private var dataSharing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Security
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Security",
                                    subtitle: "Protect your account"
                                )
                                
                                // Change Password Button
                                Button(action: {
                                    HapticsManager.shared.light()
                                    showingChangePassword = true
                                }) {
                                    HStack(spacing: ModernDesign.Spacing.md) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(ModernDesign.Colors.primary.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "key.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Change Password")
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                            
                                            Text("Update your password")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                }
                                
                                NotificationToggle(
                                    icon: "faceid",
                                    title: "Face ID / Touch ID",
                                    subtitle: "Use biometrics to unlock",
                                    color: ModernDesign.Colors.success,
                                    isOn: $biometricEnabled
                                )
                                
                                NotificationToggle(
                                    icon: "lock.fill",
                                    title: "Auto-Lock",
                                    subtitle: "Lock app when inactive",
                                    color: ModernDesign.Colors.warning,
                                    isOn: $autoLock
                                )
                            }
                        }
                        
                        // Privacy
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Privacy",
                                    subtitle: "Control your data"
                                )
                                
                                NotificationToggle(
                                    icon: "chart.bar.doc.horizontal.fill",
                                    title: "Analytics",
                                    subtitle: "Help us improve the app",
                                    color: ModernDesign.Colors.info,
                                    isOn: $dataSharing
                                )
                                
                                // Export Data
                                Button(action: {
                                    HapticsManager.shared.light()
                                    // Export data action
                                }) {
                                    HStack(spacing: ModernDesign.Spacing.md) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(Color.purple.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "square.and.arrow.up.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color.purple)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Export My Data")
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                            
                                            Text("Download your data")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                        
                        // Danger Zone
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Danger Zone",
                                    subtitle: "Irreversible actions"
                                )
                                
                                Button(action: {
                                    HapticsManager.shared.medium()
                                    showingDeleteAccount = true
                                }) {
                                    HStack(spacing: ModernDesign.Spacing.md) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(ModernDesign.Colors.error.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(ModernDesign.Colors.error)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete Account")
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.error)
                                            
                                            Text("Permanently delete your account")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                }
                            }
                        }
                        
                        // Set Password for Apple users
                        if let user = authService.currentUser, user.isAppleUser, user.hasNoPassword {
                            Button(action: {
                                HapticsManager.shared.light()
                                showingSetPassword = true
                            }) {
                                HStack(spacing: ModernDesign.Spacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                            .fill(ModernDesign.Colors.primary.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "key.badge.plus")
                                            .font(.system(size: 18))
                                            .foregroundColor(ModernDesign.Colors.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Set Password")
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Text("Create a password for your account")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticsManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
            .sheet(isPresented: $showingSetPassword) {
                SetPasswordView()
                    .environmentObject(authService)
            }
            .alert("Delete Account Permanently?", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete:\n\n• Your account (including Apple Sign-In)\n• All jobs and financial data\n• All receipts and timesheets\n• All documents and settings\n\nThis action CANNOT be undone and you will be immediately signed out.")
            }
        }
    }
    
    // MARK: - Account Deletion
    
    private func deleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
                // User is automatically signed out after deletion
            } catch {
                // Error is already handled in AuthService
                print("[PrivacySecurityView] Account deletion failed: \(error.localizedDescription)")
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Info Banner
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(ModernDesign.Colors.info)
                            Text("Choose a strong password with at least 8 characters")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.info)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.info.opacity(0.1))
                        .cornerRadius(ModernDesign.Radius.medium)
                        
                        // Password Fields
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                SecureFieldWithLabel(
                                    label: "Current Password",
                                    placeholder: "Enter current password",
                                    text: $currentPassword
                                )
                                
                                SecureFieldWithLabel(
                                    label: "New Password",
                                    placeholder: "Enter new password",
                                    text: $newPassword
                                )
                                
                                SecureFieldWithLabel(
                                    label: "Confirm Password",
                                    placeholder: "Confirm new password",
                                    text: $confirmPassword
                                )
                            }
                        }
                        
                        // Success Message
                        if showSuccess {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ModernDesign.Colors.success)
                                Text("Password changed successfully!")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.success)
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.success.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        // Error Message
                        if showError {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ModernDesign.Colors.error)
                                Text(errorMessage)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.error)
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.error.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        // Change Password Button
                        ModernButton(
                            title: "Update Password",
                            icon: "key.fill",
                            style: .primary,
                            size: .large,
                            action: changePassword,
                            isLoading: isLoading
                        )
                    }
                    .padding(ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticsManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
        }
    }
    
    private func changePassword() {
        guard !currentPassword.isEmpty else {
            showError(message: "Please enter your current password")
            return
        }
        
        guard newPassword.count >= 8 else {
            showError(message: "New password must be at least 8 characters")
            return
        }
        
        guard newPassword == confirmPassword else {
            showError(message: "Passwords do not match")
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    showSuccess = true
                    
                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(message: String) {
        HapticsManager.shared.error()
        errorMessage = message
        showError = true
    }
}

struct SetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(ModernDesign.Colors.info)
                            Text("Set a password for your account. This allows you to log in with email in the future.")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.info)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.info.opacity(0.1))
                        .cornerRadius(ModernDesign.Radius.medium)
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                SecureFieldWithLabel(
                                    label: "New Password",
                                    placeholder: "Enter new password",
                                    text: $newPassword
                                )
                                SecureFieldWithLabel(
                                    label: "Confirm Password",
                                    placeholder: "Re-enter new password",
                                    text: $confirmPassword
                                )
                                if showError {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                Button(action: setPassword) {
                                    if isLoading {
                                        ProgressView()
                                    } else {
                                        Text("Set Password")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(ModernDesign.Colors.primary)
                                            .cornerRadius(ModernDesign.Radius.medium)
                                    }
                                }
                                .disabled(isLoading)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Set Password")
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Password set successfully. You can now log in with email and password.")
            }
        }
    }
    
    private func setPassword() {
        guard !newPassword.isEmpty, newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        isLoading = true
        showError = false
        Task {
            do {
                let url = URL(string: "https://api.siteledger.ai/api/password/set")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // Use APIService.shared for accessToken
                let apiService = APIService.shared
                var token: String? = nil
                // APIService is an actor, so accessToken must be read via async
                await withCheckedContinuation { continuation in
                    Task {
                        let mirror = Mirror(reflecting: apiService)
                        if let t = mirror.children.first(where: { $0.label == "accessToken" })?.value as? String {
                            token = t
                        }
                        continuation.resume()
                    }
                }
                if let token = token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                let body: [String: String] = ["password": newPassword]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        await MainActor.run {
                            isLoading = false
                            showSuccess = true
                        }
                    } else {
                        let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct SecureFieldWithLabel: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
            Text(label)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            
            HStack(spacing: ModernDesign.Spacing.sm) {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(ModernDesign.Typography.body)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(ModernDesign.Typography.body)
                }
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
            .padding(ModernDesign.Spacing.md)
            .background(ModernDesign.Colors.background)
            .cornerRadius(ModernDesign.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                    .stroke(ModernDesign.Colors.border, lineWidth: 1)
            )
        }
    }
}
