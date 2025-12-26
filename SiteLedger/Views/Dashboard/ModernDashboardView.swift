//
//  ModernDashboardView.swift
//  SiteLedger
//
//  Completely redesigned modern dashboard
//

import SwiftUI

struct ModernDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddMenu = false
    @State private var showingCreateJob = false
    @State private var showingAddReceipt = false
    @State private var showingUploadDocument = false
    @State private var navigateToJobs = false
    @State private var navigateToCompletedJobs = false
    @State private var navigateToAlerts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.xl) {
                        // Hero Header with App Icon
                        HeroHeader(user: authService.currentUser)
                        
                        // Quick Stats Grid
                        StatsGrid(viewModel: viewModel)
                        
                        // Active Jobs Section
                        if !viewModel.activeJobs.isEmpty {
                            JobsSection(jobs: viewModel.activeJobs, title: "Active Jobs", showCompleted: false, onSeeAll: {
                                navigateToJobs = true
                            })
                        }
                        
                        // Completed Jobs Section
                        CompletedJobsSection(jobs: viewModel.jobs.filter { $0.status == .completed }, onSeeAll: {
                            navigateToCompletedJobs = true
                        })
                        
                        // Recent Activity
                        RecentActivitySection(
                            receipts: Array(viewModel.receipts.prefix(3)),
                            timesheets: Array(viewModel.timesheets.prefix(3))
                        )
                        
                        // Quick Actions - Now with direct navigation
                        QuickActionsSection(
                            showingCreateJob: $showingCreateJob,
                            showingAddReceipt: $showingAddReceipt
                        )
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationBarHidden(true)
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadData(forUserId: userID)
                }
            }
            .refreshable {
                if let userID = authService.currentUser?.id {
                    viewModel.loadData(forUserId: userID)
                }
            }
            // Direct sheets from dashboard - no nested sheets
            .sheet(isPresented: $showingCreateJob) {
                NavigationStack {
                    ModernCreateJobView()
                }
            }
            .sheet(isPresented: $showingAddReceipt) {
                NavigationStack {
                    ModernAddReceiptView()
                }
            }
            .sheet(isPresented: $showingAddMenu) {
                AddMenuSheet(
                    showingCreateJob: $showingCreateJob,
                    showingAddReceipt: $showingAddReceipt,
                    showingUploadDocument: $showingUploadDocument
                )
            }
            .sheet(isPresented: $showingUploadDocument) {
                NavigationStack {
                    AddDocumentView()
                }
            }
            // Navigation destinations for See All buttons
            .navigationDestination(isPresented: $navigateToJobs) {
                ModernJobsListView()
            }
            .navigationDestination(isPresented: $navigateToCompletedJobs) {
                ModernJobsListView()
            }
            .navigationDestination(isPresented: $navigateToAlerts) {
                ModernAlertsView()
            }
        }
    }
}

