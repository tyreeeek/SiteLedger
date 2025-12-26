import SwiftUI

/// Privacy Policy view for App Store compliance and user transparency
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    Text("Last Updated: November 27, 2025")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                    
                    // Introduction
                    policySection(
                        title: "Introduction",
                        content: """
                        SiteLedger ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our contractor management mobile application.
                        
                        By using SiteLedger, you agree to the collection and use of information in accordance with this policy.
                        """
                    )
                    
                    // Information We Collect
                    policySection(
                        title: "Information We Collect",
                        content: """
                        We collect the following types of information:
                        
                        • Account Information: Name, email address, phone number, and role (owner or worker)
                        • Job Data: Project details, client information, addresses, notes, and financial data
                        • Location Data: GPS coordinates for timesheet clock-in/out validation (when you use location features)
                        • Photos: Receipt photos and document uploads
                        • Timesheet Data: Work hours, clock-in/out times, and locations
                        • Usage Data: How you interact with the app, features used, and error logs
                        """
                    )
                    
                    // How We Use Your Information
                    policySection(
                        title: "How We Use Your Information",
                        content: """
                        We use your information to:
                        
                        • Provide and maintain the SiteLedger service
                        • Calculate labor costs and project profitability
                        • Validate worker locations during clock-in/out
                        • Process receipt photos with OCR and AI
                        • Send email notifications about jobs and alerts
                        • Generate financial reports and analytics
                        • Improve our service and develop new features
                        • Detect and prevent fraud or unusual activity
                        """
                    )
                    
                    // Location Data
                    policySection(
                        title: "Location Data Collection",
                        content: """
                        We collect precise location data when you:
                        
                        • Clock in or out of a job (to verify you're at the job site)
                        • Enable location validation features
                        
                        Location data is used to:
                        • Validate workers are within 150 meters of job sites during clock-in
                        • Detect if workers move more than 500 meters during their shift
                        • Flag potentially fraudulent timesheet entries
                        
                        You can disable location services in your device settings, but this will prevent location validation features from working.
                        """
                    )
                    
                    // Third-Party Services
                    policySection(
                        title: "Third-Party Services",
                        content: """
                        We use the following third-party services that may collect your information:
                        
                        • DigitalOcean: Cloud hosting and database infrastructure
                        • OCR.space: Receipt photo text extraction
                        • OpenRouter AI: Receipt data parsing and AI features
                        • SendGrid: Email notifications
                        
                        These services have their own privacy policies. We recommend reviewing:
                        • DigitalOcean: https://www.digitalocean.com/legal/privacy-policy
                        • Google Privacy Policy: https://policies.google.com/privacy
                        """
                    )
                    
                    // Data Storage and Security
                    policySection(
                        title: "Data Storage and Security",
                        content: """
                        Your data is stored securely on our cloud servers with:
                        
                        • Encryption in transit (HTTPS/TLS)
                        • Encryption at rest
                        • Role-based access controls
                        • Regular security audits
                        
                        While we implement industry-standard security measures, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security.
                        """
                    )
                    
                    // Data Sharing
                    policySection(
                        title: "Data Sharing and Disclosure",
                        content: """
                        We do NOT sell your personal information.
                        
                        We may share your information with:
                        
                        • Job Owners and Workers: Within your team (job assignments, timesheets, receipts)
                        • Service Providers: DigitalOcean, OCR.space, OpenRouter, SendGrid (to operate the service)
                        • Legal Requirements: If required by law, court order, or government request
                        • Business Transfers: In case of merger, acquisition, or sale of assets
                        """
                    )
                    
                    // Your Rights
                    policySection(
                        title: "Your Privacy Rights",
                        content: """
                        You have the right to:
                        
                        • Access: Request a copy of your personal data
                        • Correction: Update inaccurate or incomplete information
                        • Deletion: Request deletion of your account and data
                        • Portability: Receive your data in a machine-readable format
                        • Opt-Out: Disable location tracking or email notifications
                        • Withdraw Consent: Stop using the app at any time
                        
                        To exercise these rights, contact us at privacy@siteledger.ai
                        
                        Note: Deleting your account will permanently remove all your data and cannot be undone.
                        """
                    )
                    
                    // GDPR and CCPA
                    policySection(
                        title: "GDPR and CCPA Compliance",
                        content: """
                        If you are a resident of the European Union or California, you have additional rights:
                        
                        • GDPR (EU): Right to erasure, data portability, and to lodge complaints with supervisory authorities
                        • CCPA (California): Right to know what data is collected, right to deletion, right to opt-out of data sales (we don't sell data)
                        
                        We process your data based on:
                        • Your consent (when you create an account)
                        • Contract performance (to provide the service)
                        • Legitimate interests (fraud prevention, service improvement)
                        """
                    )
                    
                    // Children's Privacy
                    policySection(
                        title: "Children's Privacy",
                        content: """
                        SiteLedger is not intended for users under 18 years of age. We do not knowingly collect personal information from children under 18.
                        
                        If you believe we have collected information from a child under 18, please contact us immediately at privacy@siteledger.ai
                        """
                    )
                    
                    // Data Retention
                    policySection(
                        title: "Data Retention",
                        content: """
                        We retain your data:
                        
                        • Active accounts: As long as your account is active
                        • Deleted accounts: Up to 90 days for backup and recovery
                        • Legal requirements: Longer if required by law (tax records, etc.)
                        
                        You can request immediate deletion by contacting privacy@siteledger.ai
                        """
                    )
                    
                    // Changes to Privacy Policy
                    policySection(
                        title: "Changes to This Privacy Policy",
                        content: """
                        We may update this Privacy Policy from time to time. We will notify you of changes by:
                        
                        • Posting the new Privacy Policy in the app
                        • Updating the "Last Updated" date
                        • Sending an email notification (for significant changes)
                        
                        Continued use of SiteLedger after changes constitutes acceptance of the updated policy.
                        """
                    )
                    
                    // Contact Information
                    policySection(
                        title: "Contact Us",
                        content: """
                        If you have questions about this Privacy Policy or our practices, contact us:
                        
                        Email: privacy@siteledger.ai
                        Support: support@siteledger.ai
                        
                        For data deletion requests or privacy concerns, please email privacy@siteledger.ai with your account email address.
                        """
                    )
                    
                    // Legal Notice
                    Text("By using SiteLedger, you acknowledge that you have read and understood this Privacy Policy.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 5)
    }
}

#Preview {
    PrivacyPolicyView()
}
