import SwiftUI

struct ModernJobDetailView: View {
    let job: Job
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    @State private var showingAddReceipt = false
    @State private var showingEditJob = false
    @State private var showingAssignWorkers = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Header Card
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text(job.jobName)
                                        .font(ModernDesign.Typography.title1)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                    
                                    Text(job.clientName)
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                
                                ModernBadge(
                                    text: job.status.rawValue.capitalized,
                                    color: statusColor,
                                    size: .medium
                                )
                            }
                            
                            Rectangle()
                                .fill(ModernDesign.Colors.border)
                                .frame(height: 1)
                            
                            // Address
                            if !job.address.isEmpty {
                                HStack(spacing: ModernDesign.Spacing.sm) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                    Text(job.address)
                                        .font(ModernDesign.Typography.bodySmall)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                        .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                }
                            }
                            
                            // Dates
                            HStack(spacing: ModernDesign.Spacing.xl) {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                    Text("Start")
                                        .font(ModernDesign.Typography.captionSmall)
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                    Text(job.startDate.localDateString)
                                        .font(ModernDesign.Typography.label)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                                
                                if let endDate = job.endDate {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("End")
                                            .font(ModernDesign.Typography.captionSmall)
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                        Text(endDate.localDateString)
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Financial Summary - All 6 key metrics per Blueprint
                    VStack(spacing: ModernDesign.Spacing.md) {
                        // Row 1: Project Value & Amount Paid
                        HStack(spacing: ModernDesign.Spacing.md) {
                            FinancialStatCard(
                                title: "Project Value",
                                amount: job.projectValue,
                                icon: "briefcase.fill",
                                color: ModernDesign.Colors.primary
                            )
                            
                            FinancialStatCard(
                                title: "Amount Paid",
                                amount: job.amountPaid,
                                icon: "creditcard.fill",
                                color: ModernDesign.Colors.success
                            )
                        }
                        
                        // Row 2: Labor Cost & Receipt Expenses
                        HStack(spacing: ModernDesign.Spacing.md) {
                            FinancialStatCard(
                                title: "Labor Cost",
                                amount: laborCost,
                                icon: "person.2.fill",
                                color: ModernDesign.Colors.warning
                            )
                            
                            FinancialStatCard(
                                title: "Expenses",
                                amount: receiptExpenses,
                                icon: "receipt.fill",
                                color: ModernDesign.Colors.error
                            )
                        }
                        
                        // Row 3: Balance Due & Profit
                        HStack(spacing: ModernDesign.Spacing.md) {
                            FinancialStatCard(
                                title: "Balance Due",
                                amount: job.remainingBalance,
                                icon: "hourglass.circle.fill",
                                color: job.remainingBalance > 0 ? ModernDesign.Colors.warning : ModernDesign.Colors.success
                            )
                            
                            FinancialStatCard(
                                title: "Profit",
                                amount: profit,
                                icon: "chart.line.uptrend.xyaxis",
                                color: profit >= 0 ? ModernDesign.Colors.success : ModernDesign.Colors.error
                            )
                        }
                    }
                    
                    // Progress Card
                    ModernCard(shadow: true) {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            HStack {
                                Text("Payment Progress")
                                    .font(ModernDesign.Typography.labelLarge)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(paymentProgress * 100))%")
                                    .font(ModernDesign.Typography.labelLarge)
                                    .foregroundColor(ModernDesign.Colors.primary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(ModernDesign.Colors.border)
                                        .frame(height: 10)
                                    
                                    Rectangle()
                                        .fill(ModernDesign.Colors.success)
                                        .frame(width: geometry.size.width * min(paymentProgress, 1.0), height: 10)
                                }
                                .cornerRadius(ModernDesign.Radius.round)
                            }
                            .frame(height: 10)
                            
                            HStack {
                                Text("Remaining: $\(String(format: "%.2f", job.remainingBalance))")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    
                    // Edit Button
                    ModernButton(
                        title: "Edit Job Details",
                        icon: "pencil",
                        style: .secondary,
                        size: .large,
                        action: {
                            HapticsManager.shared.light()
                            showingEditJob = true
                        }
                    )
                    
                    // Tab Navigation - ALL 5 TABS per Blueprint
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            JobDetailTabButton(title: "Overview", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            JobDetailTabButton(title: "Receipts", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            JobDetailTabButton(title: "Timesheets", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            JobDetailTabButton(title: "Documents", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                            JobDetailTabButton(title: "AI Summary", isSelected: selectedTab == 4) {
                                selectedTab = 4
                            }
                        }
                    }
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case 0:
                            OverviewTabContent(
                                job: job,
                                laborCost: laborCost,
                                receiptExpenses: receiptExpenses,
                                profit: profit,
                                receiptsCount: viewModel.receipts.count,
                                timesheetsCount: timesheetViewModel.timesheets.count,
                                receipts: viewModel.receipts
                            )
                        case 1:
                            ReceiptsTabContent(receipts: viewModel.receipts, showingAddReceipt: $showingAddReceipt)
                        case 2:
                            TimesheetsTabContent(timesheets: timesheetViewModel.timesheets, job: job)
                        case 3:
                            DocumentsTabContent(jobID: job.id ?? "")
                        case 4:
                            AISummaryTabContent(job: job, receipts: viewModel.receipts, timesheets: timesheetViewModel.timesheets, laborCost: laborCost)
                        default:
                            EmptyView()
                        }
                    }
                }
                .padding(ModernDesign.Spacing.lg)
                .padding(.bottom, ModernDesign.Spacing.xxxl)
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    HapticsManager.shared.light()
                    showingAssignWorkers = true
                }) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(ModernDesign.Colors.primary)
                }
            }
        }
        .onAppear {
            if let jobID = job.id, let userID = authService.currentUser?.id {
                viewModel.loadReceiptsForJob(jobID: jobID)
                viewModel.loadWorkers(ownerID: userID)
                viewModel.loadTimesheets(userID: userID)
                Task {
                    await timesheetViewModel.loadTimesheets(for: jobID)
                }
            }
        }
        .sheet(isPresented: $showingAddReceipt, onDismiss: {
            // Reload receipts when the add sheet is dismissed
            if let jobID = job.id {
                viewModel.loadReceiptsForJob(jobID: jobID)
            }
        }) {
            ModernAddReceiptView(preSelectedJob: job)
        }
        .sheet(isPresented: $showingEditJob) {
            EditJobView(job: job)
        }
        .sheet(isPresented: $showingAssignWorkers) {
            AssignWorkersView(job: job)
                .environmentObject(viewModel)
        }
    }
    
    private var statusColor: Color {
        switch job.status {
        case .active: return ModernDesign.Colors.info
        case .completed: return ModernDesign.Colors.success
        case .onHold: return ModernDesign.Colors.warning
        }
    }
    
    /// Labor cost = sum of (hours × worker.hourlyRate) for all timesheets
    private var laborCost: Double {
        guard let jobID = job.id else { return 0 }
        return viewModel.getJobLaborCost(jobID: jobID)
    }
    
    /// Receipt expenses linked to this job
    private var receiptExpenses: Double {
        guard let jobID = job.id else { return 0 }
        return viewModel.getJobReceiptExpenses(jobID: jobID)
    }
    
    /// Profit formula: projectValue - laborCost - receiptExpenses
    private var profit: Double {
        job.calculateProfit(laborCost: laborCost, receiptExpenses: receiptExpenses)
    }
    
    private var paymentProgress: Double {
        guard job.projectValue > 0 else { return 0 }
        return job.amountPaid / job.projectValue
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return "$\(String(format: "%.2f", amount))"
    }
}

