import SwiftUI

struct ModernAlertsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = AlertsViewModel()
    @State private var selectedFilter: AlertFilterType = .all
    
    enum AlertFilterType: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case critical = "Critical"
        case warning = "Warning"
    }
    
    var filteredAlerts: [Alert] {
        switch selectedFilter {
        case .all:
            return viewModel.allAlerts
        case .unread:
            return viewModel.allAlerts.filter { !$0.read }
        case .critical:
            return viewModel.alertsBySeverity(.critical)
        case .warning:
            return viewModel.alertsBySeverity(.warning)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        HStack {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Alerts")
                                    .font(ModernDesign.Typography.displayMedium)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Text("\(viewModel.unreadCount) unread")
                                    .font(ModernDesign.Typography.bodySmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.unreadCount > 0 {
                                Button(action: {
                                    HapticsManager.shared.success()
                                    Task {
                                        try await viewModel.markAllAsRead(ownerID: authService.currentUser?.id ?? "")
                                    }
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(ModernDesign.Colors.success)
                                }
                            }
                        }
                        
                        // Summary Cards
                        HStack(spacing: ModernDesign.Spacing.md) {
                            AlertStatCard(
                                count: viewModel.unreadCount,
                                label: "Unread",
                                icon: "bell.badge.fill",
                                color: ModernDesign.Colors.error
                            )
                            
                            AlertStatCard(
                                count: viewModel.alertsBySeverity(.critical).count,
                                label: "Critical",
                                icon: "exclamationmark.triangle.fill",
                                color: ModernDesign.Colors.error
                            )
                            
                            AlertStatCard(
                                count: viewModel.alertsBySeverity(.warning).count,
                                label: "Warning",
                                icon: "exclamationmark.circle.fill",
                                color: ModernDesign.Colors.warning
                            )
                        }
                        
                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                ForEach(AlertFilterType.allCases, id: \.self) { filter in
                                    AlertsFilterChip(
                                        title: filter.rawValue,
                                        isSelected: selectedFilter == filter,
                                        action: {
                                            HapticsManager.shared.selection()
                                            selectedFilter = filter
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.md)
                    
                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredAlerts.isEmpty {
                        Spacer()
                        EmptyAlertsState()
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: ModernDesign.Spacing.md) {
                                ForEach(filteredAlerts, id: \.id) { alert in
                                    ModernAlertCard(
                                        alert: alert,
                                        onMarkRead: {
                                            HapticsManager.shared.light()
                                            Task {
                                                await viewModel.markAsRead(alert)
                                            }
                                        },
                                        onDelete: {
                                            HapticsManager.shared.rigid()
                                            Task {
                                                viewModel.deleteAlert(alert)
                                            }
                                        }
                                    )
                                    .id(alert.id ?? UUID().uuidString)
                                }
                            }
                            .padding(.horizontal, ModernDesign.Spacing.lg)
                            .padding(.top, ModernDesign.Spacing.sm)
                            .padding(.bottom, ModernDesign.Spacing.xxxl)
                        }
                        .refreshable {
                            viewModel.loadAlerts(forOwnerID: authService.currentUser?.id ?? "")
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadAlerts(forOwnerID: authService.currentUser?.id ?? "")
            }
        }
    }
}

struct AlertStatCard: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.sm) {
            HStack(spacing: ModernDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(ModernDesign.Typography.captionSmall)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            
            Text("\(count)")
                .font(ModernDesign.Typography.title2)
                .foregroundColor(ModernDesign.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernDesign.Spacing.md)
        .background(ModernDesign.Colors.cardBackground)
        .cornerRadius(ModernDesign.Radius.medium)
        .shadow(color: ModernDesign.Shadow.small.color,
               radius: ModernDesign.Shadow.small.radius,
               x: ModernDesign.Shadow.small.x,
               y: ModernDesign.Shadow.small.y)
    }
}

struct ModernAlertCard: View {
    let alert: Alert
    let onMarkRead: () -> Void
    let onDelete: () -> Void
    
    var severityColor: Color {
        switch alert.severity {
        case .critical:
            return ModernDesign.Colors.error
        case .warning:
            return ModernDesign.Colors.warning
        case .info:
            return ModernDesign.Colors.info
        }
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                // Header
                HStack(alignment: .top) {
                    // Severity Icon
                    ZStack {
                        Circle()
                            .fill(severityColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: severityIcon)
                            .font(.system(size: 18))
                            .foregroundColor(severityColor)
                    }
                    
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        HStack {
                            Text(alert.title)
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            
                            if !alert.read {
                                Circle()
                                    .fill(ModernDesign.Colors.primary)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            ModernBadge(
                                text: alert.type.rawValue.capitalized,
                                color: severityColor,
                                size: .small
                            )
                            
                            Text(timeAgo(alert.createdAt))
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Message
                Text(alert.message)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .lineLimit(3)
                
                // Actions
                HStack(spacing: ModernDesign.Spacing.md) {
                    if !alert.read {
                        Button(action: onMarkRead) {
                            HStack(spacing: ModernDesign.Spacing.xs) {
                                Image(systemName: "checkmark")
                                Text("Mark Read")
                            }
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(ModernDesign.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ModernDesign.Spacing.sm)
                            .background(ModernDesign.Colors.primary.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.small)
                        }
                    }
                    
                    Button(action: onDelete) {
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ModernDesign.Spacing.sm)
                        .background(ModernDesign.Colors.error.opacity(0.1))
                        .cornerRadius(ModernDesign.Radius.small)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.Radius.large)
                .stroke(alert.read ? Color.clear : severityColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AlertsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
                .padding(.horizontal, ModernDesign.Spacing.md)
                .padding(.vertical, ModernDesign.Spacing.sm)
                .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.cardBackground)
                .cornerRadius(ModernDesign.Radius.round)
                .shadow(color: isSelected ? ModernDesign.Shadow.small.color : .clear,
                       radius: ModernDesign.Shadow.small.radius,
                       x: ModernDesign.Shadow.small.x,
                       y: ModernDesign.Shadow.small.y)
        }
    }
}

struct EmptyAlertsState: View {
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(ModernDesign.Colors.success.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundColor(ModernDesign.Colors.success)
            }
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text("All Clear!")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text("No alerts to show. Your jobs are running smoothly!")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(ModernDesign.Spacing.xl)
    }
}
