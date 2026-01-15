import SwiftUI

struct JobDetailView: View {
    let initialJob: Job
    @StateObject private var viewModel = JobsViewModel()
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    @State private var job: Job
    @State private var showingAddReceipt = false
    @State private var showingJobSummary = false
    @State private var aiSummary = ""
    @State private var selectedTab = 0
    @State private var showingAssignWorkers = false
    
    init(job: Job) {
        self.initialJob = job
        self._job = State(initialValue: job)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Header Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                    Text(job.jobName)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(job.clientName)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Spacer()
                                StatusBadge(status: job.status)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            HStack(spacing: DesignSystem.Spacing.large) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                    Label("Address", systemImage: "location.fill")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(job.address)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                            }
                            
                            HStack(spacing: DesignSystem.Spacing.large) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                    Label("Start", systemImage: "calendar")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text(job.startDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                if let endDate = job.endDate {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                        Label("End", systemImage: "calendar")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                        Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(DesignSystem.Spacing.cardPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                        
                        // Financial Summary Cards
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            FinancialCard(title: "Project Value", amount: job.projectValue, icon: "briefcase.fill", type: .balance)
                            FinancialCard(title: "Amount Paid", amount: job.amountPaid, icon: "creditcard.fill", type: .balance)
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            FinancialCard(title: "Remaining", amount: job.remainingBalance, icon: "hourglass", type: .balance)
                            FinancialCard(title: "Receipts", amount: totalReceiptsAmount, icon: "doc.text.fill", type: .balance)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            HStack {
                                Text("Profit")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", profit))")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(profit >= 0 ? AppTheme.profitColor : AppTheme.errorColor)
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background((profit >= 0 ? AppTheme.profitColor : AppTheme.errorColor).opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        
                        // Tab Navigation
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                TabButton(title: "Overview", isSelected: selectedTab == 0) {
                                    selectedTab = 0
                                }
                                TabButton(title: "Receipts", isSelected: selectedTab == 1) {
                                    selectedTab = 1
                                }
                                TabButton(title: "Timesheets", isSelected: selectedTab == 2) {
                                    selectedTab = 2
                                }
                                TabButton(title: "Documents", isSelected: selectedTab == 3) {
                                    selectedTab = 3
                                }
                                TabButton(title: "AI Summary", isSelected: selectedTab == 4) {
                                    selectedTab = 4
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                        }
                        
                        // Tab Content
                        Group {
                            switch selectedTab {
                            case 0:
                                OverviewTabView(
                                    job: job,
                                    receiptsTotal: totalReceiptsAmount,
                                    profit: profit,
                                    receipts: viewModel.receipts,
                                    timesheets: timesheetViewModel.timesheets,
                                    workers: viewModel.workers
                                )
                            case 1:
                                ReceiptsTabView(receipts: viewModel.receipts, showingAddReceipt: $showingAddReceipt)
                            case 2:
                                TimesheetsTabView(jobID: job.id ?? "", timesheets: timesheetViewModel.timesheets)
                            case 3:
                                DocumentsTabView(jobID: job.id ?? "")
                            case 4:
                                AISummaryTabView(job: job, receipts: viewModel.receipts)
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAssignWorkers = true }) {
                    HStack(spacing: DesignSystem.Spacing.tiny) {
                        Image(systemName: "person.2.fill")
                        if let workerCount = job.assignedWorkers?.count, workerCount > 0 {
                            Text("\(workerCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .onAppear {
            if let jobID = job.id {
                viewModel.loadReceiptsForJob(jobID: jobID)
                Task {
                    await timesheetViewModel.loadTimesheets(for: jobID)
                }
                // Load all workers for accurate labor cost calculations
                if let ownerID = job.ownerID as String? {
                    viewModel.loadWorkers(ownerID: ownerID)
                }
            }
        } 
        .sheet(isPresented: $showingAddReceipt) {
            Text("Add Receipt View")
        }
        .sheet(isPresented: $showingAssignWorkers) {
            AssignWorkersView(job: job)
                .environmentObject(viewModel)
        }
        .onChange(of: showingAssignWorkers) {
            if !showingAssignWorkers {
                // Refresh job data when assignment sheet closes
                Task {
                    if let jobID = job.id {
                        await viewModel.reloadJob(jobID: jobID)
                        // Update local job state with refreshed data
                        if let updatedJob = viewModel.jobs.first(where: { $0.id == jobID }) {
                            await MainActor.run {
                                self.job = updatedJob
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Total receipts amount for display only.
    /// Receipts are documents and do NOT affect profit calculations.
    private var totalReceiptsAmount: Double {
        viewModel.receipts.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    /// PROFIT FORMULA: profit = projectValue - laborCost - receiptExpenses
    private var profit: Double {
        // Calculate actual labor cost from timesheets × worker hourly rates
        let laborCost = job.calculateLaborCost(timesheets: timesheetViewModel.timesheets, workers: viewModel.workers)
        let receiptExpenses = viewModel.receipts.reduce(0) { $0 + ($1.amount ?? 0) }
        return job.calculateProfit(laborCost: laborCost, receiptExpenses: receiptExpenses)
    }
}

struct FinancialRow: View {
    let title: String
    let value: Double
    let color: Color
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.textSecondary)
                .fontWeight(isBold ? .semibold : .regular)
            Spacer()
            Text("$\(String(format: "%.2f", value))")
                .foregroundColor(color)
                .fontWeight(isBold ? .bold : .semibold)
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack {
            // Receipts are documents only - neutral icon
            Image(systemName: "doc.text.fill")
                .foregroundColor(AppTheme.primaryColor)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text(receipt.vendor ?? "Unknown Vendor")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Text((receipt.date ?? Date()).localDateString)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Text("$\(String(format: "%.2f", receipt.amount ?? 0))")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, 8)
    }
}

struct AISummaryView: View {
    @Environment(\.dismiss) var dismiss
    let summary: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppTheme.primaryColor)
                            Text("AI Job Summary")
                                .font(.headline)
                        }
                        
                        Text(summary)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding()
            }
            .background(AppTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Job Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OverviewTabView: View {
    let job: Job
    let receiptsTotal: Double  // Receipt expenses - subtracted from profit
    let profit: Double
    let receipts: [Receipt]
    let timesheets: [Timesheet]
    let workers: [User]  // For accurate labor cost calculations
    
    /// Calculate labor cost from timesheets
    private var laborCost: Double {
        job.calculateLaborCost(timesheets: timesheets, workers: workers)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // Metrics Summary Cards
            MetricsSummaryView(job: job, receipts: receipts, timesheets: timesheets, workers: workers)
                .padding(.horizontal)
            
            // Receipts Chart (documents only - for reference)
            if !receipts.isEmpty {
                VendorReceiptsChart(receipts: receipts)
                    .padding(.horizontal)
            }
            
            // Labor Cost Trend (if timesheets exist)
            if !timesheets.isEmpty {
                LaborCostTrendChart(timesheets: timesheets)
                    .padding(.horizontal)
            }
            
            // Financial Details Card
            CardView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                    Text("Financial Details")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Divider()
                    
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        HStack {
                            Text("Project Value (Contract)")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("$\(String(format: "%.2f", job.projectValue))")
                                .foregroundColor(AppTheme.primaryColor)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Amount Paid by Client")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("$\(String(format: "%.2f", job.amountPaid))")
                                .foregroundColor(AppTheme.successColor)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Remaining Balance")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("$\(String(format: "%.2f", job.remainingBalance))")
                                .foregroundColor(job.remainingBalance > 0 ? AppTheme.warningColor : AppTheme.successColor)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Labor Cost")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("-$\(String(format: "%.2f", laborCost))")
                                .foregroundColor(AppTheme.warningColor)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Receipt Expenses")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("-$\(String(format: "%.2f", receiptsTotal))")
                                .foregroundColor(AppTheme.errorColor)
                                .fontWeight(.semibold)
                        }
                        
                        Divider()
                        
                        // Show profit calculation
                        Text("Profit = Project Value - Labor - Expenses")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        
                        HStack {
                            Text("Net Profit")
                                .foregroundColor(AppTheme.textPrimary)
                                .fontWeight(.bold)
                            Spacer()
                            Text("$\(String(format: "%.2f", profit))")
                                .foregroundColor(profit >= 0 ? AppTheme.successColor : AppTheme.errorColor)
                                .fontWeight(.bold)
                                .font(.title3)
                        }
                    }
                    
                    if !job.notes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(job.notes)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ReceiptsTabView: View {
    let receipts: [Receipt]
    @Binding var showingAddReceipt: Bool
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack {
                    Text("Receipts")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button(action: { showingAddReceipt = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primaryColor)
                            .font(.title3)
                    }
                }
                
                if receipts.isEmpty {
                    EmptyStateView(
                        icon: "receipt",
                        title: "No Receipts Yet",
                        message: "Add receipts to store documents for this job.",
                        action: nil,
                        buttonTitle: nil
                    )
                    .padding(.vertical, DesignSystem.Spacing.large)
                } else {
                    ForEach(receipts.filter { $0.id != nil }) { receipt in
                        ReceiptRowView(receipt: receipt)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TimesheetsTabView: View {
    let jobID: String
    let timesheets: [Timesheet]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Timesheets")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primaryColor)
                            .font(.title3)
                    }
                }
                
                if timesheets.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Time Entries Yet",
                        message: "Workers will clock in and out to track hours on this job.",
                        action: nil,
                        buttonTitle: nil
                    )
                    .padding(.vertical, DesignSystem.Spacing.large)
                } else {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        HStack {
                            Text("Total Hours")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f hrs", totalHours))
                                .foregroundColor(AppTheme.primaryColor)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppTheme.primaryColor.opacity(0.1))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        ForEach(timesheets, id: \.id) { timesheet in
                            TimesheetRowView(timesheet: timesheet)
                                .id(timesheet.id ?? UUID().uuidString)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var totalHours: Double {
        timesheets.reduce(0) { $0 + ($1.hours ?? 0) }
    }
}

struct DocumentsTabView: View {
    let jobID: String
    @StateObject private var viewModel = DocumentsViewModel()
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack {
                    Text("Documents")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.primaryColor)
                            .font(.title3)
                    }
                }
                
                if viewModel.documents.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Documents Yet",
                        message: "Upload contracts, invoices, and other project documents.",
                        action: nil,
                        buttonTitle: nil
                    )
                    .padding(.vertical, DesignSystem.Spacing.large)
                } else {
                    ForEach(viewModel.documents, id: \.id) { document in
                        DocumentRowView(document: document)
                            .id(document.id ?? UUID().uuidString)
                    }
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            viewModel.loadDocumentsForJob(jobID: jobID)
        }
    }
}

struct AISummaryTabView: View {
    let job: Job
    let receipts: [Receipt]
    @State private var aiSummary = ""
    @State private var isLoading = false
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.primaryColor)
                    Text("AI Summary")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                if aiSummary.isEmpty && !isLoading {
                    VStack(spacing: DesignSystem.Spacing.standard) {
                        Image(systemName: "brain")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.primaryColor.opacity(0.5))
                        
                        Text("Get AI-powered insights about this job")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        PrimaryButton(
                            title: "Generate AI Summary",
                            action: generateAISummary,
                            isLoading: isLoading
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else if isLoading {
                    VStack(spacing: DesignSystem.Spacing.standard) {
                        ProgressView()
                        Text("Analyzing job data...")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
                        Text(aiSummary)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Button(action: { generateAISummary() }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Regenerate")
                            }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryColor)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func generateAISummary() {
        isLoading = true
        Task {
            // NEW PROFIT FORMULA: profit = projectValue - laborCost
            // Receipts are documents only and do NOT affect profit!
            // Note: For full profit calculation with labor costs, use JobsViewModel
            // This simplified view shows contract value and payment status
            
            let summary = """
            🏗️ Job Analysis for "\(job.jobName)"
            
            Client: \(job.clientName)
            Status: \(job.status.rawValue.uppercased())
            
            💰 Financial Overview
            Contract Value: $\(String(format: "%.2f", job.projectValue))
            Amount Paid: $\(String(format: "%.2f", job.amountPaid))
            Remaining: $\(String(format: "%.2f", job.remainingBalance))
            
            📊 Summary
            Documents Stored: \(receipts.count) receipts
            Payment Progress: \(String(format: "%.1f%%", (job.amountPaid / job.projectValue) * 100))
            
            📝 Notes
            \(job.remainingBalance > 0 ? "💰 Outstanding balance: $\(String(format: "%.2f", job.remainingBalance))" : "✅ Fully paid!")
            Note: For detailed profit analysis with labor costs, view the Overview tab.
            """
            
            await MainActor.run {
                aiSummary = summary
                isLoading = false
            }
        }
    }
}

struct TimesheetRowView: View {
    let timesheet: Timesheet
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(AppTheme.primaryColor)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text((timesheet.clockIn ?? Date()).formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                if let notes = timesheet.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Text("\(String(format: "%.2f", timesheet.hours ?? 0)) hrs")
                .font(.headline)
                .foregroundColor(AppTheme.primaryColor)
        }
        .padding(.vertical, 8)
    }
}

struct DocumentRowView: View {
    let document: Document
    
    var body: some View {
        HStack {
            Image(systemName: document.fileType == .pdf ? "doc.fill" : "photo.fill")
                .foregroundColor(AppTheme.primaryColor)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                Text(document.title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                Text(document.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textSecondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - TabButton Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primaryColor : AppTheme.cardBackground)
                .cornerRadius(8)
        }
    }
}
