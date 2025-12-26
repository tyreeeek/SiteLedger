import SwiftUI
import CoreLocation
import Combine

struct CheckInOutView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TimesheetViewModel()
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var selectedJob: Job?
    @State private var notes = ""
    @State private var showJobPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    // Header
                    ScreenHeader(
                        title: viewModel.isCheckedIn ? "Checked In" : "Check In",
                        subtitle: viewModel.isCheckedIn ? "Track your work hours" : "Start your shift",
                        action: nil,
                        actionIcon: nil
                    )
                    
                    if viewModel.isCheckedIn {
                        // CHECKED IN STATE
                        checkedInView
                    } else {
                        // NOT CHECKED IN STATE
                        notCheckedInView
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
            }
        }
        .navigationTitle("Time Tracking")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showJobPicker) {
            jobPickerSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            // Load data filtered for current worker
            if let workerID = authService.currentUser?.id {
                await viewModel.loadData(workerID: workerID)
                print("🔍 [CheckInOutView] Loaded \(viewModel.availableJobs.count) jobs for worker")
                print("🔍 [CheckInOutView] Active timesheet: \(viewModel.activeTimesheet?.id ?? "none")")
                print("🔍 [CheckInOutView] Is checked in: \(viewModel.isCheckedIn)")
            }
            locationManager.requestPermission()
        }
        .onAppear {
            currentTime = Date()
            viewModel.updateShiftDuration()
        }
        .onReceive(timer) { time in
            currentTime = time
            // Update timer display every second if checked in
            if viewModel.isCheckedIn {
                viewModel.updateShiftDuration()
            }
        }
    }
    
    // MARK: - Checked In View
    
    private var checkedInView: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            // Active Shift Card
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Job Name
                if let job = viewModel.availableJobs.first(where: { $0.id == viewModel.activeTimesheet?.jobID }) {
                    Text(job.jobName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                // Timer Display (updates every second via published property)
                Text(viewModel.currentShiftDuration)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(AppTheme.accentColor)
                    .monospacedDigit()
                
                Text("Hours Worked")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                
                // Clock In Time
                if let clockIn = viewModel.activeTimesheet?.clockIn {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                        Text("Started at \(formatTime(clockIn))")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
                }
                
                // Location
                if let location = viewModel.activeTimesheet?.clockInLocation {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(location)
                            .font(.system(size: 13, weight: .regular))
                            .lineLimit(2)
                    }
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 4)
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            
            // Check Out Button
            Button(action: {
                guard !viewModel.isCheckingOut else { return } // Prevent double-tap
                
                Task {
                    await viewModel.checkOut(captureLocation: true, isAutoCheckout: false)
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isCheckingOut {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.system(size: 18))
                        Text("Check Out")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.errorColor)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.cornerRadius)
            }
            .disabled(viewModel.isCheckingOut)
            
            // Notes (if any)
            if let notes = viewModel.activeTimesheet?.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(notes)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.Spacing.cardPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
    }
    
    // MARK: - Not Checked In View
    
    private var notCheckedInView: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            // Info Card
            VStack(spacing: 16) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.accentColor.opacity(0.3))
                
                Text("Ready to start your shift?")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Check in to track your hours and location for this job")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            
            // Job Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Job")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                
                Button(action: { showJobPicker = true }) {
                    HStack {
                        if let job = selectedJob {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.jobName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(job.clientName)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        } else {
                            Text("Choose a job...")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.cardPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                }
            }
            
            // Notes Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Add shift notes...", text: $notes, axis: .vertical)
                    .font(.system(size: 15))
                    .padding(DesignSystem.Spacing.cardPadding)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    .lineLimit(3...6)
            }
            
            // Location Status
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.profitColor)
                    Text("Location tracking enabled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.warningColor)
                    Text("Location tracking disabled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Check In Button
            Button(action: {
                guard !viewModel.isCheckingIn else { 
                    print("⚠️ Clock-in already in progress, ignoring tap")
                    return 
                }
                
                guard let job = selectedJob else {
                    errorMessage = "Please select a job"
                    showError = true
                    return
                }
                
                guard let jobID = job.id else {
                    errorMessage = "Invalid job selected"
                    showError = true
                    return
                }
                
                Task { @MainActor in
                    let result = await viewModel.checkIn(jobID: jobID, notes: notes, captureLocation: true)
                    if result != nil {
                        notes = ""
                        selectedJob = nil
                    } else if let error = viewModel.errorMessage {
                        errorMessage = error
                        showError = true
                    }
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isCheckingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                        Text("Check In")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedJob != nil ? AppTheme.profitColor : AppTheme.textSecondary.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(AppTheme.cornerRadius)
            }
            .disabled(selectedJob == nil || viewModel.isCheckingIn)
        }
    }
    
    // MARK: - Job Picker Sheet
    
    private var jobPickerSheet: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    showJobPicker = false
                }
                Spacer()
                Text("Select Job")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Cancel") {
                    showJobPicker = false
                }
                .opacity(0)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // Content
            if viewModel.availableJobs.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "briefcase.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Jobs Assigned")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Contact your manager to get assigned to a job")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Refresh") {
                        Task {
                            if let workerID = authService.currentUser?.id {
                                await viewModel.loadData(workerID: workerID)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Spacer()
                }
            } else {
                List(viewModel.availableJobs) { job in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(job.jobName)
                                .font(.system(size: 17, weight: .medium))
                            Text(job.clientName)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedJob?.id == job.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(Color(UIColor.systemBackground))
                    .onTapGesture {
                        print("🎯 Job tapped: \(job.jobName)")
                        selectedJob = job
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showJobPicker = false
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        CheckInOutView()
            .environmentObject(AuthService())
    }
}
