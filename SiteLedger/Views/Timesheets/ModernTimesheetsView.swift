import SwiftUI
import Combine

struct ModernTimesheetsView: View {
    let job: Job
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TimesheetViewModel()
    @State private var clockInNote = ""
    @State private var showingNoteInput = false
    @Environment(\.scenePhase) private var scenePhase
    
    private var isOwner: Bool {
        authService.currentUser?.role == .owner
    }
    
    var body: some View {
        ZStack {
            ModernDesign.Colors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ModernDesign.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text("Timesheets")
                            .font(ModernDesign.Typography.displayMedium)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        
                        Text(job.jobName)
                            .font(ModernDesign.Typography.body)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Clock In/Out Card - ONLY FOR WORKERS
                    if !isOwner {
                        if let activeTimesheet = viewModel.activeTimesheet {
                            ActiveTimesheetCard(
                                timesheet: activeTimesheet,
                                onClockOut: { clockOut(timesheet: activeTimesheet) }
                            )
                        } else {
                            ClockInCard(
                                note: $clockInNote,
                                showingNoteInput: $showingNoteInput,
                                onClockIn: clockIn
                            )
                        }
                    }
                    
                    // Stats Summary
                    TimesheetStatsCard(
                        totalHours: viewModel.calculateTotalHours(),
                        entryCount: viewModel.timesheets.count
                    )
                    
                    // History Section
                    if !viewModel.timesheets.filter({ !$0.isActive }).isEmpty {
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                            ModernSectionHeader(title: "History")
                            
                            LazyVStack(spacing: ModernDesign.Spacing.md) {
                                ForEach(viewModel.timesheets.filter { !$0.isActive }, id: \.id) { timesheet in
                                    ModernTimesheetCard(timesheet: timesheet)
                                        .id(timesheet.id ?? UUID().uuidString)
                                }
                            }
                        }
                    } else if !isOwner {
                        // Only show empty state with clock-in for workers
                        EmptyTimesheetsState(onClockIn: clockIn)
                    } else {
                        // Owner sees different empty state
                        VStack(spacing: ModernDesign.Spacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(ModernDesign.Colors.info.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(ModernDesign.Colors.info)
                            }
                            
                            VStack(spacing: ModernDesign.Spacing.sm) {
                                Text("No Timesheets Yet")
                                    .font(ModernDesign.Typography.title2)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Text("Workers will clock in and out from this screen")
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(ModernDesign.Spacing.xl)
                    }
                }
                .padding(ModernDesign.Spacing.lg)
                .padding(.bottom, ModernDesign.Spacing.xxxl)
            }
            .refreshable {
                if let jobID = job.id {
                    Task {
                        await viewModel.loadTimesheets(for: jobID)
                    }
                }
            }
        }
        .navigationTitle("Timesheets")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let jobID = job.id {
                Task {
                    await viewModel.loadTimesheets(for: jobID)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // When app comes back to foreground, reload timesheets to restore timer
            if newPhase == .active, let jobID = job.id {
                Task {
                    await viewModel.loadTimesheets(for: jobID)
                }
            }
        }
    }
    
    private func clockIn() {
        guard let jobID = job.id else { return }
        HapticsManager.shared.medium()
        
        Task {
            _ = await viewModel.checkIn(jobID: jobID, notes: clockInNote)
            await MainActor.run {
                clockInNote = ""
                showingNoteInput = false
                HapticsManager.shared.success()
            }
        }
    }
    
    private func clockOut(timesheet: Timesheet) {
        HapticsManager.shared.medium()
        
        Task {
            guard timesheet.id != nil else { return }
            await viewModel.checkOut(captureLocation: true, isAutoCheckout: false)
            await MainActor.run {
                HapticsManager.shared.success()
            }
        }
    }
}

