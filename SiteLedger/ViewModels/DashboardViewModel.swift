import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var receipts: [Receipt] = []
    @Published var timesheets: [Timesheet] = []
    @Published var workers: [User] = []
    @Published var recentReceipts: [Receipt] = []
    @Published var totalReceiptsAmount: Double = 0.0
    @Published var monthlyLaborCost: Double = 0.0
    @Published var monthlyNetProfit: Double = 0.0
    @Published var totalProjectValue: Double = 0.0
    @Published var totalLaborCost: Double = 0.0
    @Published var netProfit: Double = 0.0
    @Published var activeJobsCount: Int = 0
    @Published var totalJobsCount: Int = 0
    @Published var activeJobs: [Job] = []
    @Published var alerts: [Alert] = []
    @Published var recentAlerts: [Alert] = []
    @Published var unreadAlerts: Int = 0
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
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
        receipts = []
        timesheets = []
        workers = []
        recentReceipts = []
        totalReceiptsAmount = 0.0
        monthlyLaborCost = 0.0
        monthlyNetProfit = 0.0
        totalProjectValue = 0.0
        totalLaborCost = 0.0
        netProfit = 0.0
        activeJobsCount = 0
        totalJobsCount = 0
        activeJobs = []
        alerts = []
        recentAlerts = []
        unreadAlerts = 0
        isLoading = false
    }
    
    func loadData(forUserId userId: String) {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        
        Task {
            await loadAllData()
        }
    }
    
    private func loadAllData() async {
        do {
            // Load jobs
            let apiJobs = try await apiService.getJobs()
            let mappedJobs = apiJobs.map { mapAPIJobToJob($0) }
            
            // Load receipts
            let apiReceipts = try await apiService.getReceipts()
            let mappedReceipts = apiReceipts.map { mapAPIReceiptToReceipt($0) }
            
            // Load timesheets
            let apiTimesheets = try await apiService.getTimesheets()
            let mappedTimesheets = apiTimesheets.map { mapAPITimesheetToTimesheet($0) }
            
            // Load workers
            let apiWorkers = try await apiService.getWorkers()
            let mappedWorkers = apiWorkers.map { mapAPIUserToUser($0) }
            
            await MainActor.run {
                self.jobs = mappedJobs
                self.receipts = mappedReceipts
                self.timesheets = mappedTimesheets
                self.workers = mappedWorkers
                
                // Calculate metrics
                self.calculateMetrics()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func calculateMetrics() {
        // Jobs metrics
        totalJobsCount = jobs.count
        activeJobs = jobs.filter { $0.status == .active }
        activeJobsCount = activeJobs.count
        
        // Financial metrics
        totalProjectValue = jobs.reduce(0) { $0 + $1.projectValue }
        
        // Calculate labor cost from timesheets
        totalLaborCost = calculateTotalLaborCost()
        
        // Calculate total receipt expenses
        let totalReceiptExpenses = receipts.reduce(0) { $0 + ($1.amount ?? 0) }
        
        // Net profit = project value - labor cost - receipt expenses
        netProfit = totalProjectValue - totalLaborCost - totalReceiptExpenses
        
        // Recent receipts (last 5) - sorted by createdAt with optional handling
        recentReceipts = Array(receipts.sorted { 
            ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) 
        }.prefix(5))
        totalReceiptsAmount = receipts.reduce(0) { $0 + ($1.amount ?? 0) }
        
        // Monthly calculations
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthlyTimesheets = timesheets.filter { timesheet in
            guard let clockIn = timesheet.clockIn else { return false }
            return clockIn >= startOfMonth
        }
        monthlyLaborCost = calculateLaborCost(for: monthlyTimesheets)
        
        // Monthly receipt expenses
        let monthlyReceipts = receipts.filter { receipt in
            guard let createdAt = receipt.createdAt else { return false }
            return createdAt >= startOfMonth
        }
        let monthlyReceiptExpenses = monthlyReceipts.reduce(0) { $0 + ($1.amount ?? 0) }
        
        // Job.createdAt is non-optional, so this is safe
        let monthlyJobs = jobs.filter { $0.createdAt >= startOfMonth }
        let monthlyProjectValue = monthlyJobs.reduce(0) { $0 + $1.projectValue }
        monthlyNetProfit = monthlyProjectValue - monthlyLaborCost - monthlyReceiptExpenses
    }
    
    private func calculateTotalLaborCost() -> Double {
        return calculateLaborCost(for: timesheets)
    }
    
    private func calculateLaborCost(for timesheets: [Timesheet]) -> Double {
        var totalCost: Double = 0
        
        for timesheet in timesheets {
            let hours = timesheet.effectiveHours
            if let worker = workers.first(where: { $0.id == timesheet.workerID }),
               let hourlyRate = worker.hourlyRate,
               hours > 0 {
                totalCost += hours * hourlyRate
            }
        }
        
        return totalCost
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
        
        return Job(
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
    }
    
    private func mapAPIReceiptToReceipt(_ apiReceipt: APIService.APIReceipt) -> Receipt {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: apiReceipt.date) ?? Date()
        let createdAt = dateFormatter.date(from: apiReceipt.createdAt) ?? Date()
        
        return Receipt(
            ownerID: apiReceipt.ownerID,
            jobID: apiReceipt.jobID,
            amount: apiReceipt.amount,
            vendor: apiReceipt.vendor,
            category: apiReceipt.category,
            date: date,
            imageURL: apiReceipt.imageURL,
            notes: apiReceipt.notes ?? "",
            createdAt: createdAt,
            aiProcessed: apiReceipt.aiProcessed ?? false,
            aiConfidence: apiReceipt.aiConfidence,
            aiFlags: apiReceipt.aiFlags,
            aiSuggestedCategory: apiReceipt.aiSuggestedCategory
        )
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
    
    // MARK: - Public Methods
    
    func refresh() {
        Task {
            await loadAllData()
        }
    }
    
    func getJobLaborCost(job: Job) -> Double {
        let jobTimesheets = timesheets.filter { $0.jobID == job.id }
        return calculateLaborCost(for: jobTimesheets)
    }
    
    /// Calculate total receipt expenses for a specific job
    func getJobReceiptExpenses(job: Job) -> Double {
        return receipts
            .filter { $0.jobID == job.id }
            .reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    func getJobProfit(job: Job) -> Double {
        let laborCost = getJobLaborCost(job: job)
        let receiptExpenses = getJobReceiptExpenses(job: job)
        return job.calculateProfit(laborCost: laborCost, receiptExpenses: receiptExpenses)
    }
}
