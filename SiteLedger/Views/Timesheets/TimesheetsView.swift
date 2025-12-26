import SwiftUI

struct TimesheetsView: View {
    let job: Job
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = TimesheetViewModel()
    @State private var showingAddNote = false
    @State private var clockInNote = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                    // Header
                    ScreenHeader(
                        title: "Timesheets",
                        subtitle: job.jobName,
                        action: nil,
                        actionIcon: nil
                    )
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                    
                    VStack(spacing: DesignSystem.Spacing.cardSpacing) {
                        // Active Timesheet Section
                        if let activeTimesheet = viewModel.activeTimesheet {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                HStack(spacing: DesignSystem.Spacing.medium) {
                                    Image(systemName: "clock.fill")
                                        .font(DesignSystem.TextStyle.title3)
                                        .foregroundColor(AppTheme.successColor)
                                    
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                        Text("Currently Clocked In")
                                            .font(DesignSystem.TextStyle.bodyBold)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text((activeTimesheet.clockIn ?? Date()).formatted(date: .abbreviated, time: .shortened))
                                            .font(DesignSystem.TextStyle.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                PrimaryButton(title: "Clock Out", action: { clockOut(timesheet: activeTimesheet) }, isLoading: false)
                            }
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.successColor.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius)
                        } else {
                            VStack(alignment: .center, spacing: DesignSystem.Spacing.medium) {
                                Image(systemName: "clock")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppTheme.primaryColor)
                                
                                VStack(alignment: .center, spacing: DesignSystem.Spacing.tiny) {
                                    Text("Not Clocked In")
                                        .font(DesignSystem.TextStyle.bodyBold)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Text("Start tracking time for this job")
                                        .font(DesignSystem.TextStyle.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                
                                PrimaryButton(title: "Clock In", action: clockIn, isLoading: false)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.cardPadding)
                            .background(AppTheme.backgroundColor)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(AppTheme.borderColor, lineWidth: 1)
                            )
                        }
                        
                        // Total Hours Summary
                        HStack(spacing: DesignSystem.Spacing.medium) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                                Text("Total Hours Logged")
                                    .font(DesignSystem.TextStyle.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text(String(format: "%.2f hrs", viewModel.calculateTotalHours()))
                                    .font(DesignSystem.TextStyle.title2)
                                    .foregroundColor(AppTheme.primaryColor)
                            }
                            Spacer()
                            Image(systemName: "hourglass.tophalf.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.primaryColor.opacity(0.3))
                        }
                        .padding(DesignSystem.Spacing.cardPadding)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
                        
                        // Timesheet History
                        if !viewModel.timesheets.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("History")
                                    .font(DesignSystem.TextStyle.bodyBold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    ForEach(viewModel.timesheets.filter { !$0.isActive }, id: \.id) { timesheet in
                                        TimesheetCardView(timesheet: timesheet)
                                    }
                                }
                            }
                        } else {
                            EmptyStateView(
                                icon: "clock.badge.xmark",
                                title: "No Timesheets",
                                message: "Clock in to create your first timesheet entry",
                                action: clockIn,
                                buttonTitle: "Clock In Now"
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                }
                .padding(.top, DesignSystem.Spacing.cardPadding)
                .padding(.bottom, DesignSystem.Spacing.huge)
            }
        }
        .navigationTitle("Timesheets")
        .onAppear {
            if let jobID = job.id {
                Task {
                    await viewModel.loadTimesheets(for: jobID)
                }
            }
        }
    }
    
    private func clockIn() {
        guard let jobID = job.id else { return }
        
        Task {
            _ = await viewModel.checkIn(jobID: jobID, notes: clockInNote)
            clockInNote = ""
        }
    }
    
    private func clockOut(timesheet: Timesheet) {
        Task {
            guard timesheet.id != nil else { return }
            try? await viewModel.checkOut()
        }
    }
}

struct TimesheetCardView: View {
    let timesheet: Timesheet
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                    Text("Clock In")
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text((timesheet.clockIn ?? Date()).formatted(date: .abbreviated, time: .shortened))
                        .font(DesignSystem.TextStyle.bodySecondary)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                    Text("Clock Out")
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    if let clockOut = timesheet.clockOut {
                        Text(clockOut.formatted(date: .abbreviated, time: .shortened))
                            .font(DesignSystem.TextStyle.bodySecondary)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    } else {
                        Text("—")
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                    Text("Hours")
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(String(format: "%.2f", timesheet.hours ?? 0))
                        .font(DesignSystem.TextStyle.bodySecondary)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            
            if let notes = timesheet.notes, !notes.isEmpty {
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.tiny)
                
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "quote.bubble")
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(notes)
                        .font(DesignSystem.TextStyle.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
    }
}
