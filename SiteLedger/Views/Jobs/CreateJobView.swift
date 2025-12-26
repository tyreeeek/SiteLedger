import SwiftUI

struct CreateJobView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    
    @State private var jobName = ""
    @State private var clientName = ""
    @State private var address = ""
    @State private var projectValue = ""
    @State private var amountPaid = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var status: Job.JobStatus = .active
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Header
                        ScreenHeader(
                            title: "Create Job",
                            subtitle: "Enter job details to get started",
                            action: nil,
                            actionIcon: nil
                        )
                        
                        VStack(spacing: DesignSystem.Spacing.cardSpacing) {
                            // Basic Info Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Job Information")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                CustomTextField(placeholder: "Job Name *", text: $jobName)
                                CustomTextField(placeholder: "Client Name *", text: $clientName)
                                CustomTextField(placeholder: "Address", text: $address)
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Financial Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Financial Details")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                CurrencyField(label: "Project Value *", amount: $projectValue)
                                CurrencyField(label: "Amount Paid", amount: $amountPaid)
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Dates & Status Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Timeline & Status")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                    Text("Start Date")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    DatePicker("", selection: $startDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                    Text("End Date")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    DatePicker("", selection: $endDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                    Text("Status")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Picker("Status", selection: $status) {
                                        Text("Active").tag(Job.JobStatus.active)
                                        Text("Completed").tag(Job.JobStatus.completed)
                                        Text("On Hold").tag(Job.JobStatus.onHold)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Notes Section
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Additional Notes")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .padding(DesignSystem.Spacing.small)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(AppTheme.smallCornerRadius)
                                    .font(DesignSystem.TextStyle.caption)
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                            
                            // Error Message
                            if showError {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(AppTheme.errorColor)
                                    Text(errorMessage)
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(AppTheme.errorColor)
                                    Spacer()
                                }
                                .padding(DesignSystem.Spacing.cardPadding)
                                .background(AppTheme.errorColor.opacity(0.1))
                                .cornerRadius(AppTheme.cornerRadius)
                            }
                            
                            // Create Button
                            PrimaryButton(title: "Create Job", action: createJob, isLoading: isLoading)
                                .padding(.top, DesignSystem.Spacing.medium)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    }
                    .padding(.top, DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { 
                        HapticsManager.shared.light()
                        dismiss() 
                    }) {
                        HStack(spacing: DesignSystem.Spacing.tiny) {
                            Image(systemName: "chevron.left")
                            Text("Cancel")
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createJob() {
        guard !jobName.isEmpty, !clientName.isEmpty else {
            HapticsManager.shared.error()
            errorMessage = "Please fill in required fields"
            showError = true
            return
        }
        
        guard let projectValueDouble = Double(projectValue), projectValueDouble >= 0 else {
            HapticsManager.shared.error()
            errorMessage = "Please enter a valid project value"
            showError = true
            return
        }
        
        let amountPaidDouble = Double(amountPaid) ?? 0.0
        
        guard let ownerID = authService.currentUser?.id else { return }
        
        let job = Job(
            ownerID: ownerID,
            jobName: jobName,
            clientName: clientName,
            address: address,
            startDate: startDate,
            endDate: endDate,
            status: status,
            notes: notes,
            createdAt: Date(),
            projectValue: projectValueDouble,
            amountPaid: amountPaidDouble,
            assignedWorkers: nil
        )
        
        isLoading = true
        showError = false
        
        Task {
            do {
                try await viewModel.createJob(job)
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
}
