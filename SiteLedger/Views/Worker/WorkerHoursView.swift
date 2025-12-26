import SwiftUI

struct WorkerHoursView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = WorkerHoursViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("My Hours")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            Text("Track all your work hours")
                                .font(ModernDesign.Typography.bodySmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        VStack(spacing: ModernDesign.Spacing.lg) {
                            // Weekly Summary Card
                            ModernCard(shadow: true) {
                                VStack(spacing: ModernDesign.Spacing.sm) {
                                    HStack {
                                        HStack(spacing: ModernDesign.Spacing.sm) {
                                            Image(systemName: "calendar.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                            Text("This Week")
                                                .font(ModernDesign.Typography.title3)
                                                .foregroundColor(ModernDesign.Colors.textPrimary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(String(format: "%.2f", viewModel.weeklyHours))")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(ModernDesign.Colors.primary)
                                            Text("hours")
                                                .font(ModernDesign.Typography.captionSmall)
                                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                        }
                                    }
                                    
                                    // Progress bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(ModernDesign.Colors.border)
                                            
                                            let progress = min(viewModel.weeklyHours / 40, 1.0)
                                            RoundedRectangle(cornerRadius: ModernDesign.Radius.small)
                                                .fill(ModernDesign.Colors.primary)
                                                .frame(width: geometry.size.width * CGFloat(progress))
                                        }
                                    }
                                    .frame(height: 8)
                                    
                                    HStack(spacing: 4) {
                                        Text(String(format: "%.0f%%", min((viewModel.weeklyHours / 40) * 100, 100)))
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        Text("of 40-hour week")
                                            .font(ModernDesign.Typography.caption)
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                        Spacer()
                                    }
                                }
                            }
                            
                            // Time Entries Section
                            if !viewModel.timeEntries.isEmpty {
                                ModernCard(shadow: true) {
                                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                        // Header with filter
                                        HStack {
                                            HStack(spacing: ModernDesign.Spacing.sm) {
                                                Image(systemName: "list.bullet.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(ModernDesign.Colors.primary)
                                                Text("Time Entries")
                                                    .font(ModernDesign.Typography.title3)
                                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                            }
                                            
                                            Spacer()
                                            
                                            Menu {
                                                Button(action: { viewModel.filterDays = 7 }) {
                                                    Label("Last 7 Days", systemImage: "calendar")
                                                }
                                                Button(action: { viewModel.filterDays = 30 }) {
                                                    Label("Last 30 Days", systemImage: "calendar")
                                                }
                                                Button(action: { viewModel.filterDays = 365 }) {
                                                    Label("All Time", systemImage: "calendar")
                                                }
                                            } label: {
                                                Image(systemName: "ellipsis.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(ModernDesign.Colors.primary)
                                            }
                                        }
                                        
                                        // Entries List
                                        VStack(spacing: ModernDesign.Spacing.sm) {
                                            ForEach(viewModel.timeEntries, id: \.id) { entry in
                                                TimeEntryRowView(entry: entry)
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    Image(systemName: "hourglass.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                    
                                    Text("No Time Entries Yet")
                                        .font(ModernDesign.Typography.title3)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    
                                    Text("Start tracking your hours by clocking in on a job")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(ModernDesign.Spacing.xxl)
                            }
                        }
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                    }
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.xxxl)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadTimeEntries(forUserId: authService.currentUser?.id ?? "")
            }
        }
    }
}

struct TimeEntryRowView: View {
    let entry: Timesheet
    
    var durationText: String {
        guard entry.clockOut != nil else { return "In progress" }
        let hours = entry.hours ?? 0
        return String(format: "%.2f hrs", hours)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
            // Main Row
            HStack(alignment: .top, spacing: ModernDesign.Spacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.jobName ?? "No Job")
                        .font(ModernDesign.Typography.labelLarge)
                        .foregroundColor(ModernDesign.Colors.textPrimary)
                    
                    if let clockIn = entry.clockIn {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(clockIn.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(durationText)
                        .font(ModernDesign.Typography.labelLarge)
                        .foregroundColor(ModernDesign.Colors.primary)
                    
                    if entry.clockOut != nil {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.success)
                    }
                }
            }
            
            // Clock Out Time (if available)
            if let clockOut = entry.clockOut {
                Divider()
                    .padding(.vertical, 4)
                
                HStack(spacing: ModernDesign.Spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    
                    Text("Checked out: \(clockOut.formatted(date: .omitted, time: .shortened))")
                        .font(ModernDesign.Typography.caption)
                        .foregroundColor(ModernDesign.Colors.textSecondary)
                    
                    Spacer()
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


