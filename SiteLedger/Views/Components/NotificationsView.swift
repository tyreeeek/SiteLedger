import SwiftUI

struct AppNotification: Identifiable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    
    enum NotificationType: String {
        case jobAssignment = "job_assignment"
        case timesheetApproval = "timesheet_approval"
        case paymentReceived = "payment_received"
        case general = "general"
    }
}

struct NotificationsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if !notifications.isEmpty {
                            Text("\(notifications.count) notifications")
                                .font(AppTheme.captionFont)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if !notifications.isEmpty {
                        Button(action: markAllAsRead) {
                            Text("Mark All Read")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryColor)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryColor))
                    Spacer()
                } else if notifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notifications) { notification in
                                NotificationRowView(notification: notification) {
                                    markAsRead(notification)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        isLoading = false
        notifications = []
    }
    
    private func markAllAsRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
    }
    
    private func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
}

struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            
            Text("No Notifications")
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("You're all caught up!")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.system(size: 15, weight: notification.isRead ? .regular : .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                    
                    Text(timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(AppTheme.primaryColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(notification.isRead ? Color.clear : AppTheme.primaryColor.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch notification.type {
        case .jobAssignment:
            return "briefcase.fill"
        case .timesheetApproval:
            return "checkmark.circle.fill"
        case .paymentReceived:
            return "dollarsign.circle.fill"
        case .general:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .jobAssignment:
            return .blue
        case .timesheetApproval:
            return .green
        case .paymentReceived:
            return .orange
        case .general:
            return .gray
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AuthService.shared)
}
