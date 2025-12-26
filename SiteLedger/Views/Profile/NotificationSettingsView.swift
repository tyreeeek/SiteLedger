import SwiftUI

struct ModernNotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var jobAlerts = true
    @State private var paymentAlerts = true
    @State private var timesheetReminders = true
    @State private var budgetWarnings = true
    @State private var weeklyReports = false
    @State private var marketingEmails = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // General Settings
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "General",
                                    subtitle: "Control how you receive notifications"
                                )
                                
                                NotificationToggle(
                                    icon: "bell.badge.fill",
                                    title: "Push Notifications",
                                    subtitle: "Receive alerts on your device",
                                    color: ModernDesign.Colors.primary,
                                    isOn: $pushEnabled
                                )
                                
                                NotificationToggle(
                                    icon: "envelope.fill",
                                    title: "Email Notifications",
                                    subtitle: "Get updates in your inbox",
                                    color: ModernDesign.Colors.info,
                                    isOn: $emailEnabled
                                )
                            }
                        }
                        
                        // Alert Types
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Alert Types",
                                    subtitle: "Choose which alerts you want"
                                )
                                
                                NotificationToggle(
                                    icon: "briefcase.fill",
                                    title: "Job Alerts",
                                    subtitle: "Status changes and updates",
                                    color: ModernDesign.Colors.accent,
                                    isOn: $jobAlerts
                                )
                                
                                NotificationToggle(
                                    icon: "creditcard.fill",
                                    title: "Payment Alerts",
                                    subtitle: "Payment received notifications",
                                    color: ModernDesign.Colors.success,
                                    isOn: $paymentAlerts
                                )
                                
                                NotificationToggle(
                                    icon: "clock.fill",
                                    title: "Timesheet Reminders",
                                    subtitle: "Clock in/out reminders",
                                    color: ModernDesign.Colors.warning,
                                    isOn: $timesheetReminders
                                )
                                
                                NotificationToggle(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Budget Warnings",
                                    subtitle: "When jobs exceed budget",
                                    color: ModernDesign.Colors.error,
                                    isOn: $budgetWarnings
                                )
                            }
                        }
                        
                        // Other
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Other",
                                    subtitle: "Additional notification options"
                                )
                                
                                NotificationToggle(
                                    icon: "chart.bar.fill",
                                    title: "Weekly Reports",
                                    subtitle: "Get weekly summary emails",
                                    color: Color.purple,
                                    isOn: $weeklyReports
                                )
                                
                                NotificationToggle(
                                    icon: "megaphone.fill",
                                    title: "Marketing Emails",
                                    subtitle: "Tips, features, and updates",
                                    color: ModernDesign.Colors.textSecondary,
                                    isOn: $marketingEmails
                                )
                            }
                        }
                        
                        // Save Button
                        ModernButton(
                            title: "Save Preferences",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .large,
                            action: {
                                HapticsManager.shared.success()
                                dismiss()
                            }
                        )
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationTitle("Notifications")
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
}

struct NotificationToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(subtitle)
                    .font(ModernDesign.Typography.caption)
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(ModernDesign.Colors.primary)
                .labelsHidden()
        }
    }
}
