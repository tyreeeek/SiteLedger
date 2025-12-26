import SwiftUI
import Combine

struct WorkerCheckInView: View {
    @ObservedObject var viewModel: TimesheetViewModel
    @State private var selectedJobID: String?
    @State private var isClockingIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("Time Tracking")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            Text("Clock in or out for your work day")
                                .font(ModernDesign.Typography.bodySmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        Group {
                            if viewModel.isCheckedIn, let timesheet = viewModel.activeTimesheet {
                                // Currently checked in
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    ClockedInCardView(timesheet: timesheet, onCheckOut: {
                                        Task {
                                            HapticsManager.shared.heavy()
                                            await viewModel.checkOut(captureLocation: true, isAutoCheckout: false)
                                            HapticsManager.shared.success()
                                        }
                                    })
                                }
                                .padding(.horizontal, ModernDesign.Spacing.lg)
                            } else {
                                // Not checked in
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    // Job Selection Card
                                    ModernCard(shadow: true) {
                                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                            Label("Select Job to Clock In", systemImage: "briefcase.fill")
                                                .font(ModernDesign.Typography.title3)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                            
                                            if viewModel.availableJobs.isEmpty {
                                                Text("No jobs assigned")
                                                    .font(ModernDesign.Typography.body)
                                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                                    .padding()
                                            } else {
                                                Menu {
                                                    ForEach(viewModel.availableJobs, id: \.id) { job in
                                                        Button(job.jobName) {
                                                            print("🟢 Job selected: \(job.jobName) with ID: \(job.id ?? "nil")")
                                                            selectedJobID = job.id
                                                            print("🟢 selectedJobID is now: \(selectedJobID ?? "nil")")
                                                        }
                                                    }
                                                } label: {
                                                    HStack {
                                                        if let jobID = selectedJobID,
                                                           let job = viewModel.availableJobs.first(where: { $0.id == jobID }) {
                                                            Text(job.jobName)
                                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                                        } else {
                                                            Text("Select a job")
                                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                                        }
                                                        Spacer()
                                                        Image(systemName: "chevron.down")
                                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                                    }
                                                    .padding()
                                                    .background(ModernDesign.Colors.background)
                                                    .cornerRadius(ModernDesign.Radius.medium)
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Clock In Button
                                    Button {
                                        guard let jobID = selectedJobID, !isClockingIn else { return }
                                        
                                        Task { @MainActor in
                                            isClockingIn = true
                                            HapticsManager.shared.heavy()
                                            _ = await viewModel.checkIn(jobID: jobID, notes: nil)
                                            isClockingIn = false
                                            HapticsManager.shared.success()
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 20))
                                            Text(isClockingIn ? "Clocking In..." : "Clock In")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .foregroundColor(.white)
                                        .background(selectedJobID == nil || isClockingIn ? Color.gray : Color.blue)
                                        .cornerRadius(12)
                                        .opacity(isClockingIn ? 0.6 : 1.0)
                                        .overlay {
                                            if isClockingIn {
                                                ProgressView()
                                                    .tint(.white)
                                            }
                                        }
                                    }
                                    .disabled(isClockingIn || selectedJobID == nil)
                                }
                            }
                        }
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                    }
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func jobName(for jobID: String) -> String {
        viewModel.availableJobs.first { $0.id == jobID }?.jobName ?? "Unknown Job"
    }
}

struct ClockedInCardView: View {
    let timesheet: Timesheet
    let onCheckOut: () -> Void
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.lg) {
                // Status Header
                HStack(spacing: ModernDesign.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ModernDesign.Colors.success)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Currently Clocked In")
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Text("Your timer is running")
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                    
                    Spacer()
                }
                .padding(ModernDesign.Spacing.md)
                .background(ModernDesign.Colors.success.opacity(0.1))
                .cornerRadius(ModernDesign.Radius.medium)
                
                // Timer Display
                VStack(spacing: ModernDesign.Spacing.sm) {
                    Text("Elapsed Time")
                        .font(ModernDesign.Typography.label)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    
                    TimerView(startTime: timesheet.clockIn ?? Date())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(ModernDesign.Spacing.lg)
                .background(ModernDesign.Colors.background)
                .cornerRadius(ModernDesign.Radius.medium)
                
                // Clocked In Time Display
                HStack(spacing: ModernDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clocked In")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Text((timesheet.clockIn ?? Date()).formatted(date: .omitted, time: .shortened))
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                .padding(ModernDesign.Spacing.md)
                .background(ModernDesign.Colors.background)
                .cornerRadius(ModernDesign.Radius.medium)
                
                // Clock Out Button
                ModernButton(
                    title: "Clock Out",
                    icon: "stop.circle.fill",
                    style: .danger,
                    size: .large,
                    action: onCheckOut
                )
            }
        }
    }
}

struct TimerView: View {
    let startTime: Date
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(formatTime(currentTime.timeIntervalSince(startTime)))
            .onReceive(timer) { time in
                currentTime = time
            }
            .onAppear {
                // Ensure we start with current time
                currentTime = Date()
            }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) % 3600 / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct CheckInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(ModernDesign.Colors.success)
            .cornerRadius(ModernDesign.Radius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CheckOutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(ModernDesign.Colors.error)
            .cornerRadius(ModernDesign.Radius.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}