import SwiftUI

// MARK: - Card Components
struct CardView<Content: View>: View {
    let content: Content
    var backgroundColor: Color = AppTheme.cardBackground
    var padding: CGFloat = DesignSystem.Spacing.cardPadding
    
    init(
        backgroundColor: Color = AppTheme.cardBackground,
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String?
    
    var body: some View {
        CardView {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text(title)
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)
                        .fontWeight(.semibold)
                    
                    Text(value)
                        .font(DesignSystem.TextStyle.title2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.TextStyle.tiny)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color.opacity(0.8))
            }
        }
    }
}

struct FinancialCard: View {
    let title: String
    let amount: Double
    let icon: String
    let type: FinancialType
    var isLarge: Bool = false
    
    enum FinancialType {
        case projectValue, laborCost, profit, balance, receipts
        
        var color: Color {
            switch self {
            case .projectValue: return AppTheme.primaryColor
            case .laborCost: return AppTheme.warningColor
            case .profit: return AppTheme.successColor
            case .balance: return AppTheme.accentColor
            case .receipts: return AppTheme.secondaryColor
            }
        }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack {
                    Text(title)
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: icon)
                        .foregroundColor(type.color)
                }
                
                Text(String(format: "$%.2f", amount))
                    .font(isLarge ? DesignSystem.TextStyle.title1 : DesignSystem.TextStyle.title2)
                    .fontWeight(.bold)
                    .foregroundColor(type.color)
            }
        }
    }
}

// MARK: - Button Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String?
    
    var body: some View {
        Button(action: {
            print("🔘 PrimaryButton tapped: '\(title)'")
            HapticsManager.shared.medium()
            print("🔘 Calling action closure...")
            action()
            print("🔘 Action closure completed")
        }) {
            HStack(spacing: DesignSystem.Spacing.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            .background(isDisabled ? AppTheme.textSecondary.opacity(0.3) : AppTheme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .disabled(isLoading || isDisabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String?
    var color: Color = AppTheme.primaryColor
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.light()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct TertiaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String?
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(AppTheme.primaryColor)
        }
    }
}

// MARK: - Input Components
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var showPassword: Bool = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Group {
                if isSecure && !showPassword {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .foregroundColor(AppTheme.textPrimary)
            
            // Show/Hide password toggle
            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.backgroundColor)
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(AppTheme.borderColor, lineWidth: 1)
        )
    }
}

struct CurrencyField: View {
    let label: String
    @Binding var amount: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(label)
                .font(DesignSystem.TextStyle.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fontWeight(.semibold)
                .textCase(.uppercase)
            
            HStack(spacing: DesignSystem.Spacing.small) {
                Text("$")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fontWeight(.semibold)
                
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(AppTheme.backgroundColor)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Status & Badge Components
struct AlertBadge: View {
    enum Severity {
        case info, warning, critical
        
        var color: Color {
            switch self {
            case .info: return AppTheme.infoColor
            case .warning: return AppTheme.warningColor
            case .critical: return AppTheme.errorColor
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.circle"
            case .critical: return "xmark.circle"
            }
        }
    }
    
    let severity: Severity
    let message: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Image(systemName: severity.icon)
                .foregroundColor(severity.color)
            
            Text(message)
                .font(DesignSystem.TextStyle.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(severity.color.opacity(0.1))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

// MARK: - List & Row Components
struct ListItemRow: View {
    let title: String
    let subtitle: String?
    let value: String?
    let icon: String?
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AppTheme.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}

// MARK: - Loading & Empty States
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ProgressView()
            Text("Loading...")
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let buttonTitle: String?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let buttonTitle = buttonTitle {
                PrimaryButton(title: buttonTitle, action: action)
                    .padding(.top, DesignSystem.Spacing.medium)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
    }
}

// MARK: - Header Components
struct ScreenHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionIcon: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if let action = action, let icon = actionIcon {
                    Button(action: action) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: Job.JobStatus
    
    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return AppTheme.successColor
        case .completed:
            return AppTheme.primaryColor
        case .onHold:
            return AppTheme.errorColor
        }
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.accentColor)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Menu Item
struct MoreMenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 32, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
}

// MARK: - Timesheet Card
struct TimesheetCard: View {
    let timesheet: Timesheet
    let workerName: String?
    let jobName: String?
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Header with status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workerName ?? "Unknown Worker")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(jobName ?? "Unknown Job")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    statusBadge
                }
                
                Divider()
                    .background(AppTheme.borderColor)
                
                // Time details
                HStack(spacing: DesignSystem.Spacing.large) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clock In")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if let clockIn = timesheet.clockIn {
                            Text(clockIn.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        } else {
                            Text("--:--")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clock Out")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if let clockOut = timesheet.clockOut {
                            Text(clockOut.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        } else {
                            Text("Active")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.successColor)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(String(format: "%.2f h", timesheet.hoursWorked))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
                
                // AI Flags if present
                if let flags = timesheet.aiFlags, !flags.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flags")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 4) {
                            ForEach(flags.prefix(2), id: \.self) { flag in
                                Text(flag.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.warningColor.opacity(0.1))
                                    .foregroundColor(AppTheme.warningColor)
                                    .cornerRadius(4)
                            }
                            
                            if flags.count > 2 {
                                Text("+\(flags.count - 2)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                
                // Notes if present
                if !(timesheet.notes ?? "").isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .textCase(.uppercase)
                        
                        Text(timesheet.notes ?? "")
                            .font(.caption)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .semibold))
            
            Text((timesheet.status ?? "unknown").capitalized)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch timesheet.status {
        case "working", "active":
            return AppTheme.successColor
        case "completed", "approved":
            return AppTheme.primaryColor
        case "flagged", "rejected":
            return AppTheme.warningColor
        default:
            return AppTheme.secondaryColor
        }
    }
    
    private var statusIcon: String {
        switch timesheet.status {
        case "working", "active":
            return "clock.fill"
        case "completed", "approved":
            return "checkmark.circle.fill"
        case "flagged", "rejected":
            return "exclamationmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

