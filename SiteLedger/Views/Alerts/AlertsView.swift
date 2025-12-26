import SwiftUI

struct AlertsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AlertsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Header
                        ScreenHeader(
                            title: "Alerts",
                            subtitle: "Stay on top of budget and payment issues",
                            action: {
                                HapticsManager.shared.success()
                                Task {
                                    try await viewModel.markAllAsRead(ownerID: authService.currentUser?.id ?? "")
                                }
                            },
                            actionIcon: "checkmark.circle.fill"
                        )
                        
                        VStack(spacing: DesignSystem.Spacing.cardSpacing) {
                            // Alert Summary Cards
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                AlertSummaryCard(
                                    count: viewModel.unreadCount,
                                    label: "Unread",
                                    icon: "exclamationmark.circle.fill",
                                    color: AppTheme.errorColor
                                )
                                
                                AlertSummaryCard(
                                    count: viewModel.alertsBySeverity(.critical).count,
                                    label: "Critical",
                                    icon: "bell.badge.fill",
                                    color: AppTheme.errorColor
                                )
                                
                                AlertSummaryCard(
                                    count: viewModel.alertsBySeverity(.warning).count,
                                    label: "Warnings",
                                    icon: "triangle.fill",
                                    color: AppTheme.primaryColor
                                )
                            }
                            
                            // Filter Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Filter Alerts")
                                    .font(DesignSystem.TextStyle.captionBold)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                HStack(spacing: DesignSystem.Spacing.small) {
                                    // Unread toggle
                                    Button(action: { viewModel.showUnreadOnly.toggle() }) {
                                        Label(viewModel.showUnreadOnly ? "Unread Only" : "All", systemImage: "checkmark")
                                            .font(DesignSystem.TextStyle.tiny)
                                            .fontWeight(.medium)
                                            .foregroundColor(viewModel.showUnreadOnly ? .white : DesignSystem.Colors.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(viewModel.showUnreadOnly ? AppTheme.accentColor : AppTheme.cardBackground)
                                            .cornerRadius(AppTheme.smallCornerRadius)
                                    }
                                    
                                    // Severity filter
                                    Menu {
                                        Button(action: { viewModel.selectedSeverity = nil }) {
                                            Label("All Severities", systemImage: "checkmark")
                                        }
                                        Divider()
                                        Button(action: { viewModel.selectedSeverity = .critical }) {
                                            Label("Critical", systemImage: "bell.badge.fill")
                                        }
                                        Button(action: { viewModel.selectedSeverity = .warning }) {
                                            Label("Warning", systemImage: "triangle.fill")
                                        }
                                        Button(action: { viewModel.selectedSeverity = .info }) {
                                            Label("Info", systemImage: "info.circle.fill")
                                        }
                                    } label: {
                                        Label(viewModel.selectedSeverity?.rawValue.capitalized ?? "Severity", systemImage: "line.horizontal.3.decrease.circle")
                                            .font(DesignSystem.TextStyle.tiny)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppTheme.cardBackground)
                                            .cornerRadius(AppTheme.smallCornerRadius)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            // Alerts List
                            if viewModel.isLoading {
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                            } else if !viewModel.filteredAlerts.isEmpty {
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    ForEach(viewModel.filteredAlerts, id: \.id) { alert in
                                        AlertCardView(alert: alert) {
                                            HapticsManager.shared.light()
                                            Task {
                                                await viewModel.markAsRead(alert)
                                            }
                                        } onDelete: {
                                            HapticsManager.shared.rigid()
                                            Task {
                                                viewModel.deleteAlert(alert)
                                            }
                                        }
                                        .id(alert.id ?? UUID().uuidString)
                                    }
                                }
                            } else {
                                EmptyStateView(
                                    icon: "checkmark.seal.fill",
                                    title: "All Clear",
                                    message: "No alerts to show. Your jobs are running smoothly!",
                                    action: nil,
                                    buttonTitle: nil
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    }
                    .padding(.top, DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadAlerts(forOwnerID: authService.currentUser?.id ?? "")
            }
        }
    }
}

// MARK: - Alert Summary Card

struct AlertSummaryCard: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.tiny) {
                Image(systemName: icon)
                    .font(DesignSystem.TextStyle.caption)
                    .foregroundColor(color)
                Text(label)
                    .font(DesignSystem.TextStyle.tiny)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Text("\(count)")
                .font(DesignSystem.TextStyle.title3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
}

// MARK: - Alert Card

struct AlertCardView: View {
    let alert: Alert
    let onMarkRead: () -> Void
    let onDelete: () -> Void
    
    var severityColor: Color {
        switch alert.severity {
        case .critical:
            return AppTheme.errorColor
        case .warning:
            return AppTheme.primaryColor
        case .info:
            return AppTheme.accentColor
        }
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            // Header with severity and title
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                    HStack(spacing: DesignSystem.Spacing.tiny) {
                        Image(systemName: severityIcon)
                            .font(DesignSystem.TextStyle.captionBold)
                            .foregroundColor(severityColor)
                        
                        Text(alert.title)
                            .font(DesignSystem.TextStyle.bodySecondary)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Text(alert.type.rawValue.capitalized)
                        .font(DesignSystem.TextStyle.tiny)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Time badge
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                    Text(timeAgo(alert.createdAt))
                        .font(DesignSystem.TextStyle.tiny)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if !alert.read {
                        Circle()
                            .fill(AppTheme.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Message
            Text(alert.message)
                .font(DesignSystem.TextStyle.caption)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(3)
            
            // Action buttons
            HStack(spacing: DesignSystem.Spacing.medium) {
                if !alert.read {
                    SecondaryButton(title: "Mark Read") {
                        onMarkRead()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash.fill")
                        .font(DesignSystem.TextStyle.tiny)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.errorColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.errorColor.opacity(0.1))
                        .cornerRadius(AppTheme.smallCornerRadius)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(alert.read ? AppTheme.cardBackground : AppTheme.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(
                    alert.read ? AppTheme.borderColor : severityColor.opacity(0.3),
                    lineWidth: 1.5
                )
        )
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    AlertsView()
        .environmentObject(AuthService())
}
