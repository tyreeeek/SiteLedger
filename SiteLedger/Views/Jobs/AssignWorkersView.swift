import SwiftUI

struct AssignWorkersView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var workersViewModel = WorkersViewModel()
    @EnvironmentObject private var jobsViewModel: JobsViewModel
    
    @State private var job: Job  // Changed from let to @State so we can update it
    
    @State private var assignedWorkerIDs: Set<String> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(job: Job) {
        _job = State(initialValue: job)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(workersViewModel.workers.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primaryColor)
                            Text("Total Workers")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(assignedWorkerIDs.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Assigned")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding()
                    
                    if workersViewModel.workers.isEmpty {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: "person.2.slash",
                                title: "No Workers Yet",
                                message: "Add workers to your team before assigning them to jobs.",
                                action: nil,
                                buttonTitle: nil
                            )
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(workersViewModel.workers) { worker in
                                    WorkerAssignmentRow(
                                        worker: worker,
                                        isAssigned: assignedWorkerIDs.contains(worker.id ?? ""),
                                        onToggle: { isNowAssigned in
                                            toggleWorkerAssignment(worker: worker, assign: isNowAssigned)
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(AppTheme.errorColor)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Assign Workers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        isLoading = true
        
        Task {
            await workersViewModel.loadWorkers()
            
            // ALWAYS fetch fresh job data from backend to get current assignments
            if let jobID = job.id {
                do {
                    print("[AssignWorkers] Loading fresh job data on appear...")
                    let apiJob = try await APIService.shared.getJob(id: jobID)
                    await MainActor.run {
                        if let workerIDs = apiJob.assignedWorkers {
                            print("[AssignWorkers] Fresh data shows \(workerIDs.count) assigned workers: \(workerIDs)")
                            assignedWorkerIDs = Set(workerIDs)
                        } else {
                            print("[AssignWorkers] Fresh data shows no assigned workers")
                            assignedWorkerIDs = []
                        }
                        isLoading = false
                    }
                } catch {
                    print("[AssignWorkers] Failed to load fresh job data: \(error)")
                    await MainActor.run {
                        // Fallback to job binding if API fails
                        if let workerIDs = job.assignedWorkers {
                            assignedWorkerIDs = Set(workerIDs)
                        }
                        isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func toggleWorkerAssignment(worker: User, assign: Bool) {
        guard let workerID = worker.id,
              let jobID = job.id else { 
            print("[AssignWorkers] ERROR: Missing workerID or jobID")
            return 
        }
        
        print("[AssignWorkers] Toggle: worker=\(workerID), job=\(jobID), assign=\(assign)")
        isLoading = true
        showError = false
        
        Task {
            do {
                print("[AssignWorkers] Making API call...")
                if assign {
                    try await workersViewModel.assignWorkerToJob(workerID: workerID, jobID: jobID)
                    print("[AssignWorkers] Assign API call succeeded")
                } else {
                    try await workersViewModel.unassignWorkerFromJob(workerID: workerID, jobID: jobID)
                    print("[AssignWorkers] Unassign API call succeeded")
                }
                
                // Reload job data from backend to ensure UI is in sync
                print("[AssignWorkers] Reloading job data...")
                await jobsViewModel.reloadJob(jobID: jobID)
                print("[AssignWorkers] Job reloaded")
                
                // Update assignedWorkerIDs from the reloaded job in viewModel
                await MainActor.run {
                    print("[AssignWorkers] Updating UI on MainActor")
                    // ALWAYS get the fresh job from viewModel after reload
                    if let reloadedJob = jobsViewModel.jobs.first(where: { $0.id == jobID }) {
                        print("[AssignWorkers] ✅ Found reloaded job: \(reloadedJob.jobName)")
                        // Update both the local job state AND the assignedWorkerIDs
                        self.job = reloadedJob
                        if let workerIDs = reloadedJob.assignedWorkers {
                            print("[AssignWorkers] Assigned workers: \(workerIDs)")
                            assignedWorkerIDs = Set(workerIDs)
                        } else {
                            print("[AssignWorkers] No assigned workers on job")
                            assignedWorkerIDs = []
                        }
                    } else {
                        // Job not in list yet - fetch it directly from API
                        print("[AssignWorkers] Job not in viewModel list, fetching directly...")
                        Task {
                            do {
                                let apiJob = try await APIService.shared.getJob(id: jobID)
                                await MainActor.run {
                                    if let workerIDs = apiJob.assignedWorkers {
                                        print("[AssignWorkers] Direct fetch - Assigned workers: \(workerIDs)")
                                        assignedWorkerIDs = Set(workerIDs)
                                    } else {
                                        print("[AssignWorkers] Direct fetch - No assigned workers")
                                        assignedWorkerIDs = []
                                    }
                                }
                            } catch {
                                print("[AssignWorkers] Failed to fetch job directly: \(error)")
                            }
                        }
                    }
                    isLoading = false
                }
            } catch {
                print("[AssignWorkers] ERROR: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to update assignment: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

struct WorkerAssignmentRow: View {
    let worker: User
    let isAssigned: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(AppTheme.primaryColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(worker.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(worker.email)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button {
                print("[AssignWorkers] Button tapped! isAssigned=\(isAssigned), calling onToggle with: \(!isAssigned)")
                onToggle(!isAssigned)
            } label: {
                Image(systemName: isAssigned ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundColor(isAssigned ? .green : AppTheme.textSecondary.opacity(0.5))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    AssignWorkersView(job: Job(
        ownerID: "owner1",
        jobName: "Kitchen Remodel",
        clientName: "John Doe",
        address: "123 Main St",
        startDate: Date(),
        status: .active,
        notes: "",
        createdAt: Date(),
        projectValue: 10000,
        amountPaid: 0
    ))
    .environmentObject(AuthService.shared)
}
