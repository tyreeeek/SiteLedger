import SwiftUI

struct    // Geofence fields
    @State private var geofenceEnabled = false
    @State private var geofenceRadius = "100"
    
    var body: some View {CreateJobView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    @StateObject private var workersViewModel = WorkersViewModel()
    
    @State private var jobName = ""
    @State private var clientName = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var projectValue = ""
    @State private var amountPaid = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var status: Job.JobStatus = .active
    @State private var selectedWorkerIDs: Set<String> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Geofence fields
    @State private var geofenceEnabled = false
    @State private var geofenceLatitude = ""
    @State private var geofenceLongitude = ""
    @State private var geofenceRadius = "100"
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Create Job")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                .adaptiveText(allowsMultipleLines: false, minimumScaleFactor: 0.85)
                            
                            Text("Enter job details to get started")
                                .font(ModernDesign.Typography.body)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Job Information
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Job Information"
                                )
                                
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
                                    
                                    // Split Address Fields
                                    ModernTextField(
                                        placeholder: "Street Address",
                                        text: $street,
                                        icon: "location.fill"
                                    )
                                    
                                    HStack(spacing: ModernDesign.Spacing.sm) {
                                        ModernTextField(
                                            placeholder: "City",
                                            text: $city,
                                            icon: "building.2.fill"
                                        )
                                        
                                        ModernTextField(
                                            placeholder: "State",
                                            text: $state,
                                            icon: "map.fill"
                                        )
                                    }
                                    
                                    ModernTextField(
                                        placeholder: "Zip Code",
                                        text: $zip,
                                        icon: "number.square.fill"
                                    )
                                }
                            }
                        }
                        
                        // Financial Details
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Financial Details"
                                )
                                
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
                                }
                            }
                        }
                        
                        // Timeline & Status
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Timeline & Status"
                                )
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    // Start Date
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("Start Date")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .tint(ModernDesign.Colors.primary)
                                    }
                                    
                                    // End Date
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                        Text("End Date")
                                            .font(ModernDesign.Typography.labelSmall)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        
                                        DatePicker("", selection: $endDate, displayedComponents: .date)
                                            .labelsHidden()
                                            .tint(ModernDesign.Colors.primary)
                                    }
                                    
                                    // Status
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
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Geofence Time Tracking
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Geofence Time Tracking",
                                    subtitle: "Optional - Require workers to be at job address to clock in"
                                )
                                
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    // Enable toggle
                                    Toggle(isOn: $geofenceEnabled) {
                                        HStack(spacing: ModernDesign.Spacing.xs) {
                                            Image(systemName: "location.circle.fill")
                                                .foregroundColor(ModernDesign.Colors.primary)
                                            Text("Require workers at job address")
                                                .font(ModernDesign.Typography.body)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                        }
                                    }
                                    .tint(ModernDesign.Colors.primary)
                                    
                                    if geofenceEnabled {
                                        VStack(spacing: ModernDesign.Spacing.md) {
                                            // Show current address
                                            HStack(spacing: ModernDesign.Spacing.sm) {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(ModernDesign.Colors.info)
                                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.tiny) {
                                                    Text("Job Address")
                                                        .font(ModernDesign.Typography.labelSmall)
                                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                                    
                                                    // Construct full address for display
                                                    let components = [street, city, state, zip].filter { !$0.isEmpty }
                                                    let fullAddress = components.isEmpty ? "Enter an address above" : components.joined(separator: ", ")
                                                    
                                                    Text(fullAddress)
                                                        .font(ModernDesign.Typography.body)
                                                        .foregroundColor(components.isEmpty ? ModernDesign.Colors.textTertiary : ModernDesign.Colors.textPrimary)
                                                }
                                                Spacer()
                                            }
                                            .padding(ModernDesign.Spacing.md)
                                            .background(ModernDesign.Colors.info.opacity(0.1))
                                            .cornerRadius(ModernDesign.Radius.medium)
                                            
                                            ModernTextField(
                                                placeholder: "Radius in meters (default: 100)",
                                                text: $geofenceRadius,
                                                icon: "circle.dashed",
                                                keyboardType: .decimalPad
                                            )
                                            
                                            Text("Workers must be within this radius of the job address to clock in. 100 meters ≈ 328 feet")
                                                .font(ModernDesign.Typography.caption)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Assign Workers (Optional)
                        if !workersViewModel.workers.isEmpty {
                            ModernCard(shadow: true) {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    ModernSectionHeader(
                                        title: "Assign Workers",
                                        subtitle: "Optional - Select workers for this job"
                                    )
                                    
                                    VStack(spacing: ModernDesign.Spacing.sm) {
                                        ForEach(workersViewModel.workers) { worker in
                                            WorkerSelectionRow(
                                                worker: worker,
                                                isSelected: selectedWorkerIDs.contains(worker.id ?? "")
                                            ) {
                                                if let workerID = worker.id {
                                                    if selectedWorkerIDs.contains(workerID) {
                                                        selectedWorkerIDs.remove(workerID)
                                                    } else {
                                                        selectedWorkerIDs.insert(workerID)
                                                    }
                                                    HapticsManager.shared.selection()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        ModernCard(shadow: true) {
                            VStack(spacing: ModernDesign.Spacing.lg) {
                                ModernSectionHeader(
                                    title: "Additional Notes",
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
                        
                        // Create Button
                        ModernButton(
                            title: "Create Job",
                            icon: "checkmark.circle.fill",
                            style: .primary,
                            size: .large,
                            action: createJob,
                            isLoading: isLoading
                        )
                        .padding(.top, ModernDesign.Spacing.sm)
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
            .onAppear {
                Task {
                    await workersViewModel.loadWorkers()
                    // Auto-select all workers for new jobs
                    await MainActor.run {
                        selectedWorkerIDs = Set(workersViewModel.workers.compactMap { $0.id })
                    }
                }
            }
        }
    }
    
    private func createJob() {
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
        
        // Validate geofence fields if enabled
        var geofenceRad: Double? = nil
        let fullAddress = [street, city, state, zip].filter { !$0.isEmpty }.joined(separator: ", ")
        
        if geofenceEnabled {
            guard !fullAddress.isEmpty else {
                HapticsManager.shared.error()
                errorMessage = "Please enter a job address for geofence validation"
                showError = true
                return
            }
            
            guard let rad = Double(geofenceRadius), rad > 0 else {
                HapticsManager.shared.error()
                errorMessage = "Please enter a valid geofence radius"
                showError = true
                return
            }
            geofenceRad = rad
        }
        
        guard let ownerID = authService.currentUser?.id else {
            HapticsManager.shared.error()
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        let job = Job(
            ownerID: ownerID,
            jobName: jobName,
            clientName: clientName,
            address: fullAddress, // Kept for backward compatibility
            street: street,
            city: city,
            state: state,
            zip: zip,
            geofenceEnabled: geofenceEnabled ? true : nil,
            geofenceRadius: geofenceRad,
            startDate: startDate,
            endDate: endDate,
            status: status,
            notes: notes,
            createdAt: Date(),
            projectValue: projectValueDouble,
            amountPaid: amountPaidDouble,
            assignedWorkers: selectedWorkerIDs.isEmpty ? nil : Array(selectedWorkerIDs)
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

struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ModernDesign.Colors.textTertiary)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(ModernDesign.Typography.body)
        }
        .padding(ModernDesign.Spacing.md)
        .background(ModernDesign.Colors.background)
        .cornerRadius(ModernDesign.Radius.medium)
    }
}

struct ModernCurrencyField: View {
    let label: String
    @Binding var amount: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
            Text(label)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(ModernDesign.Colors.textSecondary)
            
            HStack(spacing: ModernDesign.Spacing.sm) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                TextField("0.00", text: $amount)
                    .font(ModernDesign.Typography.title3)
                    .keyboardType(.decimalPad)
            }
            .padding(ModernDesign.Spacing.md)
            .background(ModernDesign.Colors.background)
            .cornerRadius(ModernDesign.Radius.medium)
        }
    }
}

struct StatusButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesign.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(ModernDesign.Typography.labelSmall)
            }
            .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ModernDesign.Spacing.sm)
            .background(isSelected ? color : ModernDesign.Colors.background)
            .cornerRadius(ModernDesign.Radius.medium)
        }
    }
}

struct WorkerSelectionRow: View {
    let worker: User
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ModernDesign.Spacing.md) {
                // Worker Avatar
                ZStack {
                    Circle()
                        .fill(ModernDesign.Colors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(worker.name.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                
                // Worker Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(worker.name)
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    Text(worker.email)
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                // Checkmark
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? ModernDesign.Colors.success : ModernDesign.Colors.textTertiary)
            }
            .padding(ModernDesign.Spacing.md)
            .background(isSelected ? ModernDesign.Colors.success.opacity(0.05) : ModernDesign.Colors.background)
            .cornerRadius(ModernDesign.Radius.medium)
        }
    }
}