struct ActiveTimesheetCard: View {
    let timesheet: Timesheet
    let onClockOut: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.lg) {
                // Status Badge
                HStack {
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Circle()
                            .fill(ModernDesign.Colors.success)
                            .frame(width: 8, height: 8)
                        
                        Text("CLOCKED IN")
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(ModernDesign.Colors.success)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.md)
                    .padding(.vertical, ModernDesign.Spacing.xs)
                    .background(ModernDesign.Colors.success.opacity(0.1))
                    .cornerRadius(ModernDesign.Radius.round)
                    
                    Spacer()
                }
                
                // Timer Display
                VStack(spacing: ModernDesign.Spacing.xs) {
                    Text(formatElapsedTime(elapsedTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                        .monospacedDigit()
                    
                    Text("Started \((timesheet.clockIn ?? Date()).formatted(date: .omitted, time: .shortened))")
                        .font(ModernDesign.Typography.bodySmall)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                // Clock Out Button
                ModernButton(
                    title: "Clock Out",
                    icon: "stop.circle.fill",
                    style: .danger,
                    size: .large,
                    action: onClockOut
                )
            }
        }
        .onReceive(timer) { _ in
            elapsedTime = Date().timeIntervalSince(timesheet.clockIn ?? Date())
        }
        .onAppear {
            elapsedTime = Date().timeIntervalSince(timesheet.clockIn ?? Date())
        }
    }
    
    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct ClockInCard: View {
    @Binding var note: String
    @Binding var showingNoteInput: Bool
    let onClockIn: () -> Void
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(ModernDesign.Colors.primary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "clock")
                        .font(.system(size: 36))
                        .foregroundColor(ModernDesign.Colors.primary)
                }
                
                // Text
                VStack(spacing: ModernDesign.Spacing.xs) {
                    Text("Ready to Work?")
                        .font(ModernDesign.Typography.title2)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    Text("Clock in to start tracking time")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                // Optional Note
                if showingNoteInput {
                    TextField("Add a note (optional)", text: $note)
                        .font(ModernDesign.Typography.body)
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.background)
                        .cornerRadius(ModernDesign.Radius.medium)
                } else {
                    Button(action: {
                        HapticsManager.shared.light()
                        showingNoteInput = true
                    }) {
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: "note.text.badge.plus")
                            Text("Add Note")
                        }
                        .font(ModernDesign.Typography.labelSmall)
                        .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
                
                // Clock In Button
                ModernButton(
                    title: "Clock In",
                    icon: "play.circle.fill",
                    style: .primary,
                    size: .large,
                    action: onClockIn
                )
            }
        }
    }
}

struct TimesheetStatsCard: View {
    let totalHours: Double
    let entryCount: Int
    
    var body: some View {
        ModernCard(shadow: true) {
            HStack(spacing: ModernDesign.Spacing.lg) {
                // Total Hours
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 14))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        Text("Total Hours")
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    
                    Text(String(format: "%.2f", totalHours))
                        .font(ModernDesign.Typography.displayMedium)
                        .foregroundColor(ModernDesign.Colors.primary)
                    + Text(" hrs")
                        .font(ModernDesign.Typography.body)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                // Entries
                VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Text("Entries")
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                    
                    Text("\(entryCount)")
                        .font(ModernDesign.Typography.displayMedium)
                        .foregroundColor(ModernDesign.Colors.accent)
                }
            }
        }
    }
}

struct ModernTimesheetCard: View {
    let timesheet: Timesheet
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.md) {
                // Time Row
                HStack {
                    // Clock In
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ModernDesign.Colors.success)
                            Text("In")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                        
                        Text((timesheet.clockIn ?? Date()).formatted(date: .omitted, time: .shortened))
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Date
                    VStack(spacing: ModernDesign.Spacing.xs) {
                        Text((timesheet.clockIn ?? Date()).formatted(.dateTime.weekday(.abbreviated)))
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                        
                        Text((timesheet.clockIn ?? Date()).formatted(.dateTime.month(.abbreviated).day()))
                            .font(ModernDesign.Typography.label)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.md)
                    .padding(.vertical, ModernDesign.Spacing.sm)
                    .background(ModernDesign.Colors.background)
                    .cornerRadius(ModernDesign.Radius.small)
                    
                    Spacer()
                    
                    // Clock Out
                    VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Text("Out")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(ModernDesign.Colors.error)
                        }
                        
                        if let clockOut = timesheet.clockOut {
                            Text(clockOut.formatted(date: .omitted, time: .shortened))
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                        } else {
                            Text("—")
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                        }
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(ModernDesign.Colors.border)
                    .frame(height: 1)
                
                // Hours and Notes Row
                HStack {
                    // Hours Badge
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ModernDesign.Colors.accent)
                        
                        Text(String(format: "%.2f hrs", timesheet.hours ?? 0))
                            .font(ModernDesign.Typography.labelSmall)
                            .foregroundColor(ModernDesign.Colors.accent)
                    }
                    .padding(.horizontal, ModernDesign.Spacing.sm)
                    .padding(.vertical, ModernDesign.Spacing.xs)
                    .background(ModernDesign.Colors.accent.opacity(0.1))
                    .cornerRadius(ModernDesign.Radius.small)
                    
                    Spacer()
                    
                    // Notes
                    if !(timesheet.notes ?? "").isEmpty {
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: "note.text")
                                .font(.system(size: 12))
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            
                            Text(timesheet.notes ?? "")
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        }
                    }
                }
            }
        }
    }
}

struct EmptyTimesheetsState: View {
    let onClockIn: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(ModernDesign.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock.badge.xmark")
                    .font(.system(size: 40))
                    .foregroundColor(ModernDesign.Colors.primary)
            }
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text("No Timesheets Yet")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text("Clock in to start tracking your time")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            ModernButton(
                title: "Clock In Now",
                icon: "play.circle.fill",
                style: .primary,
                size: .large,
                action: onClockIn
            )
        }
        .padding(ModernDesign.Spacing.xl)
    }
}
