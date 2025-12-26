import SwiftUI

struct AlertsListView: View {
    @EnvironmentObject var alertsViewModel: AlertsViewModel
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var showingFilterOptions = false
    @State private var selectedTab: AlertTab = .all
    
    enum AlertTab {
        case all, unread
    }
    
    var displayedAlerts: [Alert] {
        switch selectedTab {
        case .all:
            return alertsViewModel.filteredAlerts
        case .unread:
            return alertsViewModel.filteredAlerts.filter { !$0.read }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("Filter", selection: $selectedTab) {
                        Text("All (\(alertsViewModel.allAlerts.count))").tag(AlertTab.all)
                        Text("Unread (\(alertsViewModel.unreadCount))").tag(AlertTab.unread)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Filter Pills
                    if alertsViewModel.selectedType != nil || alertsViewModel.selectedSeverity != nil {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if let type = alertsViewModel.selectedType {
                                    FilterPill(text: type.rawValue.capitalized) {
                                        alertsViewModel.selectedType = nil
                                    }
                                }
                                
                                if let severity = alertsViewModel.selectedSeverity {
                                    FilterPill(text: severity.rawValue.capitalized) {
                                        alertsViewModel.selectedSeverity = nil
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Alerts List
                    if alertsViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    } else if displayedAlerts.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: selectedTab == .unread ? "checkmark.circle.fill" : "bell.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                            
                            Text(selectedTab == .unread ? "No unread alerts" : "No alerts yet")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(selectedTab == .unread ? "You're all caught up!" : "Alerts about budgets, payments, and timesheets will appear here")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(displayedAlerts, id: \.id) { alert in
                                    AlertRowView(alert: alert)
                                        .environmentObject(alertsViewModel)
                                        .id(alert.id ?? UUID().uuidString)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Filter by Type
                        Menu("Filter by Type") {
                            Button("All Types") {
                                alertsViewModel.selectedType = nil
                            }
                            ForEach([AlertType.budget, .payment, .timesheet, .labor, .receipt, .document], id: \.self) { type in
                                Button(type.rawValue.capitalized) {
                                    alertsViewModel.selectedType = type
                                }
                            }
                        }
                        
                        // Filter by Severity
                        Menu("Filter by Severity") {
                            Button("All Severities") {
                                alertsViewModel.selectedSeverity = nil
                            }
                            ForEach([AlertSeverity.critical, .warning, .info], id: \.self) { severity in
                                Button(severity.rawValue.capitalized) {
                                    alertsViewModel.selectedSeverity = severity
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Actions
                        if alertsViewModel.unreadCount > 0 {
                            Button("Mark All as Read") {
                                Task {
                                    if let ownerID = authService.currentUser?.id {
                                        try? await alertsViewModel.markAllAsRead(ownerID: ownerID)
                                    }
                                }
                            }
                        }
                        
                        if alertsViewModel.allAlerts.contains(where: { $0.read }) {
                            Button("Delete Read Alerts", role: .destructive) {
                                Task {
                                    try? await alertsViewModel.deleteReadAlerts()
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
        }
    }
}

// MARK: - Alert Row View
struct AlertRowView: View {
    let alert: Alert
    @EnvironmentObject var alertsViewModel: AlertsViewModel
    @State private var showingDeleteConfirmation = false
    
    var severityColor: Color {
        switch alert.severity {
        case .critical:
            return AppTheme.errorColor
        case .warning:
            return Color.orange
        case .info:
            return AppTheme.accentColor
        }
    }
    
    var typeIcon: String {
        switch alert.type {
        case .budget:
            return "dollarsign.circle.fill"
        case .payment:
            return "creditcard.fill"
        case .timesheet:
            return "clock.fill"
        case .labor:
            return "person.2.fill"
        case .receipt:
            return "receipt.fill"
        case .document:
            return "doc.fill"
        }
    }
    
    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: typeIcon)
                    .font(.title2)
                    .foregroundColor(severityColor)
                    .frame(width: 40, height: 40)
                    .background(severityColor.opacity(0.1))
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(alert.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        if !alert.read {
                            Circle()
                                .fill(AppTheme.accentColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(alert.message)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(3)
                    
                    HStack {
                        // Type badge
                        Text(alert.type.rawValue.capitalized)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(severityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor.opacity(0.1))
                            .cornerRadius(4)
                        
                        // Severity badge
                        Text(alert.severity.rawValue.capitalized)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // Time
                        Text(alert.createdAt.timeAgoDisplay())
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .opacity(alert.read ? 0.6 : 1.0)
        .onTapGesture {
            if !alert.read {
                Task {
                    await alertsViewModel.markAsRead(alert)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if !alert.read {
                Button {
                    Task {
                        await alertsViewModel.markAsRead(alert)
                    }
                } label: {
                    Label("Read", systemImage: "checkmark")
                }
                .tint(AppTheme.accentColor)
            }
        }
        .confirmationDialog("Delete Alert", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    alertsViewModel.deleteAlert(alert)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this alert? This action cannot be undone.")
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(AppTheme.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.accentColor.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Date Extension for "Time Ago"
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    AlertsListView()
        .environmentObject(AlertsViewModel())
        .environmentObject(AuthService())
}
