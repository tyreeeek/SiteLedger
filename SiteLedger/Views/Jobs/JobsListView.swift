import SwiftUI

struct JobsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    @State private var showingCreateJob = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                        // Modern Header
                        ScreenHeader(
                            title: "Jobs",
                            subtitle: "\(viewModel.jobs.count) total",
                            action: { showingCreateJob = true },
                            actionIcon: "plus.circle.fill"
                        )
                        
                        if viewModel.jobs.isEmpty {
                            EmptyStateView(
                                icon: "briefcase",
                                title: "No Jobs Yet",
                                message: "Create your first job to get started",
                                action: { showingCreateJob = true },
                                buttonTitle: "Create Job"
                            )
                        } else {
                            JobsListContent(viewModel: viewModel)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.cardPadding)
                    .padding(.bottom, DesignSystem.Spacing.huge)
                }
            }
            .navigationBarHidden(true)
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadJobs(userID: userID)
                }
            }
            .refreshable {
                if let userID = authService.currentUser?.id {
                    viewModel.loadJobs(userID: userID)
                }
            }
            .sheet(isPresented: $showingCreateJob) {
                CreateJobView()
            }
        }
    }
}

struct JobsListContent: View {
    @ObservedObject var viewModel: JobsViewModel
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            if #available(iOS 16, *) {
                ForEach(viewModel.jobs, id: \.id) { job in
                    jobCard(job: job)
                }
            } else {
                ForEach(viewModel.jobs, id: \.id) { job in
                    jobCard(job: job)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.cardPadding)
    }
    
    @ViewBuilder
    func jobCard(job: Job) -> some View {
        NavigationLink(destination: JobDetailView(job: job)) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                        Text(job.jobName)
                            .font(DesignSystem.TextStyle.bodyBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text(job.clientName)
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                    StatusBadge(status: job.status)
                }
                
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.tiny)
                
                HStack(spacing: DesignSystem.Spacing.large) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.tiny) {
                        Text("Start Date")
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(job.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(DesignSystem.TextStyle.captionBold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.tiny) {
                        Text("Value")
                            .font(DesignSystem.TextStyle.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("$\(String(format: "%.2f", job.projectValue))")
                            .font(DesignSystem.TextStyle.captionBold)
                            .foregroundColor(AppTheme.profitColor)
                    }
                }
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .shadow(color: AppTheme.shadowColor, radius: AppTheme.shadowRadius, x: AppTheme.shadowOffset.width, y: AppTheme.shadowOffset.height)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

