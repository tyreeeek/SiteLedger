import SwiftUI

/// Main payroll dashboard for owner/admin to see all workers and their payment status
struct WorkerPayrollView: View {
    @StateObject private var viewModel = WorkerPaymentViewModel()
    @EnvironmentObject var authService: AuthService
    
    @State private var showAllPayments = false
    @State private var selectedWorkerForPayment: WorkerPayrollSummary?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Summary Cards
                    summaryCardsSection
                    
                    // Workers List
                    workersSection
                }
                .padding()
            }
            .background(ModernDesign.Colors.background)
            .navigationTitle("Payroll")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAllPayments = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(ModernDesign.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAllPayments) {
                AllPaymentsHistoryView(viewModel: viewModel)
            }
            .sheet(item: $selectedWorkerForPayment) { summary in
                if let worker = viewModel.getWorker(summary.workerID) {
                    RecordPaymentSheet(
                        worker: worker,
                        summary: summary,
                        viewModel: viewModel
                    )
                }
            }
            .onAppear {
                if let userID = authService.currentUser?.id {
                    viewModel.loadPayrollData(ownerID: userID)
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCardsSection: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            // Total Balance Owed
            HStack(spacing: ModernDesign.Spacing.md) {
                PayrollSummaryCard(
                    title: "Balance Owed",
                    value: viewModel.formatCurrency(viewModel.totalBalanceOwed),
                    subtitle: "To all workers",
                    icon: "dollarsign.circle.fill",
                    color: viewModel.totalBalanceOwed > 0 ? ModernDesign.Colors.warning : ModernDesign.Colors.success
                )
                
                PayrollSummaryCard(
                    title: "Paid This Month",
                    value: viewModel.formatCurrency(viewModel.totalPaidThisMonth),
                    subtitle: "All workers",
                    icon: "checkmark.circle.fill",
                    color: ModernDesign.Colors.success
                )
            }
            
            HStack(spacing: ModernDesign.Spacing.md) {
                PayrollSummaryCard(
                    title: "Paid This Week",
                    value: viewModel.formatCurrency(viewModel.totalPaidThisWeek),
                    subtitle: "7 days",
                    icon: "calendar",
                    color: ModernDesign.Colors.info
                )
                
                PayrollSummaryCard(
                    title: "Workers",
                    value: "\(viewModel.workers.count)",
                    subtitle: "Active team",
                    icon: "person.2.fill",
                    color: ModernDesign.Colors.primary
                )
            }
        }
    }
    
    // MARK: - Workers Section
    
    private var workersSection: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
            Text("Workers")
                .font(ModernDesign.Typography.title2)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.workerSummaries.isEmpty {
                EmptyWorkersView()
            } else {
                ForEach(viewModel.workerSummaries) { summary in
                    WorkerPayrollCard(summary: summary) {
                        selectedWorkerForPayment = summary
                    }
                }
            }
        }
    }
}

// MARK: - Payroll Summary Card

struct PayrollSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(ModernDesign.Typography.title2)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Text(title)
                .font(ModernDesign.Typography.caption)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            
            Text(subtitle)
                .font(ModernDesign.Typography.captionSmall)
                .foregroundColor(ModernDesign.Colors.textTertiary)
        }
        .padding(ModernDesign.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ModernDesign.Colors.cardBackground)
        .cornerRadius(ModernDesign.Radius.medium)
    }
}

// MARK: - Worker Payroll Card

struct WorkerPayrollCard: View {
    let summary: WorkerPayrollSummary
    let onRecordPayment: () -> Void
    