// MARK: - Hero Header
struct HeroHeader: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            HStack(alignment: .top, spacing: ModernDesign.Spacing.lg) {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                    Text("Welcome back,")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                    
                    Text(user?.name ?? "User")
                        .font(ModernDesign.Typography.displayMedium)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // SiteLedger Logo
                SiteLedgerLogoView(.small, showLabel: true)
            }
            .padding(.top, ModernDesign.Spacing.md)
        }
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Calculate completed jobs revenue
    var completedJobs: [Job] {
        viewModel.jobs.filter { $0.status == .completed }
    }
    
    var completedJobsRevenue: Double {
        completedJobs.reduce(0) { $0 + $1.projectValue }
    }
    
    // Note: This is a simplified profit calculation
    // The actual profit is: projectValue - laborCost (receipts do not affect profit)
    var completedJobsRemainingBalance: Double {
        completedJobs.reduce(0) { total, job in
            total + (job.projectValue - job.amountPaid)
        }
    }
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            // Main Revenue Card
            ModernCard(backgroundColor: ModernDesign.Colors.primary.opacity(0.05), shadow: true) {
                VStack(spacing: ModernDesign.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Total Project Value")
                                .font(ModernDesign.Typography.labelSmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Text("$\(String(format: "%.2f", completedJobsRevenue))")
                                .font(ModernDesign.Typography.displayLarge)
                                .foregroundColor(ModernDesign.Colors.success)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(ModernDesign.Colors.success.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(ModernDesign.Colors.success)
                        }
                    }
                    
                    // Breakdown Row
                    HStack(spacing: ModernDesign.Spacing.lg) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Completed Jobs")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Text("\(completedJobs.count) jobs • $\(String(format: "%.2f", completedJobsRevenue))")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Labor Cost")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Text("$\(String(format: "%.2f", viewModel.totalLaborCost))")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                    }
                }
            }
            
            HStack(spacing: ModernDesign.Spacing.md) {
                StatCard(
                    title: "Active Jobs",
                    value: "\(viewModel.activeJobsCount)",
                    icon: "briefcase.fill",
                    color: ModernDesign.Colors.primary,
                    trend: nil
                )
                
                StatCard(
                    title: "Labor Cost",
                    value: "$\(String(format: "%.2f", viewModel.totalLaborCost))",
                    icon: "person.fill",
                    color: ModernDesign.Colors.warning,
                    trend: nil
                )
            }
            
            HStack(spacing: ModernDesign.Spacing.md) {
                StatCard(
                    title: "Net Profit",
                    value: "$\(String(format: "%.2f", viewModel.netProfit))",
                    icon: "chart.pie.fill",
                    color: viewModel.netProfit >= 0 ? ModernDesign.Colors.success : ModernDesign.Colors.error,
                    trend: nil
                )
                
                StatCard(
                    title: "Workers",
                    value: "\(viewModel.workers.count)",
                    icon: "person.2.fill",
                    color: ModernDesign.Colors.accent,
                    trend: nil
                )
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(color.opacity(0.1))
                        .cornerRadius(ModernDesign.Radius.medium)
                    
                    Spacer()
                    
                    if let trend = trend {
                        Text(trend)
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.success)
                    }
                }
                
                Text(value)
                    .font(ModernDesign.Typography.displayMedium)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                    .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.8)
                
                Text(title)
                    .font(ModernDesign.Typography.caption)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
            }
        }
    }
}

// MARK: - Jobs Section
struct JobsSection: View {
    let jobs: [Job]
    var title: String = "Active Jobs"
    var showCompleted: Bool = false
    var onSeeAll: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            ModernSectionHeader(
                title: title,
                subtitle: "\(jobs.count) ongoing",
                actionTitle: "See All",
                action: onSeeAll
            )
            