struct FinancialStatCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                HStack(spacing: ModernDesign.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Text(title)
                        .font(ModernDesign.Typography.captionSmall)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                        .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                }
                
                Text("$\(String(format: "%.2f", amount))")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                    .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct JobDetailTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
                .padding(.horizontal, ModernDesign.Spacing.lg)
                .padding(.vertical, ModernDesign.Spacing.sm)
                .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.cardBackground)
                .cornerRadius(ModernDesign.Radius.medium)
        }
    }
}

struct ReceiptsTabContent: View {
    let receipts: [Receipt]
    @Binding var showingAddReceipt: Bool
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    Text("Receipts")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Spacer()
                    Button(action: {
                        HapticsManager.shared.light()
                        showingAddReceipt = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                }
                
                if receipts.isEmpty {
                    VStack(spacing: ModernDesign.Spacing.md) {
                        Image(systemName: "receipt")
                            .font(.system(size: 40))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        Text("No receipts yet")
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.xl)
                } else {
                    ForEach(receipts.filter { $0.id != nil }) { receipt in
                        HStack {
                            Image(systemName: "receipt")
                                .foregroundColor(ModernDesign.Colors.primary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(receipt.vendor ?? "Unknown Vendor")
                                    .font(ModernDesign.Typography.label)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                Text((receipt.date ?? Date()).localDateString)
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                        }
                        .padding(.vertical, ModernDesign.Spacing.sm)
                        
                        if receipt.id != receipts.last?.id {
                            Rectangle()
                                .fill(ModernDesign.Colors.border)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

struct TimesheetsTabContent: View {
    let timesheets: [Timesheet]
    let job: Job
    
    var totalHours: Double {
        timesheets.reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    Text("Timesheets")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Spacer()
                    
                    NavigationLink(destination: ModernTimesheetsView(job: job)) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                }
                
                if timesheets.isEmpty {
                    VStack(spacing: ModernDesign.Spacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        Text("No time entries yet")
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.xl)
                } else {
                    // Summary
                    HStack {
                        Text("Total Hours")
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.2f hrs", totalHours))
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                    .padding(ModernDesign.Spacing.md)
                    .background(ModernDesign.Colors.primary.opacity(0.1))
                    .cornerRadius(ModernDesign.Radius.small)
                    
                    ForEach(timesheets.prefix(5), id: \.id) { timesheet in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(ModernDesign.Colors.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text((timesheet.clockIn ?? Date()).localDateTimeString)
                                    .font(ModernDesign.Typography.label)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                            }
                            
                            Spacer()
                            
                            Text("\(String(format: "%.2f", timesheet.hours ?? 0)) hrs")
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.accent)
                        }
                        .padding(.vertical, ModernDesign.Spacing.sm)
                        .id(timesheet.id ?? UUID().uuidString)
                    }
                }
            }
        }
    }
}

struct DocumentsTabContent: View {
    let jobID: String
    @StateObject private var viewModel = DocumentsViewModel()
    @State private var showingAddDocument = false
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    Text("Documents")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Spacer()
                    Button(action: {
                        HapticsManager.shared.light()
                        showingAddDocument = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                }
                
                if viewModel.documents.isEmpty {
                    VStack(spacing: ModernDesign.Spacing.md) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        Text("No documents yet")
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.xl)
                } else {
                    ForEach(viewModel.documents, id: \.id) { document in
                        NavigationLink(destination: DocumentDetailView(document: document)) {
                            HStack {
                                Image(systemName: document.fileType == .pdf ? "doc.fill" : "photo.fill")
                                    .foregroundColor(ModernDesign.Colors.primary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(document.title)
                                        .font(ModernDesign.Typography.label)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Text(document.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                                        .font(ModernDesign.Typography.caption)
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(ModernDesign.Colors.textTertiary)
                            }
                            .padding(.vertical, ModernDesign.Spacing.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(document.id ?? UUID().uuidString)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadDocumentsForJob(jobID: jobID)
        }
        .sheet(isPresented: $showingAddDocument) {
            ModernAddDocumentView(preselectedJobID: jobID)
        }
    }
}

// MARK: - Overview Tab Content
struct OverviewTabContent: View {
    let job: Job
    let laborCost: Double
    let receiptExpenses: Double
    let profit: Double
    let receiptsCount: Int
    let timesheetsCount: Int
    let receipts: [Receipt]
    
    /// Format currency for display
    private func formatCurrency(_ value: Double) -> String {
        return "$\(String(format: "%.2f", value))"
    }
    
    // Calculate receipt totals by category
    private var receiptCostsByCategory: [(category: String, amount: Double, icon: String)] {
        var costs: [String: Double] = [:]
        
        for receipt in receipts {
            let category = receipt.category ?? "Other"
            costs[category, default: 0] += receipt.amount ?? 0
        }
        
        return costs.map { (category: $0.key, amount: $0.value, icon: iconForCategory($0.key)) }
            .sorted { $0.amount > $1.amount }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "materials": return "hammer.fill"
        case "gas/fuel", "gas", "fuel": return "fuelpump.fill"
        case "tools": return "wrench.and.screwdriver.fill"
        case "equipment": return "gearshape.2.fill"
        default: return "doc.text.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            // Quick Stats
            ModernCard(shadow: true) {
                VStack(spacing: ModernDesign.Spacing.md) {
                    HStack {
                        Text("Quick Stats")
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack(spacing: ModernDesign.Spacing.md) {
                        StatBadge(
                            icon: "doc.text.fill",
                            value: "\(receiptsCount)",
                            label: "Receipts",
                            color: ModernDesign.Colors.info
                        )
                        StatBadge(
                            icon: "clock.fill",
                            value: "\(timesheetsCount)",
                            label: "Timesheets",
                            color: ModernDesign.Colors.warning
                        )
                        StatBadge(
                            icon: "person.2.fill",
                            value: "\(job.assignedWorkers?.count ?? 0)",
                            label: "Workers",
                            color: ModernDesign.Colors.success
                        )
                    }
                }
            }
            
            // Receipt Costs by Category
            if !receipts.isEmpty {
                ModernCard(shadow: true) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                        HStack {
                            Text("Receipt Costs by Category")
                                .font(ModernDesign.Typography.title3)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            Spacer()
                            Text("(Document Storage Only)")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                        
                        VStack(spacing: ModernDesign.Spacing.sm) {
                            ForEach(receiptCostsByCategory, id: \.category) { item in
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(ModernDesign.Colors.primary)
                                        .frame(width: 24)
                                    
                                    Text(item.category)
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("$\(String(format: "%.2f", item.amount))")
                                        .font(ModernDesign.Typography.labelLarge)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                }
                                
                                if item.category != receiptCostsByCategory.last?.category {
                                    Divider()
                                }
                            }
                            
                            // Total
                            Rectangle()
                                .fill(ModernDesign.Colors.border)
                                .frame(height: 2)
                            
                            HStack {
                                Text("Total")
                                    .font(ModernDesign.Typography.labelLarge)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", receiptCostsByCategory.reduce(0) { $0 + $1.amount }))")
                                    .font(ModernDesign.Typography.title3)
                                    .foregroundColor(ModernDesign.Colors.primary)
                            }
                        }
                    }
                }
            }
            
            // Financial Breakdown
            ModernCard(shadow: true) {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                    Text("Financial Breakdown")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    VStack(spacing: ModernDesign.Spacing.sm) {
                        FinancialBreakdownRow(
                            label: "Project Value",
                            amount: job.projectValue,
                            color: ModernDesign.Colors.primary
                        )
                        FinancialBreakdownRow(
                            label: "Amount Paid",
                            amount: job.amountPaid,
                            color: ModernDesign.Colors.success
                        )
                        FinancialBreakdownRow(
                            label: "Balance Due",
                            amount: job.remainingBalance,
                            color: job.remainingBalance > 0 ? ModernDesign.Colors.warning : ModernDesign.Colors.success
                        )
                        
                        Divider()
                            .padding(.vertical, ModernDesign.Spacing.xs)
                        
                        FinancialBreakdownRow(
                            label: "Labor Cost",
                            amount: laborCost,
                            color: ModernDesign.Colors.warning
                        )
                        FinancialBreakdownRow(
                            label: "Receipt Expenses",
                            amount: receiptExpenses,
                            color: ModernDesign.Colors.error
                        )
                        
                        Divider()
                            .padding(.vertical, ModernDesign.Spacing.xs)
                        
                        FinancialBreakdownRow(
                            label: "Net Profit",
                            amount: profit,
                            color: profit >= 0 ? ModernDesign.Colors.success : ModernDesign.Colors.error,
                            isHighlighted: true
                        )
                        
                        // Show the calculation breakdown
                        Text("Profit = \(formatCurrency(job.projectValue)) - \(formatCurrency(laborCost)) - \(formatCurrency(receiptExpenses))")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                            .padding(.top, ModernDesign.Spacing.xs)
                    }
                }
            }
            
            // Notes
            if !job.notes.isEmpty {
                ModernCard(shadow: true) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                        Text("Notes")
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        
                        Text(job.notes)
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - AI Summary Tab Content
struct AISummaryTabContent: View {
    let job: Job
    let receipts: [Receipt]
    let timesheets: [Timesheet]
    let laborCost: Double
    
    private let aiService = AIService()
    @State private var summary: String = ""
    @State private var isLoading = false
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(ModernDesign.Colors.primary)
                    Text("AI Job Summary")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    Spacer()
                }
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, ModernDesign.Spacing.xl)
                        Spacer()
                    }
                } else if summary.isEmpty {
                    VStack(spacing: ModernDesign.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        Text("No AI summary yet")
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        
                        ModernButton(
                            title: "Generate AI Summary",
                            icon: "sparkles",
                            style: .primary,
                            size: .medium,
                            action: { generateSummary() }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.xl)
                } else {
                    ScrollView {
                        Text(summary)
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    ModernButton(
                        title: "Regenerate",
                        icon: "arrow.clockwise",
                        style: .secondary,
                        size: .small,
                        action: { generateSummary() }
                    )
                }
            }
        }
    }
    
    private func generateSummary() {
        isLoading = true
        Task {
            // NEW PROFIT FORMULA: profit = projectValue - laborCost
            // Receipts are documents only and do NOT affect profit!
            let profit = job.projectValue - laborCost
            let profitMargin = job.projectValue > 0 ? (profit / job.projectValue * 100) : 0
            
            let summaryText = """
            🏗️ Job Analysis for "\(job.jobName)"
            
            Client: \(job.clientName)
            Status: \(job.status.rawValue.uppercased())
            
            💰 Financial Overview
            Project Value: $\(String(format: "%.2f", job.projectValue))
            Amount Paid: $\(String(format: "%.2f", job.amountPaid))
            Balance Due: $\(String(format: "%.2f", job.remainingBalance))
            
            💼 Labor Costs
            Total Labor: $\(String(format: "%.2f", laborCost))
            Timesheets: \(timesheets.count) entries
            
            📊 Profitability
            Net Profit: $\(String(format: "%.2f", profit))
            Profit Margin: \(String(format: "%.1f", profitMargin))%
            
            📁 Documentation
            Receipts Stored: \(receipts.count) documents
            
            📝 Summary
            \(profit > 0 ? "✅ This job is profitable with healthy margins!" : "⚠️ This job needs attention - labor costs are high relative to project value.")
            \(job.remainingBalance > 0 ? "\n💳 Outstanding balance of $\(String(format: "%.2f", job.remainingBalance)) to collect." : "")
            """
            
            await MainActor.run {
                summary = summaryText
                isLoading = false
            }
        }
    }
}

// MARK: - Helper Components
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(ModernDesign.Typography.title3)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            Text(label)
                .font(ModernDesign.Typography.caption)
                .foregroundColor(ModernDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ModernDesign.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(ModernDesign.Radius.medium)
    }
}

struct FinancialBreakdownRow: View {
    let label: String
    let amount: Double
    let color: Color
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isHighlighted ? ModernDesign.Typography.labelLarge : ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .font(isHighlighted ? ModernDesign.Typography.title3 : ModernDesign.Typography.labelLarge)
                .foregroundColor(isHighlighted ? color : ModernDesign.Colors.textPrimary)
        }
        .padding(.vertical, isHighlighted ? ModernDesign.Spacing.xs : 2)
    }
}
