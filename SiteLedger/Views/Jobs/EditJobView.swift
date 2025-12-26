import SwiftUI

struct EditJobView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    
    let job: Job
    
    @State private var jobName: String
    @State private var clientName: String
    @State private var address: String
    @State private var projectValue: String
    @State private var amountPaid: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var status: Job.JobStatus
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    
    init(job: Job) {
        self.job = job
        _jobName = State(initialValue: job.jobName)
        _clientName = State(initialValue: job.clientName)
        _address = State(initialValue: job.address)
        _projectValue = State(initialValue: String(format: "%.2f", job.projectValue))
        _amountPaid = State(initialValue: String(format: "%.2f", job.amountPaid))
        _startDate = State(initialValue: job.startDate)
        _endDate = State(initialValue: job.endDate ?? Date())
        _notes = State(initialValue: job.notes)
        _status = State(initialValue: job.status)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Edit Job")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            
                            Text("Update job details and financials")
                                .font(ModernDesign.Typography.body)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Job Information
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Job Information")
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    ModernTextField(
                                        placeholder: "Job Name",
                                        text: $jobName,
                                        icon: "hammer.fill"
                                    )
                                    
                                    ModernTextField(
                                        placeholder: "Client Name",
                                        text: $clientName,
                                        icon: "person.fill"
                                    )
                                    
                                    ModernTextField(
                                        placeholder: "Address",
                                        text: $address,
                                        icon: "location.fill"
                                    )
                                }
                            }
                        }
                        
                        // Financial Details
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Financial Details")
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    ModernCurrencyField(
                                        label: "Project Value",
                                        amount: $projectValue,
                                        color: ModernDesign.Colors.primary
                                    )
                                    
                                    ModernCurrencyField(
                                        label: "Amount Paid",
                                        amount: $amountPaid,
                                        color: ModernDesign.Colors.success
                                    )
                                    
                                    // Remaining Balance Display
                                    HStack {
                                        Text("Remaining Balance")
                                            .font(ModernDesign.Typography.label)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        Spacer()
                                        Text("$\(String(format: "%.2f", remainingBalance))")
                                            .font(ModernDesign.Typography.title3)
                                            .foregroundColor(remainingBalance > 0 ? ModernDesign.Colors.warning : ModernDesign.Colors.success)
                                    }
                                    .padding(ModernDesign.Spacing.md)
                                    .background(remainingBalance > 0 ? ModernDesign.Colors.warning.opacity(0.1) : ModernDesign.Colors.success.opacity(0.1))
                                    .cornerRadius(ModernDesign.Radius.medium)
                                }
                            }
                        }
                        
                        // Status & Dates
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(title: "Status & Timeline")
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    // Status Selector
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Status")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        HStack(spacing: ModernDesign.Spacing.sm) {
                                            StatusButton(
                                                title: "Active",
                                                icon: "play.circle.fill",
                                                isSelected: status == .active,
                                                color: ModernDesign.Colors.info
                                            ) {
                                                HapticsManager.shared.selection()
                                                status = .active
                                            }
                                            
                                            StatusButton(
                                                title: "On Hold",
                                                icon: "pause.circle.fill",
                                                isSelected: status == .onHold,
                                                color: ModernDesign.Colors.warning
                                            ) {
                                                HapticsManager.shared.selection()
                                                status = .onHold
                                            }
                                            
                                            StatusButton(
                                                title: "Complete",
                                                icon: "checkmark.circle.fill",
                                                isSelected: status == .completed,
                                                color: ModernDesign.Colors.success
                                            ) {
                                                HapticsManager.shared.selection()
                                                status = .completed
                                            }
                                        }
                                    }
                                    
                                    // Dates
                                    HStack(spacing: ModernDesign.Spacing.md) {
                                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                            Text("Start Date")
                                                .font(ModernDesign.Typography.labelSmall)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                                .labelsHidden()
                                                .tint(ModernDesign.Colors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                            Text("End Date")
                                                .font(ModernDesign.Typography.labelSmall)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                                .labelsHidden()
                                                .tint(ModernDesign.Colors.primary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Notes",
                                    subtitle: "Optional"
                                )
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(ModernDesign.Spacing.sm)
                                    .background(ModernDesign.Colors.background)
                                    .cornerRadius(ModernDesign.Radius.small)
                                    .font(ModernDesign.Typography.body)
                            }
                        }
                        
                        // Error Message
                        if showError {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(ModernDesign.Colors.error)
                                Text(errorMessage)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.error)
                                Spacer()
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.error.opacity(0.1))
                            .cornerRadius(ModernDesign.Radius.medium)
                        }
                        
                        // Save Button
                        ModernButton(
                            title: "Save Changes",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .large,
                            action: saveJob,
                            isLoading: isLoading
                        )
                        
                        // Delete Button
                        Button(action: {
                            HapticsManager.shared.medium()
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                Image(systemName: "trash.fill")
                                Text("Delete Job")
                            }
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.error)
                        }
                        .padding(.top, ModernDesign.Spacing.md)
                    }
                    .padding(ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticsManager.shared.light()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
            }
            .alert("Delete Job", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteJob()
                }
            } message: {
                Text("Are you sure you want to delete this job? This action cannot be undone.")
            }
        }
    }
    
    private var remainingBalance: Double {
        let pv = Double(projectValue) ?? 0
        let ap = Double(amountPaid) ?? 0
        return pv - ap
    }
    
    private func saveJob() {
        // Validate required fields
        guard !jobName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please fill in job name and client name"
            showError = true
            return
        }
        
        guard let projectValueDouble = Double(projectValue), projectValueDouble > 0 else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a valid project value"
            showError = true
            return
        }
        
        // Validate dates
        guard endDate >= startDate else {
            HapticsManager.shared.error()
            errorMessage = "End date must be after start date"
            showError = true
            return
        }
        
        let amountPaidDouble = Double(amountPaid) ?? 0.0
        
        // Validate amount paid doesn't exceed project value
        guard amountPaidDouble <= projectValueDouble else {
            HapticsManager.shared.error()
            errorMessage = "Amount paid cannot exceed project value"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        var updatedJob = job
        updatedJob.jobName = jobName
        updatedJob.clientName = clientName
        updatedJob.address = address
        updatedJob.projectValue = projectValueDouble
        updatedJob.amountPaid = amountPaidDouble
        updatedJob.startDate = startDate
        updatedJob.endDate = endDate
        updatedJob.status = status
        updatedJob.notes = notes
        
        // Build updates dictionary for API
        let dateFormatter = ISO8601DateFormatter()
        var updates: [String: Any] = [
            "jobName": jobName,
            "clientName": clientName,
            "address": address,
            "projectValue": projectValueDouble,
            "amountPaid": amountPaidDouble,
            "startDate": dateFormatter.string(from: startDate),
            "status": status.rawValue,
            "notes": notes
        ]
        
        // Always include endDate since user may have edited it
        updates["endDate"] = dateFormatter.string(from: endDate)
        
        Task {
            do {
                try await viewModel.updateJob(updatedJob, with: updates)
                await MainActor.run {
                    HapticsManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HapticsManager.shared.error()
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteJob() {
        guard job.id != nil else { return }
        
        Task {
            do {
                try await viewModel.deleteJob(job)
                await MainActor.run {
                    HapticsManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    HapticsManager.shared.error()
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
