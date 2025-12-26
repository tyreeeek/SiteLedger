import SwiftUI

struct WorkerJobsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = WorkerJobsViewModel()
    @State private var searchText = ""
    
    var filteredJobs: [Job] {
        if searchText.isEmpty {
            return viewModel.jobs
        }
        return viewModel.jobs.filter { job in
            job.jobName.localizedCaseInsensitiveContains(searchText) ||
            job.clientName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                            Text("My Jobs")
                                .font(ModernDesign.Typography.displayMedium)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                            Text("Jobs assigned to you")
                                .font(ModernDesign.Typography.bodySmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ModernDesign.Spacing.lg)
                        
                        VStack(spacing: ModernDesign.Spacing.md) {
                            // Search Bar
                            HStack(spacing: ModernDesign.Spacing.md) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16))
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                                
                                TextField("Search jobs...", text: $searchText)
                                    .font(ModernDesign.Typography.body)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(ModernDesign.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(ModernDesign.Spacing.md)
                            .background(ModernDesign.Colors.cardBackground)
                            .cornerRadius(ModernDesign.Radius.medium)
                            .shadow(
                                color: ModernDesign.Shadow.medium.color,
                                radius: ModernDesign.Shadow.medium.radius,
                                x: ModernDesign.Shadow.medium.x,
                                y: ModernDesign.Shadow.medium.y
                            )
                            
                            // Jobs List
                            if !filteredJobs.isEmpty {
                                VStack(spacing: ModernDesign.Spacing.md) {
                                    ForEach(filteredJobs, id: \.id) { job in
                                        // Use WorkerJobDetailView - no financial data shown
                                        NavigationLink(destination: WorkerJobDetailView(job: job)) {
                                            WorkerJobCardView(job: job)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            } else if viewModel.isLoading {
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                            } else {
                                VStack(spacing: ModernDesign.Spacing.lg) {
                                    Image(systemName: "briefcase.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(ModernDesign.Colors.textTertiary)
                                    
                                    Text("No Jobs Assigned")
                                        .font(ModernDesign.Typography.title3)
                                        .foregroundColor(ModernDesign.Colors.textPrimary)
                                    
                                    Text("Check back soon for job assignments from your manager")
                                        .font(ModernDesign.Typography.body)
                                        .foregroundColor(ModernDesign.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    ModernButton(
                                        title: "Refresh",
                                        icon: "arrow.clockwise",
                                        style: .primary,
                                        size: .medium,
                                        action: { viewModel.loadJobs(forWorkerID: authService.currentUser?.id ?? "") }
                                    )
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
                viewModel.loadJobs(forWorkerID: authService.currentUser?.id ?? "")
            }
        }
    }
}

/// Worker-specific job card - NO financial data shown per Blueprint spec
/// Workers should only see job details, not money information
struct WorkerJobCardView: View {
    let job: Job
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                // Header: Job Name and Status
                HStack(alignment: .top, spacing: ModernDesign.Spacing.sm) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text(job.jobName)
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        
                        if !job.clientName.isEmpty {
                            Text(job.clientName)
                                .font(ModernDesign.Typography.caption)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    ModernBadge(
                        text: job.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        color: statusColor(for: job.status),
                        size: .medium
                    )
                }
                
                // Location
                if !job.address.isEmpty {
                    HStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ModernDesign.Colors.primary)
                        Text(job.address)
                            .font(ModernDesign.Typography.caption)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                            .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                    }
                }
                
                // Date Info (instead of financial data)
                Divider()
                    .padding(.vertical, ModernDesign.Spacing.xs)
                
                HStack(spacing: ModernDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text("Start Date")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textSecondary)
                        Text(job.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    if let endDate = job.endDate {
                        VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                            Text("End Date")
                                .font(ModernDesign.Typography.captionSmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                .font(ModernDesign.Typography.labelLarge)
                                .foregroundColor(ModernDesign.Colors.success)
                        }
                    }
                }
            }
        }
    }
    
    private func statusColor(for status: Job.JobStatus) -> Color {
        switch status {
        case .active: return ModernDesign.Colors.success
        case .completed: return ModernDesign.Colors.primary
        case .onHold: return ModernDesign.Colors.warning
        }
    }
}

#Preview {
    WorkerJobsListView()
        .environmentObject(AuthService())
}
