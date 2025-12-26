import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) var dismiss
    let legalType: LegalType
    
    enum LegalType {
        case terms
        case privacy
        
        var title: String {
            switch self {
            case .terms: return "Terms of Service"
            case .privacy: return "Privacy Policy"
            }
        }
        
        var lastUpdated: String {
            return "January 1, 2024"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                        // Last Updated
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Text("Last updated: \(legalType.lastUpdated)")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.cardBackground)
                        .cornerRadius(ModernDesign.Radius.medium)
                        
                        // Content
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
                                if legalType == .terms {
                                    termsContent
                                } else {
                                    privacyContent
                                }
                            }
                        }
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle(legalType.title)
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
    
    var termsContent: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
            LegalSection(
                title: "1. Acceptance of Terms",
                content: "By accessing and using SiteLedger, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this application."
            )
            
            LegalSection(
                title: "2. Use License",
                content: "Permission is granted to temporarily download one copy of SiteLedger for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title."
            )
            
            LegalSection(
                title: "3. Account Responsibilities",
                content: "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account."
            )
            
            LegalSection(
                title: "4. User Data",
                content: "You retain all ownership rights to the data you enter into SiteLedger. We will not share your data with third parties except as required to provide the service or as required by law."
            )
            
            LegalSection(
                title: "5. Service Modifications",
                content: "SiteLedger reserves the right to modify or discontinue, temporarily or permanently, the service with or without notice. We shall not be liable to you or to any third party for any modification, suspension, or discontinuance of the service."
            )
            
            LegalSection(
                title: "6. Limitation of Liability",
                content: "In no event shall SiteLedger or its suppliers be liable for any damages arising out of the use or inability to use the materials on SiteLedger, even if SiteLedger has been notified of the possibility of such damage."
            )
            
            LegalSection(
                title: "7. Governing Law",
                content: "These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that location."
            )
        }
    }
    
    var privacyContent: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.lg) {
            LegalSection(
                title: "1. Information We Collect",
                content: "We collect information you provide directly to us, including your name, email address, and any data you enter into the app such as jobs, receipts, timesheets, and documents."
            )
            
            LegalSection(
                title: "2. How We Use Information",
                content: "We use the information we collect to provide, maintain, and improve our services, to send you technical notices and support messages, and to respond to your comments and questions."
            )
            
            LegalSection(
                title: "3. Data Storage",
                content: "Your data is stored securely on our cloud servers. We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing."
            )
            
            LegalSection(
                title: "4. Location Data",
                content: "When you use our timesheet feature, we may collect GPS location data to verify clock-in locations. This data is only collected when you actively clock in or out and is stored with your timesheet records."
            )
            
            LegalSection(
                title: "5. Data Sharing",
                content: "We do not sell, trade, or otherwise transfer your personal information to outside parties. This does not include trusted third parties who assist us in operating our app, so long as those parties agree to keep this information confidential."
            )
            
            LegalSection(
                title: "6. Your Rights",
                content: "You have the right to access, update, or delete your personal information at any time. You can do this through the app settings or by contacting our support team."
            )
            
            LegalSection(
                title: "7. Data Retention",
                content: "We retain your data for as long as your account is active or as needed to provide you services. If you delete your account, we will delete your personal data within 30 days."
            )
            
            LegalSection(
                title: "8. Contact Us",
                content: "If you have any questions about this Privacy Policy, please contact us at privacy@siteledger.ai."
            )
        }
    }
}

struct LegalSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            Text(title)
                .font(ModernDesign.Typography.labelLarge)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Text(content)
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .lineSpacing(4)
        }
    }
}
