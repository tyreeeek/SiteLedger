import SwiftUI

// MARK: - Notification Bell Button
struct NotificationBellButton: View {
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.textPrimary)
                
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppTheme.errorColor)
                            .frame(width: 18, height: 18)
                        
                        Text("\(min(unreadCount, 99))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
    }
}

// MARK: - Alerts List Sheet View
struct AlertsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AlertsViewModel
    let ownerID: String
    
    @State private var showingFilter = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    if viewModel.allAlerts.count > 0 {
                        filterBar
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.filteredAlerts.isEmpty {
                        emptyState
                    } else {
                        alertsList
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                try? await viewModel.markAllAsRead(ownerID: ownerID)
                            }
                        } label: {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.unreadCount == 0)
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            Task {
                                try? await viewModel.deleteReadAlerts()
                            }
                        } label: {
                            Label("Clear Read", systemImage: "trash")
                        }
                        .disabled(viewModel.allAlerts.filter { $0.read }.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Unread Only Toggle
            Button {
                withAnimation {
                    viewModel.showUnreadOnly.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.showUnreadOnly ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(viewModel.showUnreadOnly ? AppTheme.primaryColor : AppTheme.textSecondary)
                    Text("Unread")
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(viewModel.showUnreadOnly ? AppTheme.primaryColor.opacity(0.1) : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.showUnreadOnly ? AppTheme.primaryColor : AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Severity Filter
            Menu {
                Button {
                    viewModel.selectedSeverity = nil
                } label: {
                    Label("All", systemImage: viewModel.selectedSeverity == nil ? "checkmark" : "")
                }
                
                Divider()
                
                Button {
                    viewModel.selectedSeverity = .critical
                } label: {
                    Label("Critical", systemImage: viewModel.selectedSeverity == .critical ? "checkmark" : "exclamationmark.triangle.fill")
                }
                
                Button {
                    viewModel.selectedSeverity = .warning
                } label: {
                    Label("Warning", systemImage: viewModel.selectedSeverity == .warning ? "checkmark" : "exclamationmark.circle.fill")
                }
                
                Button {
                    viewModel.selectedSeverity = .info
                } label: {
                    Label("Info", systemImage: viewModel.selectedSeverity == .info ? "checkmark" : "info.circle.fill")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(viewModel.selectedSeverity != nil ? AppTheme.primaryColor : AppTheme.textSecondary)
                    Text(viewModel.selectedSeverity?.rawValue.capitalized ?? "Severity")
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(viewModel.selectedSeverity != nil ? AppTheme.primaryColor.opacity(0.1) : Color.clear)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.selectedSeverity != nil ? AppTheme.primaryColor : AppTheme.textSecondary.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
            
            Text("\(viewModel.filteredAlerts.count) alerts")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    // MARK: - Alerts List
    
    private var alertsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredAlerts, id: \.id) { alert in
                    AlertCard(alert: alert) {
                        Task {
                            await viewModel.markAsRead(alert)
                        }
                    } onDelete: {
                        Task {
                            viewModel.deleteAlert(alert)
                        }
                    }
                    .id(alert.id ?? UUID().uuidString)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.showUnreadOnly ? "checkmark.circle" : "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            
            Text(viewModel.showUnreadOnly ? "All caught up!" : "No notifications")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(viewModel.showUnreadOnly ? "You have no unread notifications" : "Your notifications will appear here")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Alert Card
struct AlertCard: View {
    let alert: Alert
    let onMarkRead: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: alert.icon)
                    .font(.system(size: 18))
                    .foregroundColor(severityColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    if !alert.read {
                        Circle()
                            .fill(AppTheme.primaryColor)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(3)
                
                HStack {
                    Label(alert.timeAgo, systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    // Action Buttons
                    if !alert.read {
                        Button {
                            onMarkRead()
                        } label: {
                            Text("Mark Read")
                                .font(.caption2)
                                .foregroundColor(AppTheme.primaryColor)
                        }
                    }
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(AppTheme.errorColor)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(alert.read ? AppTheme.cardBackground : AppTheme.cardBackground.opacity(0.8))
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(alert.read ? Color.clear : AppTheme.primaryColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .info:
            return AppTheme.primaryColor
        case .warning:
            return AppTheme.warningColor
        case .critical:
            return AppTheme.errorColor
        }
    }
}

// MARK: - Preview
#Preview {
    AlertsSheetView(
        viewModel: AlertsViewModel(),
        ownerID: "preview-owner-id"
    )
}
