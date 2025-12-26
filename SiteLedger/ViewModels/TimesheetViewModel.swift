import Foundation
import Combine

@MainActor
class TimesheetViewModel: ObservableObject {
    @Published var timesheets: [Timesheet] = []
    @Published var availableJobs: [Job] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCheckingIn = false
    @Published var isCheckingOut = false
    @Published var activeTimesheet: Timesheet?
    @Published var currentShiftDuration: String = "00:00:00"
    
    // Computed property - single source of truth
    var isCheckedIn: Bool {
        activeTimesheet?.status == "working"
    }
    
    private let apiService = APIService.shared
    
    /// Load data without filter (loads all timesheets for owner view)
    func loadData() async {
        await loadData(workerID: nil)
    }
    
    func loadData(workerID: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load timesheets
            let allTimesheets = try await apiService.fetchTimesheets()
            if let workerID = workerID {
                timesheets = allTimesheets.filter { $0.userID == workerID }
            } else {
                timesheets = allTimesheets
            }
            
            // Load available jobs
            availableJobs = try await apiService.fetchJobs()
            
            // Find active timesheet - single source of truth
            activeTimesheet = timesheets.first { $0.status == "working" }
            print("🟣 Active timesheet search: found \(activeTimesheet?.id ?? "none"), isCheckedIn: \(isCheckedIn)")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadTimesheets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            timesheets = try await apiService.fetchTimesheets()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadTimesheets(for jobID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allTimesheets = try await apiService.fetchTimesheets()
            timesheets = allTimesheets.filter { $0.jobID == jobID }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadTimesheets(for workerID: String, asWorker: Bool = true) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allTimesheets = try await apiService.fetchTimesheets()
            timesheets = allTimesheets.filter { $0.userID == workerID }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadAllTimesheetsForOwner(ownerID: String) {
        Task {
            await loadTimesheets()
        }
    }
    
    func createTimesheet(_ timesheet: Timesheet) async throws {
        try await apiService.createTimesheet(timesheet)
        // Don't auto-reload - let caller handle reload with proper context
    }
    
    func updateTimesheet(_ timesheet: Timesheet) async throws {
        try await apiService.updateTimesheet(timesheet)
        // Don't auto-reload - let caller handle reload with proper context
    }
    
    func deleteTimesheet(_ timesheet: Timesheet) async throws {
        guard let id = timesheet.id else { return }
        try await apiService.deleteTimesheet(id: id)
        await loadTimesheets()
    }
    
    func clockIn(workerID: String, jobID: String, notes: String? = nil) async throws {
        // Use the dedicated clock-in endpoint - this creates the timesheet on backend
        let apiTimesheet = try await apiService.clockIn(jobID: jobID, latitude: nil, longitude: nil, location: nil)
        print("🟣 ClockIn API successful, timesheet created: \(apiTimesheet.id)")
        
        // Don't manually set state here - let loadData() be the single source of truth
    }
    
    // Alias for views that use checkIn
    func checkIn(jobID: String) async throws {
        guard let currentUser = AuthService.shared.currentUser,
              let userID = currentUser.id else {
            throw APIError.unauthorized
        }
        try await clockIn(workerID: userID, jobID: jobID)
    }
    
    func checkOut() async throws {
        guard let active = activeTimesheet else { return }
        try await clockOut(timesheet: active)
        activeTimesheet = nil
    }
    
    func clockOut(timesheet: Timesheet) async throws {
        var updated = timesheet
        updated.clockOut = Date()
        if let clockIn = updated.clockIn {
            updated.hours = Date().timeIntervalSince(clockIn) / 3600.0
        }
        updated.status = "completed"
        try await updateTimesheet(updated)
    }
    
    // Calculate total hours for a job
    func totalHours(for jobID: String) -> Double {
        timesheets
            .filter { $0.jobID == jobID }
            .reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    // Calculate labor cost
    func laborCost(for jobID: String, hourlyRate: Double) -> Double {
        totalHours(for: jobID) * hourlyRate
    }
    
    // Get active timesheets (clocked in but not out)
    var activeTimesheets: [Timesheet] {
        timesheets.filter { $0.clockOut == nil && $0.status == "active" }
    }
    
    // Pending approval timesheets
    var pendingApproval: [Timesheet] {
        timesheets.filter { $0.status == "pending" }
    }
    
    func approveTimesheet(_ timesheet: Timesheet) async throws {
        var updated = timesheet
        updated.status = "approved"
        try await updateTimesheet(updated)
    }
    
    func rejectTimesheet(_ timesheet: Timesheet) async throws {
        var updated = timesheet
        updated.status = "rejected"
        try await updateTimesheet(updated)
    }
    
    // Calculate total hours across all timesheets
    func calculateTotalHours() -> Double {
        timesheets.reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    // Check in with notes (alias for views)
    func checkIn(jobID: String, notes: String?) async -> Bool {
        guard let currentUser = AuthService.shared.currentUser,
              let userID = currentUser.id else {
            return false
        }
        do {
            try await clockIn(workerID: userID, jobID: jobID, notes: notes)
            // Reload to get the actual timesheet from backend
            // Pass workerID so it filters correctly for workers
            await loadData(workerID: userID)
            print("🟣 After checkIn reload, activeTimesheet: \(activeTimesheet?.id ?? "none"), isCheckedIn: \(isCheckedIn)")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // Check in with location capture
    func checkIn(jobID: String, notes: String?, captureLocation: Bool) async -> Timesheet? {
        guard let currentUser = AuthService.shared.currentUser,
              let userID = currentUser.id else {
            return nil
        }
        isCheckingIn = true
        
        do {
            try await clockIn(workerID: userID, jobID: jobID, notes: notes)
            // Reload to get the actual timesheet from backend
            await loadData(workerID: userID)
            print("🟣 After checkIn reload, activeTimesheet: \(activeTimesheet?.id ?? "none"), isCheckedIn: \(isCheckedIn)")
            isCheckingIn = false
            return activeTimesheet
        } catch {
            errorMessage = error.localizedDescription
            isCheckingIn = false
            return nil
        }
    }
    
    // Check out with location capture option
    func checkOut(captureLocation: Bool = false, isAutoCheckout: Bool = false) async {
        guard activeTimesheet != nil else { return }
        guard let currentUser = AuthService.shared.currentUser,
              let userID = currentUser.id else {
            return
        }
        
        isCheckingOut = true
        
        do {
            // Use dedicated clock-out endpoint
            let _ = try await apiService.clockOut(latitude: nil, longitude: nil, location: nil, notes: nil)
            print("🟣 ClockOut API successful")
            // Reload from backend to get fresh state
            await loadData(workerID: userID)
            print("🟣 After checkOut reload, activeTimesheet: \(activeTimesheet?.id ?? "none"), isCheckedIn: \(isCheckedIn)")
            isCheckingOut = false
        } catch {
            errorMessage = error.localizedDescription
            isCheckingOut = false
        }
    }
    
    // Get formatted shift duration
    func getFormattedShiftDuration() -> String {
        guard let active = activeTimesheet,
              let clockIn = active.clockIn else {
            return "00:00:00"
        }
        let interval = Date().timeIntervalSince(clockIn)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Update shift duration (call this every second from view)
    func updateShiftDuration() {
        currentShiftDuration = getFormattedShiftDuration()
    }
}
