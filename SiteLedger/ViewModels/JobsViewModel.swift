import Foundation
import Combine

class JobsViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var selectedJob: Job?
    @Published var receipts: [Receipt] = []
    @Published var workers: [User] = []
    @Published var timesheets: [Timesheet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var currentUserID: String?
    
    init() {
        setupSignOutObserver()
    }
    
    private func setupSignOutObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearAllData),
            name: .userDidSignOut,
            object: nil
        )
    }
    
    @objc private func clearAllData() {
        jobs = []
        selectedJob = nil
        receipts = []
        workers = []
        timesheets = []
        isLoading = false
        errorMessage = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadJobs(userID: String) {
        currentUserID = userID
        isLoading = true
        Task {
            do {
                let apiJobs = try await apiService.getJobs()
                let mappedJobs = apiJobs.map { mapAPIJobToJob($0) }
                
                await MainActor.run {
                    self.jobs = mappedJobs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadWorkers(ownerID: String) {
        Task {
            do {
                let apiWorkers = try await apiService.getWorkers()
                let mappedWorkers = apiWorkers.map { mapAPIUserToUser($0) }
                
                await MainActor.run {
                    self.workers = mappedWorkers
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadTimesheets(userID: String) {
        Task {
            do {
                let apiTimesheets = try await apiService.getTimesheets()
                let mappedTimesheets = apiTimesheets.map { mapAPITimesheetToTimesheet($0) }
                
                await MainActor.run {
                    self.timesheets = mappedTimesheets
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Load all receipts for profit calculations
    func loadAllReceipts() {
        Task {
            do {
                let allReceipts = try await apiService.fetchReceipts()
                await MainActor.run {
                    self.receipts = allReceipts
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadReceiptsForJob(jobID: String) {
        Task {
            do {
                let allReceipts = try await apiService.fetchReceipts()
                await MainActor.run {
                    self.receipts = allReceipts.filter { $0.jobID == jobID }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createJob(_ job: Job) async throws {
        // Use APIService.createJob(_ job: Job) directly - it handles date formatting correctly
        try await apiService.createJob(job)
        
        // Reload jobs list after creating
        if let userID = currentUserID {
            loadJobs(userID: userID)
        }
    }
    
    func updateJob(_ job: Job, with updates: [String: Any]) async throws {
        guard let jobID = job.id else { return }
        _ = try await apiService.updateJob(id: jobID, updates: updates)
        
        // Reload jobs list after updating
        if let userID = currentUserID {
            loadJobs(userID: userID)
        }
    }
    
    func deleteJob(_ job: Job) async throws {
        guard let jobID = job.id else { return }
        _ = try await apiService.deleteJob(id: jobID)
        
        // Reload jobs list after deleting
        if let userID = currentUserID {
            loadJobs(userID: userID)
        }
    }
    
    // MARK: - Labor Cost Calculation
    
    func getJobLaborCost(jobID: String) -> Double {
        let jobTimesheets = timesheets.filter { $0.jobID == jobID }
        var totalCost: Double = 0
        
        for timesheet in jobTimesheets {
            let hours = timesheet.effectiveHours
            if let worker = workers.first(where: { $0.id == timesheet.workerID }),
               let hourlyRate = worker.hourlyRate,
               hours > 0 {
                totalCost += hours * hourlyRate
            }
        }
        
        return totalCost
    }
    
    /// Calculate total receipt expenses for a job
    func getJobReceiptExpenses(jobID: String) -> Double {
        return receipts
            .filter { $0.jobID == jobID }
            .reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    /// Calculate remaining job value after subtracting receipt expenses
    /// Remaining Job Value = Original Job Value - Total Receipts
    func getRemainingJobValue(job: Job) -> Double {
        guard let jobID = job.id else { return job.projectValue }
        let receiptExpenses = getJobReceiptExpenses(jobID: jobID)
        let remaining = job.projectValue - receiptExpenses
        // Never show negative values unless intentionally allowed
        return max(0, remaining)
    }
    
    func getJobProfit(job: Job) -> Double {
        guard let jobID = job.id else { return 0 }
        let laborCost = getJobLaborCost(jobID: jobID)
        let receiptExpenses = getJobReceiptExpenses(jobID: jobID)
        return job.calculateProfit(laborCost: laborCost, receiptExpenses: receiptExpenses)
    }
    
    // MARK: - Mapping Functions
    
    private func mapAPIJobToJob(_ apiJob: APIService.APIJob) -> Job {
        let dateFormatter = ISO8601DateFormatter()
        let startDate = dateFormatter.date(from: apiJob.startDate) ?? Date()
        let endDate = apiJob.endDate.flatMap { dateFormatter.date(from: $0) }
        let createdAt = dateFormatter.date(from: apiJob.createdAt) ?? Date()
        
        let status: Job.JobStatus
        switch apiJob.status {
        case "completed": status = .completed
        case "on_hold": status = .onHold
        default: status = .active
        }
        
        var job = Job(
            ownerID: apiJob.ownerID,
            jobName: apiJob.jobName,
            clientName: apiJob.clientName,
            address: apiJob.address,
            latitude: apiJob.latitude,
            longitude: apiJob.longitude,
            startDate: startDate,
            endDate: endDate,
            status: status,
            notes: apiJob.notes,
            createdAt: createdAt,
            projectValue: apiJob.projectValue,
            amountPaid: apiJob.amountPaid
        )
        job.id = apiJob.id
        job.assignedWorkers = apiJob.assignedWorkers
        return job
    }
    
    private func mapAPITimesheetToTimesheet(_ apiTimesheet: APIService.APITimesheet) -> Timesheet {
        let dateFormatter = ISO8601DateFormatter()
        let clockIn = dateFormatter.date(from: apiTimesheet.clockIn) ?? Date()
        let clockOut = apiTimesheet.clockOut.flatMap { dateFormatter.date(from: $0) }
        let createdAt = dateFormatter.date(from: apiTimesheet.createdAt) ?? Date()
        
        let status: TimesheetStatus
        switch apiTimesheet.status {
        case "completed": status = .completed
        case "flagged": status = .flagged
        default: status = .working
        }
        
        return Timesheet(
            id: apiTimesheet.id,
            ownerID: apiTimesheet.ownerID,
            workerID: apiTimesheet.workerID,
            jobID: apiTimesheet.jobID,
            clockIn: clockIn,
            clockOut: clockOut,
            hours: apiTimesheet.hours,
            status: status,
            notes: apiTimesheet.notes ?? "",
            createdAt: createdAt
        )
    }
    
    private func mapAPIUserToUser(_ apiUser: APIService.APIUser) -> User {
        let role: UserRole = apiUser.role == "worker" ? .worker : .owner
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: apiUser.createdAt) ?? Date()
        
        return User(
            id: apiUser.id,
            ownerID: apiUser.ownerId,
            name: apiUser.name,
            email: apiUser.email,
            phone: apiUser.phone,
            photoURL: apiUser.photoURL,
            role: role,
            hourlyRate: apiUser.hourlyRate,
            active: apiUser.active,
            assignedJobIDs: apiUser.assignedJobIDs,
            createdAt: createdAt
        )
    }
    
    func reloadJob(jobID: String) async {
        do {
            let apiJob = try await apiService.getJob(id: jobID)
            let updatedJob = mapAPIJobToJob(apiJob)
            await MainActor.run {
                if let idx = self.jobs.firstIndex(where: { $0.id == jobID }) {
                    self.jobs[idx] = updatedJob
                }
                if self.selectedJob?.id == jobID {
                    self.selectedJob = updatedJob
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
