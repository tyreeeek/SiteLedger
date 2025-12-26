import Foundation
import Combine

@MainActor
class WorkerHoursViewModel: ObservableObject {
    @Published var timesheets: [Timesheet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterDays: Int = 30
    
    private let apiService = APIService.shared
    private var currentWorkerID: String?
    
    // Alias for views that use timeEntries
    var timeEntries: [Timesheet] {
        timesheets
    }
    
    func loadHours(for workerID: String) async {
        currentWorkerID = workerID
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
    
    func loadTimeEntries(for workerID: String) {
        Task {
            await loadHours(for: workerID)
        }
    }
    
    func loadTimeEntries(forUserId userId: String) {
        loadTimeEntries(for: userId)
    }
    
    var totalHours: Double {
        timesheets
            .filter { $0.status == "completed" }  // Only count completed timesheets
            .reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    var weeklyHours: Double {
        thisWeekHours
    }
    
    var thisWeekHours: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return timesheets
            .filter { ($0.clockIn ?? Date.distantPast) >= weekAgo }
            .filter { $0.status == "completed" }  // Only count completed timesheets
            .reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    var thisMonthHours: Double {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return timesheets
            .filter { ($0.clockIn ?? Date.distantPast) >= monthAgo }
            .filter { $0.status == "completed" }  // Only count completed timesheets
            .reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    func hoursGroupedByJob() -> [String: Double] {
        var result: [String: Double] = [:]
        for timesheet in timesheets {
            if let jobID = timesheet.jobID {
                result[jobID, default: 0] += timesheet.hours ?? 0
            }
        }
        return result
    }
}
