import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSignOutAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Profile Header Card
                    ModernCard(shadow: true) {
                        VStack(spacing: ModernDesign.Spacing.lg) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [ModernDesign.Colors.primary, ModernDesign.Colors.primary.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Text(initials)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: ModernDesign.Spacing.xs) {
                                Text(authService.currentUser?.name ?? "User")
                                    .font(ModernDesign.Typography.title2)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                    .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                
                                Text(authService.currentUser?.email ?? "")
                                    .font(ModernDesign.Typography.bodySmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                    .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                
                                if let createdAt = authService.currentUser?.createdAt {
                                    Text("Member since \(createdAt.formatted(.dateTime.month(.abbreviated).year()))")
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                        .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                                }
                            }
                            
                            // Edit Profile Button
                            ModernButton(
                                title: "Edit Profile",
                                icon: "pencil",
                                style: .outline,
                                size: .medium,
                                action: { showingEditProfile = true }
                            )
                        }
                        .padding(.vertical, ModernDesign.Spacing.md)
                    }
                    
                    // Settings Section
                    ModernCard(shadow: true) {
                        VStack(spacing: 0) {
                            ModernSectionHeader(title: "Settings")
                                .padding(.bottom, ModernDesign.Spacing.md)
                            
                            NavigationLink(destination: SettingsView()) {
                                ProfileMenuRow(
                                    icon: "gearshape.fill",
                                    title: "General Settings",
                                    iconColor: ModernDesign.Colors.info
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ProfileDivider()
                            
                            NavigationLink(destination: NotificationSettingsView()) {
                                ProfileMenuRow(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    iconColor: Color.pink
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ProfileDivider()
                            
                            NavigationLink(destination: HelpSupportView()) {
                                ProfileMenuRow(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    iconColor: Color.purple
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Legal Section
                    ModernCard(shadow: true) {
                        VStack(spacing: 0) {
                            ModernSectionHeader(title: "Legal")
                                .padding(.bottom, ModernDesign.Spacing.md)
                            
                            NavigationLink(destination: LegalView(legalType: .terms)) {
                                ProfileMenuRow(
                                    icon: "doc.text.fill",
                                    title: "Terms of Service",
                                    iconColor: ModernDesign.Colors.textSecondary
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ProfileDivider()
                            
                            NavigationLink(destination: LegalView(legalType: .privacy)) {
                                ProfileMenuRow(
                                    icon: "hand.raised.fill",
                                    title: "Privacy Policy",
                                    iconColor: ModernDesign.Colors.success
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Sign Out Button
                    ModernButton(
                        title: "Sign Out",
                        icon: "arrow.right.square.fill",
                        style: .danger,
                        size: .large,
                        action: {
                            HapticsManager.shared.medium()
                            showingSignOutAlert = true
                        }
                    )
                    
                    // Version Info
                    Text("Version 1.0.0")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                        .padding(.top, ModernDesign.Spacing.sm)
                }
                .padding(ModernDesign.Spacing.lg)
                .padding(.bottom, ModernDesign.Spacing.xxxl)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authService)
        }
        .alert("Sign Out?", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {
                HapticsManager.shared.light()
            }
            Button("Sign Out", role: .destructive) {
                HapticsManager.shared.medium()
                authService.signOut()
            }
        } message: {
            Text("You will need to sign in again to access your account.")
        }
    }
    
    var initials: String {
        guard let name = authService.currentUser?.name else { return "?" }
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ModernDesign.Colors.textTertiary)
        }
        .padding(.vertical, ModernDesign.Spacing.sm)
    }
}

struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(ModernDesign.Colors.border)
            .frame(height: 1)
            .padding(.leading, 52)
    }
}
