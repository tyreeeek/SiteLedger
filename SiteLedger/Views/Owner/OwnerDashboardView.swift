import SwiftUI

struct OwnerDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var alertsViewModel = AlertsViewModel()
    @State private var showingAlerts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.activeJobs.isEmpty && viewModel.receipts.isEmpty {
                    LoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                            // Modern Header with Notification Bell
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Dashboard")
                                            .font(DesignSystem.TextStyle.title2)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text("This Month")
                                            .font(DesignSystem.TextStyle.bodySecondary)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    NotificationBellButton(
                                        unreadCount: alertsViewModel.unreadCount,
                                        action: { showingAlerts = true }
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.sectionSpacing)
                            
                            // Monthly Financial Summary Cards - Modern Grid
                            VStack(spacing: DesignSystem.Spacing.medium) {
                                HStack(spacing: DesignSystem.Spacing.medium) {
                                    FinancialCard(
                                        title: "Project Value",
                                        amount: viewModel.totalProjectValue,
                                        icon: "briefcase.fill",
                                        type: .projectValue
                                    )
                                    
                                    FinancialCard(
                                        title: "Labor Cost",
                                        amount: viewModel.monthlyLaborCost,
                                        icon: "person.2.fill",
                                        type: .laborCost
                                    )
                                }
                                
                                FinancialCard(
                                    title: "Monthly Net Profit",
                                    amount: viewModel.monthlyNetProfit,
                                    icon: "chart.line.uptrend.xyaxis",
                                    type: .profit,
                                    isLarge: true
                                )
                            }
                            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                            
                            // Key Metrics Row
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                MetricCard(
                                    title: "Active Jobs",
                                    value: "\(viewModel.activeJobsCount)",
                                    icon: "briefcase.fill",
                                    color: AppTheme.primaryColor
                                )
                                
                                MetricCard(
                                    title: "Total Jobs",
                                    value: "\(viewModel.totalJobsCount)",
                                    icon: "doc.fill",
                                    color: AppTheme.secondaryColor
                                )
                                
                                MetricCard(
                                    title: "Unread Alerts",
                                    value: "\(viewModel.unreadAlerts)",
                                    icon: "bell.fill",
                                    color: viewModel.unreadAlerts > 0 ? AppTheme.warningColor : AppTheme.textSecondary
                                )
                            }
                            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                            
                            // Charts Section
                            VStack(spacing: DesignSystem.Spacing.medium) {
                                // Monthly Profit Trend
                                MonthlyProfitTrendChart(
                                    receipts: viewModel.receipts,
                                    timesheets: viewModel.timesheets,
                                    workers: viewModel.workers
                                )
                                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                
                                // Daily Receipts Chart (document storage only)
                                DailyReceiptsChart(receipts: viewModel.receipts)
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                
                                // Receipts by Category
                                if !viewModel.receipts.isEmpty {
                                    TopCategoriesChart(receipts: viewModel.receipts)
                                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                }
                            }
                            
                            // Active Jobs Section
                            if !viewModel.activeJobs.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    HStack {
                                        Label("Active Jobs", systemImage: "briefcase.fill")
                                            .font(DesignSystem.TextStyle.bodyBold)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: JobsListView()) {
                                            Text("View All")
                                                .font(DesignSystem.TextStyle.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(AppTheme.primaryColor)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                    
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        ForEach(viewModel.activeJobs.prefix(3), id: \.id) { job in
                                            NavigationLink(destination: JobDetailView(job: job)) {
                                                ListItemRow(
                                                    title: job.jobName,
                                                    subtitle: job.clientName,
                                                    value: "$\(String(format: "%.2f", job.projectValue))",
                                                    icon: "briefcase",
                                                    action: {}
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                }
                            }
                            
                            // Recent Receipts Section
                            if !viewModel.recentReceipts.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    HStack {
                                        Label("Recent Receipts", systemImage: "receipt.fill")
                                            .font(DesignSystem.TextStyle.bodyBold)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: ReceiptsListView()) {
                                            Text("View All")
                                                .font(DesignSystem.TextStyle.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(AppTheme.primaryColor)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                    
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        ForEach(viewModel.recentReceipts.prefix(5), id: \.id) { receipt in
                                            NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                                ListItemRow(
                                                    title: receipt.vendor ?? "Unknown",
                                                    subtitle: (receipt.date ?? Date()).formatted(date: .abbreviated, time: .omitted),
                                                    value: "$\(String(format: "%.2f", receipt.amount ?? 0))",
                                                    icon: "doc.text",
                                                    action: {}
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                }
                            }
                            
                            // AI Alerts Section
                            if !viewModel.recentAlerts.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    HStack {
                                        Label("Recent Alerts", systemImage: "bell.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: AlertsView()) {
                                            Text("View All")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(AppTheme.primaryColor)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                    
                                    VStack(spacing: DesignSystem.Spacing.small) {
                                        ForEach(viewModel.recentAlerts.prefix(3), id: \.id) { alert in
                                            AlertRow(alert: alert)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                }
                            }
                            
                            Spacer(minLength: DesignSystem.Spacing.huge)
                        }
                        .padding(.vertical, DesignSystem.Spacing.medium)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                let userID = authService.currentUser?.id ?? ""
                viewModel.loadData(forUserId: userID)
                alertsViewModel.loadAlerts(forOwnerID: userID)
            }
            .sheet(isPresented: $showingAlerts) {
                AlertsSheetView(
                    viewModel: alertsViewModel,
                    ownerID: authService.currentUser?.id ?? ""
                )
            }
        }
    }
}

struct AlertRow: View {
    let alert: Alert
    
    var severityColor: Color {
        switch alert.severity {
        case .critical:
            return AppTheme.errorColor
        case .warning:
            return AppTheme.warningColor
        case .info:
            return AppTheme.primaryColor
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(DesignSystem.TextStyle.captionBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(alert.message)
                    .font(DesignSystem.TextStyle.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(alert.createdAt.formatted(date: .omitted, time: .shortened))
                .font(DesignSystem.TextStyle.tiny)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
    }
}
