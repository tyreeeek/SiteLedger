import SwiftUI

// MARK: - Modern Profile View (More Tab)
struct ModernProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingResetDataAlert = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showResetSuccess = false
    
    private var isOwner: Bool {
        let role = authService.currentUser?.role
        return role == .owner
    }
    
    private var initials: String {
        let name = authService.currentUser?.name ?? "U"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private var defaultProfileAvatar: some View {
        ZStack {
            Circle()
                .fill(ModernDesign.Colors.primary.opacity(0.15))
                .frame(width: 60, height: 60)
            
            Text(initials)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ModernDesign.Colors.primary)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        ModernDesign.Colors.primary.opacity(0.05),
                        ModernDesign.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        profileHeaderCard
                        
                        if isOwner {
                            ownerMenuSections
                        } else {
                            workerMenuSections
                        }
                        
                        signOutButton
                        
                        Text("SiteLedger v1.0.0")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                            .padding(.bottom, ModernDesign.Spacing.xl)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.md)
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account Permanently?", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete:\n\n• Your account (including Apple Sign-In credentials)\n• All jobs, receipts, and timesheets\n• All documents and worker data\n• All financial records\n\nThis action CANNOT be undone.")
        }
        .alert("Reset All Data", isPresented: $showingResetDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all your jobs, receipts, and timesheets. Your account will remain.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Data Reset Complete", isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All your jobs, receipts, timesheets, and documents have been deleted.")
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
    
    private func deleteAccount() {
        isLoading = true
        Task {
            do {
                try await authService.deleteAccount()
                // AuthService will set isAuthenticated to false, triggering navigation
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func resetAllData() {
        isLoading = true
        Task {
            do {
                try await authService.resetAllData()
                await MainActor.run {
                    isLoading = false
                    showResetSuccess = true
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
    
    private var profileHeaderCard: some View {
        NavigationLink(destination: EditProfileView()) {
            ModernCard(shadow: true) {
                HStack(spacing: ModernDesign.Spacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [ModernDesign.Colors.primary, ModernDesign.Colors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 70, height: 70)
                        
                        if let photoURL = authService.currentUser?.photoURL,
                           let url = URL(string: photoURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                default:
                                    defaultProfileAvatar
                                }
                            }
                        } else {
                            defaultProfileAvatar
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.name ?? "User")
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: isOwner ? "crown.fill" : "person.fill")
                                .font(.system(size: 10))
                            Text(isOwner ? "Owner" : "Worker")
                                .font(ModernDesign.Typography.caption)
                        }
                        .foregroundColor(ModernDesign.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ModernDesign.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var ownerMenuSections: some View {
        MoreMenuSection(title: "COMPANY", icon: "building.2.fill") {
            MoreMenuItem(icon: "building.fill", title: "Company Profile", subtitle: "Business name, timezone, currency", color: .indigo, destination: AnyView(CompanyProfileView()))
        }
        
        MoreMenuSection(title: "TEAM & ACCESS", icon: "person.3.fill") {
            MoreMenuItem(icon: "person.2.fill", title: "Workers", subtitle: "Manage team members", color: .blue, destination: AnyView(WorkersListView()))
            MoreMenuItem(icon: "checkmark.circle.fill", title: "Approve Timesheets", subtitle: "Review & approve hours", color: .orange, destination: AnyView(TimesheetApprovalView()))
            MoreMenuItem(icon: "dollarsign.circle.fill", title: "Payroll", subtitle: "Pay workers & track payments", color: .green, destination: AnyView(WorkerPayrollView()))
            MoreMenuItem(icon: "shield.lefthalf.filled", title: "Roles & Permissions", subtitle: "Control who sees what", color: .purple, destination: AnyView(RolesPermissionsView()))
            MoreMenuItem(icon: "clock.fill", title: "All Workers' Hours", subtitle: "View all timesheets", color: .cyan, destination: AnyView(AllTimesheetsView()))
        }
        
        MoreMenuSection(title: "AI & AUTOMATION", icon: "cpu.fill") {
            MoreMenuItem(icon: "wand.and.stars", title: "AI Automation", subtitle: "Manual, Assist, or Auto-Pilot", color: .cyan, destination: AnyView(AIAutomationSettingsView()))
            MoreMenuItem(icon: "slider.horizontal.3", title: "AI Thresholds", subtitle: "Confidence & alert settings", color: .teal, destination: AnyView(AIThresholdsView()))
            MoreMenuItem(icon: "lightbulb.fill", title: "AI Insights", subtitle: "View recommendations", color: .yellow, destination: AnyView(AIInsightsView()))
        }
        
        MoreMenuSection(title: "DATA & STORAGE", icon: "externaldrive.fill") {
            MoreMenuItem(icon: "clock.arrow.circlepath", title: "Data Retention", subtitle: "How long to keep data", color: .green, destination: AnyView(DataRetentionView()))
            MoreMenuItem(icon: "square.and.arrow.up", title: "Export Data", subtitle: "Download your data", color: .mint, destination: AnyView(ExportDataView()))
        }
        
        MoreMenuSection(title: "APP BEHAVIOR", icon: "gearshape.fill") {
            MoreMenuItem(icon: "lock.fill", title: "Account Settings", subtitle: "Password & security", color: .blue, destination: AnyView(AccountSettingsView()))
            MoreMenuItem(icon: "bell.fill", title: "Smart Notifications", subtitle: "Alert rules & preferences", color: .red, destination: AnyView(SmartNotificationsView()))
            MoreMenuItem(icon: "paintbrush.fill", title: "Appearance", subtitle: "Theme & display settings", color: .pink, destination: AnyView(AppearanceSettingsView()))
        }
        
        MoreMenuSection(title: "INTEGRATIONS", icon: "link.circle.fill") {
            MoreMenuItem(icon: "chart.bar.doc.horizontal", title: "Accounting", subtitle: "QuickBooks, Xero (Coming Soon)", color: .green, destination: AnyView(IntegrationsView()))
            MoreMenuItem(icon: "calendar", title: "Calendar", subtitle: "Google, Apple Calendar", color: .red, destination: AnyView(CalendarIntegrationView()))
        }
        
        MoreMenuSection(title: "HELP & LEGAL", icon: "questionmark.circle.fill") {
            MoreMenuItem(icon: "book.fill", title: "FAQ / Help", subtitle: "Common questions", color: .blue, destination: AnyView(FAQView()))
            MoreMenuItem(icon: "envelope.fill", title: "Contact Support", subtitle: "Get help from our team", color: .indigo, destination: AnyView(SupportView()))
            MoreMenuItem(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "How we protect your data", color: .gray, destination: AnyView(MorePrivacyPolicyView()))
            MoreMenuItem(icon: "doc.text.fill", title: "Terms of Service", subtitle: "Usage agreement", color: .gray, destination: AnyView(MoreTermsOfServiceView()))
        }
        
        dangerZoneSection
    }
    
    @ViewBuilder
    private var workerMenuSections: some View {
        // Quick Actions for Workers
        MoreMenuSection(title: "QUICK ACTIONS", icon: "bolt.fill") {
            MoreMenuItem(icon: "doc.text.image", title: "Add Receipt", subtitle: "Submit expense receipts", color: .green, destination: AnyView(ModernAddReceiptView()))
        }
        
        MoreMenuSection(title: "SETTINGS", icon: "gearshape.fill") {
            MoreMenuItem(icon: "lock.fill", title: "Account Settings", subtitle: "Password & security", color: .blue, destination: AnyView(AccountSettingsView()))
            MoreMenuItem(icon: "bell.fill", title: "Notifications", subtitle: "Alert preferences", color: .red, destination: AnyView(NotificationSettingsView()))
            MoreMenuItem(icon: "paintbrush.fill", title: "Appearance", subtitle: "Theme & display settings", color: .pink, destination: AnyView(AppearanceSettingsView()))
        }
        
        MoreMenuSection(title: "HELP & LEGAL", icon: "questionmark.circle.fill") {
            MoreMenuItem(icon: "book.fill", title: "FAQ / Help", subtitle: "Common questions", color: .blue, destination: AnyView(FAQView()))
            MoreMenuItem(icon: "envelope.fill", title: "Contact Support", subtitle: "Get help from our team", color: .indigo, destination: AnyView(SupportView()))
        }
        
        workerDangerZoneSection
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            HStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                Text("DANGER ZONE")
                    .font(ModernDesign.Typography.captionSmall)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, ModernDesign.Spacing.sm)
            .padding(.top, ModernDesign.Spacing.md)
            
            ModernCard(shadow: true) {
                VStack(spacing: 0) {
                    Button(action: { showingResetDataAlert = true }) {
                        DangerRow(icon: "arrow.counterclockwise", title: "Reset All Data", subtitle: "Delete all jobs, receipts, timesheets", color: .orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider().padding(.leading, 56)
                    
                    Button(action: { showingDeleteAccountAlert = true }) {
                        DangerRow(icon: "trash.fill", title: "Delete Account", subtitle: "Permanently remove everything", color: .red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var workerDangerZoneSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            HStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 12))
                Text("DANGER ZONE")
                    .font(ModernDesign.Typography.captionSmall)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, ModernDesign.Spacing.sm)
            .padding(.top, ModernDesign.Spacing.md)
            
            ModernCard(shadow: true) {
                Button(action: { showingDeleteAccountAlert = true }) {
                    DangerRow(icon: "trash.fill", title: "Delete Account", subtitle: "Permanently remove your account", color: .red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            HapticsManager.shared.warning()
            showingSignOutAlert = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(ModernDesign.Typography.label)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1))
            .cornerRadius(ModernDesign.Radius.large)
        }
        .padding(.top, ModernDesign.Spacing.md)
    }
}

struct DangerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(color == .red ? .red : ModernDesign.Colors.textPrimary)
                Text(subtitle)
                    .font(ModernDesign.Typography.caption)
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, ModernDesign.Spacing.sm)
    }
}

struct MoreMenuSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            HStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .font(.system(size: 12))
                Text(title)
                    .font(ModernDesign.Typography.captionSmall)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            .padding(.horizontal, ModernDesign.Spacing.sm)
            
            ModernCard(shadow: true) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct MoreMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
            .padding(.vertical, ModernDesign.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MorePrivacyPolicyView: View {
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            Text("Privacy Policy")
                                .font(ModernDesign.Typography.title2)
                            Text("Last updated: January 2025")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Divider()
                            PolicySection(title: "Data Collection", content: "SiteLedger collects information you provide directly, including your name, email, company details, job information, receipts, and timesheets.")
                            PolicySection(title: "Data Storage", content: "Your data is securely stored on our cloud infrastructure with encryption at rest and in transit.")
                            PolicySection(title: "AI Processing", content: "Receipt images are processed by AI to extract text. This data is used only for your benefit and is not shared.")
                            PolicySection(title: "Your Rights", content: "You can export or delete your data at any time from the Settings menu.")
                        }
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Text("View Full Privacy Policy")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(ModernDesign.Colors.primary)
                    }
                    .padding(.horizontal)
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct MoreTermsOfServiceView: View {
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            Text("Terms of Service")
                                .font(ModernDesign.Typography.title2)
                            Text("Last updated: January 2025")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Divider()
                            PolicySection(title: "Acceptance", content: "By using SiteLedger, you agree to these Terms of Service.")
                            PolicySection(title: "Use of Service", content: "SiteLedger is a business management tool. You are responsible for maintaining account confidentiality.")
                            PolicySection(title: "AI Features", content: "AI features provide suggestions. You are responsible for reviewing AI-generated content.")
                            PolicySection(title: "Termination", content: "You may delete your account at any time.")
                        }
                    }
                    
                    // Full terms are shown above - no external link needed
                    Text("For questions, contact support@siteledger.ai")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .padding(.horizontal)
                }
                .padding(ModernDesign.Spacing.lg)
            }
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(ModernDesign.Typography.label)
            Text(content)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModernProfileView()
        .environmentObject(AuthService())
}
