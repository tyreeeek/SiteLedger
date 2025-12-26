import Foundation
import Combine

@MainActor
class AIInsightsViewModel: ObservableObject {
    @Published var insights: [AIInsight] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadInsights(ownerID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all required data from API
            let jobs = try await apiService.fetchJobs()
            let receipts = try await apiService.fetchReceipts()
            let timesheets = try await apiService.fetchTimesheets()
            
            // Generate insights from the data
            await generateInsights(for: jobs, receipts: receipts, timesheets: timesheets, ownerID: ownerID)
        } catch {
            errorMessage = error.localizedDescription
            insights = []
            isLoading = false
        }
    }
    
    func generateInsights(for jobs: [Job], receipts: [Receipt], timesheets: [Timesheet], ownerID: String) async {
        isLoading = true
        
        // Generate basic insights client-side
        var newInsights: [AIInsight] = []
        
        // Active jobs insight
        let activeJobs = jobs.filter { $0.status == .active }
        if !activeJobs.isEmpty {
            let insight = AIInsight(
                ownerID: ownerID,
                insight: "You have \(activeJobs.count) active project\(activeJobs.count == 1 ? "" : "s")",
                category: "summary",
                severity: "info"
            )
            newInsights.append(insight)
        }
        
        // Total project value insight
        let totalValue = jobs.reduce(0.0) { $0 + $1.projectValue }
        if totalValue > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let valueStr = formatter.string(from: NSNumber(value: totalValue)) ?? "$0"
            let insight = AIInsight(
                ownerID: ownerID,
                insight: "Total project value: \(valueStr)",
                category: "profit",
                severity: "info"
            )
            newInsights.append(insight)
        }
        
        // Unpaid invoices insight
        let totalUnpaid = jobs.reduce(0.0) { $0 + ($1.projectValue - $1.amountPaid) }
        if totalUnpaid > 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let unpaidStr = formatter.string(from: NSNumber(value: totalUnpaid)) ?? "$0"
            let insight = AIInsight(
                ownerID: ownerID,
                insight: "\(unpaidStr) in outstanding payments",
                category: "profit",
                severity: "warning",
                actionable: true
            )
            newInsights.append(insight)
        }
        
        // Recent receipts insight
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentReceipts = receipts.filter { ($0.date ?? Date()) > thirtyDaysAgo }
        let recentExpenses = recentReceipts.reduce(0.0) { $0 + ($1.amount ?? 0) }
        if recentExpenses > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let expenseStr = formatter.string(from: NSNumber(value: recentExpenses)) ?? "$0"
            let insight = AIInsight(
                ownerID: ownerID,
                insight: "\(expenseStr) in expenses this month (\(recentReceipts.count) receipts)",
                category: "cost",
                severity: "info"
            )
            newInsights.append(insight)
        }
        
        // Budget warnings for jobs
        for job in jobs where job.status == .active {
            let projectValue = job.projectValue
            let laborCost = timesheets
                .filter { $0.jobID == job.id }
                .reduce(0.0) { $0 + (($1.hours ?? 0) * 50.0) } // Assume $50/hr default
            
            let jobReceipts = receipts.filter { $0.jobID == job.id }
            let receiptExpenses = jobReceipts.reduce(0.0) { $0 + ($1.amount ?? 0) }
            
            let totalCost = laborCost + receiptExpenses
            
            if projectValue > 0 && totalCost > projectValue * 0.8 {
                let percentage = Int(totalCost / projectValue * 100)
                let insight = AIInsight(
                    ownerID: ownerID,
                    insight: "⚠️ \(job.jobName) is at \(percentage)% of budget",
                    category: "cost",
                    severity: percentage >= 100 ? "critical" : "warning",
                    actionable: true
                )
                newInsights.append(insight)
            }
        }
        
        // If no insights, add a helpful message
        if newInsights.isEmpty {
            let insight = AIInsight(
                ownerID: ownerID,
                insight: "Add jobs, receipts, and timesheets to get personalized insights",
                category: "summary",
                severity: "info"
            )
            newInsights.append(insight)
        }
        
        insights = newInsights
        isLoading = false
    }
    
    func dismissInsight(_ insight: AIInsight) {
        insights.removeAll { $0.id == insight.id }
    }
}