            VStack(spacing: ModernDesign.Spacing.md) {
                ForEach(Array(jobs.prefix(3))) { job in
                    NavigationLink(destination: ModernJobDetailView(job: job)) {
                        ModernJobCard(job: job)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Completed Jobs Section  
struct CompletedJobsSection: View {
    let jobs: [Job]
    var onSeeAll: (() -> Void)?
    
    var totalValue: Double {
        jobs.reduce(0) { $0 + $1.projectValue }
    }
    
    var totalPaid: Double {
        jobs.reduce(0) { $0 + $1.amountPaid }
    }
    
    var body: some View {
        if !jobs.isEmpty {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                ModernSectionHeader(
                    title: "Completed Jobs",
                    subtitle: "\(jobs.count) finished • $\(String(format: "%.2f", totalValue)) earned",
                    actionTitle: "See All",
                    action: onSeeAll
                )
                
                // Summary Card
                ModernCard(backgroundColor: ModernDesign.Colors.success.opacity(0.05), shadow: true) {
                    HStack(spacing: ModernDesign.Spacing.lg) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            HStack(spacing: ModernDesign.Spacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(ModernDesign.Colors.success)
                                Text("Total Earned")
                                    .font(ModernDesign.Typography.labelSmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                            Text("$\(String(format: "%.2f", totalValue))")
                                .font(ModernDesign.Typography.title1)
                                .foregroundColor(ModernDesign.Colors.success)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                            Text("Collected")
                                .font(ModernDesign.Typography.labelSmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Text("$\(String(format: "%.2f", totalPaid))")
                                .font(ModernDesign.Typography.title2)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                        }
                    }
                }
                
                // Show last 2 completed jobs
                VStack(spacing: ModernDesign.Spacing.sm) {
                    ForEach(Array(jobs.prefix(2))) { job in
                        NavigationLink(destination: ModernJobDetailView(job: job)) {
                            CompletedJobCard(job: job)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct CompletedJobCard: View {
    let job: Job
    
    var body: some View {
        ModernCard(shadow: false) {
            HStack(spacing: ModernDesign.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(ModernDesign.Colors.success.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(ModernDesign.Colors.success)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.jobName)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(job.clientName)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", job.projectValue))")
                        .font(ModernDesign.Typography.labelLarge)
                        .foregroundColor(ModernDesign.Colors.success)
                    Text("Earned")
                        .font(ModernDesign.Typography.captionSmall)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Modern Job Card
struct ModernJobCard: View {
    let job: Job
    
    var body: some View {
        ModernCard {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text(job.jobName)
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        
                        Text(job.clientName)
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    ModernBadge(
                        text: job.status.rawValue.capitalized,
                        color: statusColor(job.status),
                        size: .small
                    )
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text("Project Value")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Text("$\(String(format: "%.2f", job.projectValue))")
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
        }
    }
    
    private func statusColor(_ status: Job.JobStatus) -> Color {
        switch status {
        case .active: return ModernDesign.Colors.success
        case .completed: return ModernDesign.Colors.primary
        case .onHold: return ModernDesign.Colors.warning
        }
    }
}

// MARK: - Recent Activity
struct RecentActivitySection: View {
    let receipts: [Receipt]
    let timesheets: [Timesheet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            ModernSectionHeader(
                title: "Recent Activity",
                subtitle: "Latest updates"
            )
            
            ModernCard {
                VStack(spacing: ModernDesign.Spacing.md) {
                    ForEach(receipts.filter { $0.id != nil }) { receipt in
                        ActivityRow(
                            icon: "receipt.fill",
                            title: receipt.vendor ?? "Unknown Vendor",
                            subtitle: "$\(String(format: "%.2f", receipt.amount ?? 0))",
                            time: receipt.date ?? Date(),
                            color: ModernDesign.Colors.error
                        )
                        
                        if receipt.id != receipts.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .cornerRadius(ModernDesign.Radius.medium)
            
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                Text(title)
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(subtitle)
                    .font(ModernDesign.Typography.caption)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(timeAgo(time))
                .font(ModernDesign.Typography.captionSmall)
                .foregroundColor(ModernDesign.Colors.textTertiary)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Quick Actions
struct QuickActionsSection: View {
    @Binding var showingCreateJob: Bool
    @Binding var showingAddReceipt: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            ModernSectionHeader(
                title: "Quick Actions",
                subtitle: "Get things done faster"
            )
            
            HStack(spacing: ModernDesign.Spacing.md) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Job",
                    color: ModernDesign.Colors.primary
                ) {
                    showingCreateJob = true
                }
                
                QuickActionButton(
                    icon: "camera.fill",
                    title: "Scan Receipt",
                    color: ModernDesign.Colors.accent
                ) {
                    showingAddReceipt = true
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.medium()
            action()
        }) {
            ModernCard(backgroundColor: color.opacity(0.1), shadow: false) {
                VStack(spacing: ModernDesign.Spacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Menu Sheet
struct AddMenuSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showingCreateJob: Bool
    @Binding var showingAddReceipt: Bool
    @Binding var showingUploadDocument: Bool
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            Text("Add New")
                .font(ModernDesign.Typography.title1)
                .padding(.top)
            
            VStack(spacing: ModernDesign.Spacing.md) {
                MenuButton(icon: "briefcase.fill", title: "New Job", subtitle: "Create a new project") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingCreateJob = true
                    }
                }
                MenuButton(icon: "receipt.fill", title: "Add Receipt", subtitle: "Store a document") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAddReceipt = true
                    }
                }
                MenuButton(icon: "doc.fill", title: "Upload Document", subtitle: "Add a file") {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingUploadDocument = true
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesign.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(ModernDesign.Colors.primary)
                    .frame(width: 50, height: 50)
                    .background(ModernDesign.Colors.primary.opacity(0.1))
                    .cornerRadius(ModernDesign.Radius.medium)
                
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    Text(title)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Text(subtitle)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
            .padding(ModernDesign.Spacing.lg)
            .background(ModernDesign.Colors.cardBackground)
            .cornerRadius(ModernDesign.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
