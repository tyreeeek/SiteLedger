import SwiftUI

/// Worker-specific job detail view - NO financial data shown per Blueprint spec
/// Workers should only see:
/// - Job name, client, address, dates
/// - Their own timesheets for this job
/// - Documents (read-only)
/// - Notes
/// - Submit receipts for job expenses
/// NO access to: Project value, amount paid, profit, expenses, income
struct WorkerJobDetailView: View {
    @EnvironmentObject var authService: AuthService
    let job: Job
    @StateObject private var timesheetViewModel = TimesheetViewModel()
    @StateObject private var receiptsViewModel = ReceiptsViewModel()
    @State private var selectedTab = 0
    @State private var showingAddReceipt = false
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header Section
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                HStack {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text(job.jobName)
                                            .font(ModernDesign.Typography.title2)
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
                                        text: job.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                                        color: statusColor(for: job.status),
                                        size: .large
                                    )
                                }
                                
                                Divider()
                                
                                // Location
                                if !job.address.isEmpty {
                                    HStack(spacing: ModernDesign.Spacing.sm) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(ModernDesign.Colors.primary)
                                        Text(job.address)
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                            .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                                    }
                                }
                                
                                // Dates
                                HStack(spacing: ModernDesign.Spacing.xl) {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        HStack(spacing: ModernDesign.Spacing.xs) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 12))
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            Text("Start")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                        }
                                        Text(job.startDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                    }
                                    
                                    if let endDate = job.endDate {
                                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                            HStack(spacing: ModernDesign.Spacing.xs) {
                                                Image(systemName: "calendar")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                                Text("End")
                                                    .font(ModernDesign.Typography.caption)
                                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                            }
                                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(ModernDesign.Typography.label)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        // My Hours Summary
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("My Hours on This Job")
                                        .font(ModernDesign.Typography.title3)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Spacer()
                                }
                                
                                if myTimesheets.isEmpty {
                                    VStack(spacing: ModernDesign.Spacing.md) {
                                        Image(systemName: "clock.badge.questionmark")
                                            .font(.system(size: 36))
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                        Text("No time entries yet")
                                            .font(ModernDesign.Typography.body)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        Text("Clock in from the Clock tab to start tracking hours")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textTertiary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(ModernDesign.Spacing.lg)
                                } else {
                                    // Total hours summary
                                    HStack {
                                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                            Text("Total Hours")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            Text(String(format: "%.2f hrs", totalHours))
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                                            Text("Entries")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            Text("\(myTimesheets.count)")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                        }
                                    }
                                    .padding(ModernDesign.Spacing.md)
                                    .background(ModernDesign.Colors.primary.opacity(0.1))
                                    .cornerRadius(ModernDesign.Radius.medium)
                                    
                                    Divider()
                                    
                                    // Recent time entries
                                    VStack(spacing: ModernDesign.Spacing.sm) {
                                        ForEach(Array(myTimesheets.prefix(5)), id: \.id) { timesheet in
                                            WorkerTimesheetRow(timesheet: timesheet)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        // Submit Receipt Section
                        ModernCard(shadow: true) {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                HStack {
                                    Image(systemName: "receipt.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(ModernDesign.Colors.primary)
                                    Text("Submit Expense")
                                        .font(ModernDesign.Typography.title3)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    Spacer()
                                }
                                
                                Text("Upload receipts for materials, supplies, or expenses for this job")
                                    .font(ModernDesign.Typography.caption)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                
                                Button(action: { showingAddReceipt = true }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                        Text("Upload Receipt")
                                            .font(ModernDesign.Typography.label)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, ModernDesign.Spacing.md)
                                    .background(ModernDesign.Colors.primary)
                                    .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        // Notes Section (if any)
                        if !job.notes.isEmpty {
                            ModernCard(shadow: true) {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                    HStack {
                                        Image(systemName: "note.text")
                                            .font(.system(size: 18))
                                            .foregroundColor(ModernDesign.Colors.primary)
                                        Text("Job Notes")
                                            .font(ModernDesign.Typography.title3)
                                            .foregroundColor(ModernDesign.Colors.textPrimary)
                                        Spacer()
                                    }
                                    
                                    Text(job.notes)
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                }
                            }
                            .padding(.horizontal, ModernDesign.Spacing.lg)
                        }
                    }
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let jobID = job.id {
                Task {
                    await timesheetViewModel.loadTimesheets(for: jobID)
                }
            }
        }
        .sheet(isPresented: $showingAddReceipt) {
            ModernAddReceiptView(preSelectedJob: job)
                .environmentObject(receiptsViewModel)
                .environmentObject(authService)
        }
    }
    
    // Filter timesheets to only show current worker's entries
    private var myTimesheets: [Timesheet] {
        guard let workerID = authService.currentUser?.id else { return [] }
        return timesheetViewModel.timesheets.filter { $0.workerID == workerID }
    }
    
    private var totalHours: Double {
        myTimesheets.reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    private func statusColor(for status: Job.JobStatus) -> Color {
        switch status {
        case .active: return ModernDesign.Colors.success
        case .completed: return ModernDesign.Colors.primary
        case .onHold: return ModernDesign.Colors.warning
        }
    }
}

struct WorkerTimesheetRow: View {
    let timesheet: Timesheet
    
    var durationText: String {
        guard timesheet.clockOut != nil else { return "In progress..." }
        let hours = timesheet.hours ?? 0
        return String(format: "%.2f hrs", hours)
    }
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                if let clockIn = timesheet.clockIn {
                    Text(clockIn.formatted(date: .abbreviated, time: .shortened))
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                }
                
                if let clockOut = timesheet.clockOut {
                    Text("→ \(clockOut.formatted(date: .omitted, time: .shortened))")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                Text(durationText)
                    .font(ModernDesign.Typography.labelLarge)
                    .foregroundColor(timesheet.clockOut != nil ? ModernDesign.Colors.primary : ModernDesign.Colors.warning)
                
                if timesheet.clockOut != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesign.Colors.success)
                } else {
                    Image(systemName: "clock.badge.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ModernDesign.Colors.warning)
                }
            }
        }
        .padding(ModernDesign.Spacing.md)
        .background(ModernDesign.Colors.background)
        .cornerRadius(ModernDesign.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: ModernDesign.Radius.medium)
                .stroke(ModernDesign.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        WorkerJobDetailView(job: Job(
            ownerID: "owner123",
            jobName: "Kitchen Renovation",
            clientName: "John Smith",
            address: "123 Main St",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30),
            status: .active,
            notes: "Complete kitchen remodel with new cabinets and countertops",
            createdAt: Date(),
            projectValue: 25000,
            amountPaid: 10000
        ))
        .environmentObject(AuthService())
    }
}
