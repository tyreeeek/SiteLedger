import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var alertsViewModel = AlertsViewModel()
    @State private var showingAddMenu = false
    @State private var showingAlerts = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.cardSpacing) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            Text("Welcome back,")
                                .font(DesignSystem.TextStyle.title3)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text(authService.currentUser?.name ?? "User")
                                .font(DesignSystem.TextStyle.title1)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.standard)
                        .padding(.top, DesignSystem.Spacing.large)
                        
                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                                Text("This Month's Overview")
                                    .font(DesignSystem.TextStyle.title3)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    MonthMetricRow(
                                        title: "Project Value",
                                        value: viewModel.totalProjectValue,
                                        color: AppTheme.primaryColor,
                                        icon: "briefcase.fill"
                                    )
                                    
                                    MonthMetricRow(
                                        title: "Labor Cost",
                                        value: viewModel.totalLaborCost,
                                        color: AppTheme.warningColor,
                                        icon: "person.2.fill"
                                    )
                                    
                                    MonthMetricRow(
                                        title: "Net Profit",
                                        value: viewModel.netProfit,
                                        color: viewModel.netProfit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                                        icon: "chart.line.uptrend.xyaxis"
                                    )
                                    
                                    Divider()
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.standard)
                        
                        if !viewModel.jobs.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    Text("Active Jobs")
                                        .font(DesignSystem.TextStyle.title3)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    ForEach(viewModel.jobs.filter { $0.status == .active && $0.id != nil }.prefix(5)) { job in
                                        NavigationLink(destination: JobDetailView(job: job)) {
                                            JobRowView(job: job)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.standard)
                        }
                        
                        if !viewModel.receipts.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                    Text("Recent Receipts")
                                        .font(DesignSystem.TextStyle.title3)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    ForEach(viewModel.receipts.filter { $0.id != nil }.prefix(5)) { receipt in
                                        RecentReceiptRowView(receipt: receipt)
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.standard)
                        }
                        

                    }
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAlerts = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(AppTheme.accentColor)
                                .font(.title3)
                            
                            if alertsViewModel.unreadCount > 0 {
                                Text("\(alertsViewModel.unreadCount)")
                                    .font(DesignSystem.TextStyle.tiny)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(AppTheme.errorColor)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Job") { }
                        Button("Add Receipt") { }
                        Button("Add Timesheet") { }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAlerts) {
                AlertsListView()
                    .environmentObject(alertsViewModel)
                    .environmentObject(authService)
            }
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadData(forUserId: userID)
                    alertsViewModel.loadAlerts(forOwnerID: userID)
                }
            }
            .refreshable {
                if let userID = authService.currentUser?.id {
                    viewModel.loadData(forUserId: userID)
                    alertsViewModel.loadAlerts(forOwnerID: userID)
                }
            }
        }
    }
}

struct JobRowView: View {
    let job: Job
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text(job.jobName)
                    .font(DesignSystem.TextStyle.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(job.clientName)
                    .font(DesignSystem.TextStyle.bodySecondary)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                Text(job.startDate.localDateString)
                    .font(DesignSystem.TextStyle.bodyBold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text(job.status.rawValue.capitalized)
                    .font(DesignSystem.TextStyle.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

struct MonthMetricRow: View {
    let title: String
    let value: Double
    let color: Color
    let icon: String
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(title)
                .foregroundColor(AppTheme.textPrimary)
                .fontWeight(isBold ? .semibold : .regular)
            
            Spacer()
            
            Text("$\(String(format: "%.2f", value))")
                .foregroundColor(color)
                .fontWeight(isBold ? .bold : .semibold)
                .font(isBold ? .title3 : .body)
        }
    }
}

struct RecentReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            // Receipts are documents only - neutral icon
            Image(systemName: "doc.text.fill")
                .foregroundColor(AppTheme.primaryColor)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text(receipt.vendor ?? "Unknown Vendor")
                    .font(DesignSystem.TextStyle.bodySecondary)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text((receipt.date ?? Date()).localDateString)
                    .font(DesignSystem.TextStyle.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                .font(DesignSystem.TextStyle.bodyBold)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}
