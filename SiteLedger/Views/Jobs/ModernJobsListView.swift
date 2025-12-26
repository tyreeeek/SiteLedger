import SwiftUI

struct ModernJobsListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = JobsViewModel()
    @State private var showingCreateJob = false
    @State private var searchText = ""
    @State private var selectedFilter: JobFilterType = .all
    
    enum JobFilterType: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case onHold = "On Hold"
    }
    
    var filteredJobs: [Job] {
        var jobs = viewModel.jobs
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            jobs = jobs.filter { $0.status == .active }
        case .completed:
            jobs = jobs.filter { $0.status == .completed }
        case .onHold:
            jobs = jobs.filter { $0.status == .onHold }
        }
        // Apply search filter
        if !searchText.isEmpty {
            jobs = jobs.filter { job in
                job.jobName.localizedCaseInsensitiveContains(searchText) ||
                job.clientName.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Filter out jobs with nil id
        return jobs.filter { $0.id != nil }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ModernDesign.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: ModernDesign.Spacing.lg) {
                        HStack {
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                                Text("Jobs")
                                    .font(ModernDesign.Typography.displayMedium)
                                    .foregroundColor(ModernDesign.Colors.textPrimary)
                                
                                Text("\(filteredJobs.count) total")
                                    .font(ModernDesign.Typography.bodySmall)
                                    .foregroundColor(ModernDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.shared.light()
                                showingCreateJob = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ModernDesign.Colors.primary)
                            }
                        }
                        
                        // Search Bar
                        HStack(spacing: ModernDesign.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            
                            TextField("Search jobs...", text: $searchText)
                                .font(ModernDesign.Typography.body)
                        }
                        .padding(ModernDesign.Spacing.md)
                        .background(ModernDesign.Colors.cardBackground)
                        .cornerRadius(ModernDesign.Radius.medium)
                        .shadow(color: ModernDesign.Shadow.small.color,
                               radius: ModernDesign.Shadow.small.radius,
                               x: ModernDesign.Shadow.small.x,
                               y: ModernDesign.Shadow.small.y)
                        
                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: ModernDesign.Spacing.sm) {
                                ForEach(JobFilterType.allCases, id: \.self) { filter in
                                    JobsFilterChip(
                                        title: filter.rawValue,
                                        isSelected: selectedFilter == filter,
                                        action: {
                                            HapticsManager.shared.selection()
                                            selectedFilter = filter
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ModernDesign.Spacing.lg)
                    .padding(.top, ModernDesign.Spacing.lg)
                    .padding(.bottom, ModernDesign.Spacing.md)
                    
                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredJobs.isEmpty {
                        Spacer()
                        EmptyJobsState(
                            hasJobs: !viewModel.jobs.isEmpty,
                            searchText: searchText,
                            action: { showingCreateJob = true }
                        )
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: ModernDesign.Spacing.md) {
                                ForEach(filteredJobs, id: \.id) { job in
                                    NavigationLink(destination: ModernJobDetailView(job: job)) {
                                        ModernJobCardItem(job: job, viewModel: viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .id(job.id ?? UUID().uuidString)
                                }
                            }
                            .padding(.horizontal, ModernDesign.Spacing.lg)
                            .padding(.top, ModernDesign.Spacing.sm)
                            .padding(.bottom, ModernDesign.Spacing.xxxl)
                        }
                        .refreshable {
                            if let userID = authService.currentUser?.id {
                                viewModel.loadJobs(userID: userID)
                                viewModel.loadAllReceipts()
                                viewModel.loadTimesheets(userID: userID)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if let userID = authService.currentUser?.id {
                    viewModel.loadJobs(userID: userID)
                    viewModel.loadAllReceipts()
                    viewModel.loadTimesheets(userID: userID)
                }
            }
            .task {
                if let userID = authService.currentUser?.id {
                    viewModel.loadJobs(userID: userID)
                    viewModel.loadAllReceipts()
                    viewModel.loadTimesheets(userID: userID)
                }
            }
            .sheet(isPresented: $showingCreateJob, onDismiss: {
                // Reload data when job creation sheet is dismissed
                if let userID = authService.currentUser?.id {
                    viewModel.loadJobs(userID: userID)
                    viewModel.loadAllReceipts()
                    viewModel.loadTimesheets(userID: userID)
                }
            }) {
                ModernCreateJobView()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct ModernJobCardItem: View {
    let job: Job
    @ObservedObject var viewModel: JobsViewModel
    
    var profit: Double {
        // Use ViewModel's calculated profit
        // Formula: profit = projectValue - laborCost - receiptExpenses
        return viewModel.getJobProfit(job: job)
    }
    
    var remainingValue: Double {
        // Remaining Job Value = Original Job Value - Total Receipts
        return viewModel.getRemainingJobValue(job: job)
    }
    
    var receiptExpenses: Double {
        guard let jobID = job.id else { return 0 }
        return viewModel.getJobReceiptExpenses(jobID: jobID)
    }
    
    var profitColor: Color {
        profit >= 0 ? ModernDesign.Colors.success : ModernDesign.Colors.error
    }
    
    var statusColor: Color {
        switch job.status {
        case .active:
            return ModernDesign.Colors.info
        case .completed:
            return ModernDesign.Colors.success
        case .onHold:
            return ModernDesign.Colors.warning
        }
    }
    
    var progressPercentage: Double {
        guard job.projectValue > 0 else { return 0 }
        return min(job.amountPaid / job.projectValue, 1.0)
    }
    
    var body: some View {
        ModernCard(shadow: true) {
            VStack(spacing: ModernDesign.Spacing.md) {
                // Header Row
                HStack {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        Text(job.jobName)
                            .font(ModernDesign.Typography.title3)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                            .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        
                        HStack(spacing: ModernDesign.Spacing.xs) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundColor(ModernDesign.Colors.textTertiary)
                            Text(job.clientName)
                                .font(ModernDesign.Typography.bodySmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                                .adaptiveText(allowsMultipleLines: true, minimumScaleFactor: 0.85)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: ModernDesign.Spacing.xs) {
                        ModernBadge(text: job.status.rawValue.capitalized, color: statusColor, size: .small)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                }
                
                // Divider
                Rectangle()
                    .fill(ModernDesign.Colors.border)
                    .frame(height: 1)
                
                // Stats Row
                HStack(spacing: ModernDesign.Spacing.lg) {
                    VStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ModernDesign.Colors.primary)
                        Text("$\(String(format: "%.2f", job.projectValue))")
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Text("Value")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(profitColor)
                        Text("$\(String(format: "%.2f", profit))")
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Text("Profit")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: ModernDesign.Spacing.xs) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ModernDesign.Colors.accent)
                        Text(job.startDate.formatted(.dateTime.month(.abbreviated).day()))
                            .font(ModernDesign.Typography.labelLarge)
                            .foregroundColor(ModernDesign.Colors.textPrimary)
                        Text("Start")
                            .font(ModernDesign.Typography.captionSmall)
                            .foregroundColor(ModernDesign.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Progress if active
                if job.status == .active {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                        HStack {
                            Text("Progress")
                                .font(ModernDesign.Typography.labelSmall)
                                .foregroundColor(ModernDesign.Colors.textSecondary)
                            Spacer()
                            Text("\(Int(progressPercentage * 100))%")
                                .font(ModernDesign.Typography.labelSmall)
                                .foregroundColor(ModernDesign.Colors.textPrimary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(ModernDesign.Colors.border)
                                    .frame(height: 6)
                                
                                Rectangle()
                                    .fill(ModernDesign.Colors.primary)
                                    .frame(width: geometry.size.width * progressPercentage, height: 6)
                            }
                            .cornerRadius(ModernDesign.Radius.round)
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
    }
}

struct JobsFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ModernDesign.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : ModernDesign.Colors.textSecondary)
                .padding(.horizontal, ModernDesign.Spacing.md)
                .padding(.vertical, ModernDesign.Spacing.sm)
                .background(isSelected ? ModernDesign.Colors.primary : ModernDesign.Colors.cardBackground)
                .cornerRadius(ModernDesign.Radius.round)
                .shadow(color: isSelected ? ModernDesign.Shadow.small.color : .clear,
                       radius: ModernDesign.Shadow.small.radius,
                       x: ModernDesign.Shadow.small.x,
                       y: ModernDesign.Shadow.small.y)
        }
    }
}

struct EmptyJobsState: View {
    let hasJobs: Bool
    let searchText: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.lg) {
            Image(systemName: hasJobs ? "magnifyingglass" : "briefcase")
                .font(.system(size: 64))
                .foregroundColor(ModernDesign.Colors.textTertiary)
            
            VStack(spacing: ModernDesign.Spacing.sm) {
                Text(hasJobs ? "No Results" : "No Jobs Yet")
                    .font(ModernDesign.Typography.title2)
                    .foregroundColor(ModernDesign.Colors.textPrimary)
                
                Text(hasJobs ? "Try adjusting your search or filters" : "Create your first job to get started")
                    .font(ModernDesign.Typography.body)
                    .foregroundColor(ModernDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasJobs {
                ModernButton(
                    title: "Create Job",
                    icon: "plus.circle.fill",
                    style: .primary,
                    size: .large,
                    action: {
                        HapticsManager.shared.light()
                        action()
                    }
                )
            }
        }
        .padding(ModernDesign.Spacing.xl)
    }
}