    private var balanceColor: Color {
        if summary.balanceOwed > 0 {
            return ModernDesign.Colors.warning
        } else if summary.balanceOwed < 0 {
            return ModernDesign.Colors.error
        } else {
            return ModernDesign.Colors.success
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Worker Avatar
                ZStack {
                    Circle()
                        .fill(ModernDesign.Colors.primary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Text(summary.workerName.prefix(1).uppercased())
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.workerName)
                        .font(ModernDesign.Typography.labelLarge)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    Text("$\(String(format: "%.2f", summary.hourlyRate))/hr")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                // Balance Owed
                VStack(alignment: .trailing, spacing: 2) {
                    Text(summary.balanceOwed >= 0 ? "$\(String(format: "%.2f", summary.balanceOwed))" : "-$\(String(format: "%.2f", abs(summary.balanceOwed)))")
                        .font(ModernDesign.Typography.title3)
                        .foregroundColor(balanceColor)
                    
                    Text(summary.balanceOwed > 0 ? "owed" : "settled")
                        .font(ModernDesign.Typography.captionSmall)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                }
            }
            .padding(ModernDesign.Spacing.md)
            
            Divider()
            
            // Stats Row
            HStack(spacing: ModernDesign.Spacing.lg) {
                StatItem(label: "Hours", value: String(format: "%.2f", summary.totalHoursWorked))
                StatItem(label: "Earned", value: "$\(String(format: "%.2f", summary.totalEarnings))")
                StatItem(label: "Paid", value: "$\(String(format: "%.2f", summary.totalPaid))")
                StatItem(label: "Payments", value: "\(summary.paymentCount)")
            }
            .padding(ModernDesign.Spacing.md)
            
            // Record Payment Button (only show if balance owed > 0)
            if summary.balanceOwed > 0 {
                Divider()
                
                Button(action: onRecordPayment) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("Record Payment")
                    }
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(ModernDesign.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ModernDesign.Spacing.md)
                }
            }
        }
        .background(ModernDesign.Colors.cardBackground)
        .cornerRadius(ModernDesign.Radius.medium)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(ModernDesign.Typography.label)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Text(label)
                .font(ModernDesign.Typography.captionSmall)
                .foregroundColor(ModernDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State

struct EmptyWorkersView: View {
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(ModernDesign.Colors.textTertiary)
            
            Text("No Workers Yet")
                .font(ModernDesign.Typography.title3)
                .foregroundColor(ModernDesign.Colors.textPrimary)
            
            Text("Add workers to your team to track their hours and payments")
                .font(ModernDesign.Typography.body)
                .foregroundColor(ModernDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - All Payments History

struct AllPaymentsHistoryView: View {
    @ObservedObject var viewModel: WorkerPaymentViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.payments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Payments Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Payment history will appear here after you pay workers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(viewModel.payments, id: \.id) { payment in
                        PaymentHistoryRow(payment: payment)
                            .id(payment.id ?? UUID().uuidString)
                    }
                }
            }
            .navigationTitle("Payment History")
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

struct PaymentHistoryRow: View {
    let payment: WorkerPayment
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack {
            // Worker Avatar
            ZStack {
                Circle()
                    .fill(ModernDesign.Colors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(payment.workerName.prefix(1).uppercased())
                    .font(ModernDesign.Typography.label)
                    .foregroundColor(ModernDesign.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.workerName)
                    .font(ModernDesign.Typography.labelLarge)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: payment.paymentMethod.icon)
                        .font(.system(size: 10))
                    Text(payment.paymentMethod.displayName)
                }
                .font(ModernDesign.Typography.caption)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", payment.amount))")
                    .font(ModernDesign.Typography.labelLarge)
                    .foregroundColor(ModernDesign.Colors.success)
                
                Text(dateFormatter.string(from: payment.paymentDate))
                    .font(ModernDesign.Typography.captionSmall)
                    .foregroundColor(ModernDesign.Colors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Record Payment Sheet

struct RecordPaymentSheet: View {
    let worker: User
    let summary: WorkerPayrollSummary
    @ObservedObject var viewModel: WorkerPaymentViewModel
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var amount: String = ""
    @State private var paymentMethod: WorkerPayment.PaymentMethod = .cash
    @State private var notes: String = ""
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var amountValue: Double {
        Double(amount) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Worker Info
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(ModernDesign.Colors.primary.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Text(worker.name.prefix(1).uppercased())
                                .font(ModernDesign.Typography.title3)
                                .foregroundColor(ModernDesign.Colors.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(worker.name)
                                .font(ModernDesign.Typography.labelLarge)
                            Text("Balance: $\(String(format: "%.2f", summary.balanceOwed))")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.warning)
                        }
                    }
                }
                
                // Amount
                Section("Payment Amount") {
                    HStack {
                        Text("$")
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    // Quick amount buttons
                    HStack(spacing: ModernDesign.Spacing.sm) {
                        Button {
                            amount = String(format: "%.2f", summary.balanceOwed)
                        } label: {
                            Text("Full")
                                .font(ModernDesign.Typography.captionSmall)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                .foregroundColor(ModernDesign.Colors.primary)
                                .cornerRadius(ModernDesign.Radius.small)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            amount = String(format: "%.2f", summary.balanceOwed / 2)
                        } label: {
                            Text("Half")
                                .font(ModernDesign.Typography.captionSmall)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                .foregroundColor(ModernDesign.Colors.primary)
                                .cornerRadius(ModernDesign.Radius.small)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            amount = "100.00"
                        } label: {
                            Text("$100")
                                .font(ModernDesign.Typography.captionSmall)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                .foregroundColor(ModernDesign.Colors.primary)
                                .cornerRadius(ModernDesign.Radius.small)
                        }
                        .buttonStyle(.borderless)
                        
                        Button {
                            amount = "500.00"
                        } label: {
                            Text("$500")
                                .font(ModernDesign.Typography.captionSmall)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ModernDesign.Colors.primary.opacity(0.1))
                                .foregroundColor(ModernDesign.Colors.primary)
                                .cornerRadius(ModernDesign.Radius.small)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                // Payment Method
                Section("Payment Method") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(WorkerPayment.PaymentMethod.allCases, id: \.self) { method in
                            Label(method.displayName, systemImage: method.icon)
                                .tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Notes
                Section("Notes (Optional)") {
                    TextField("Add a note...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        recordPayment()
                    }
                    .fontWeight(.semibold)
                    .disabled(amountValue <= 0 || isProcessing)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func recordPayment() {
        guard let workerID = worker.id else {
            errorMessage = "Worker ID not found"
            showError = true
            return
        }
        
        guard let ownerID = authService.currentUser?.id else {
            errorMessage = "Please log in again"
            showError = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Use current date for both payment date and period
                let now = Date()
                let periodStart = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
                
                try await viewModel.createPayment(
                    ownerID: ownerID,
                    workerID: workerID,
                    workerName: worker.name,
                    amount: amountValue,
                    paymentDate: now,
                    periodStart: periodStart,
                    periodEnd: now,
                    hoursWorked: summary.totalHoursWorked,
                    hourlyRate: worker.hourlyRate ?? 0,
                    paymentMethod: paymentMethod,
                    notes: notes.isEmpty ? nil : notes,
                    referenceNumber: nil
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    WorkerPayrollView()
        .environmentObject(AuthService())
}
