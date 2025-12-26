import Foundation
import Combine

// Uses WorkerPayrollSummary from Models/WorkerPayment.swift

@MainActor
class WorkerPaymentViewModel: ObservableObject {
    @Published var payments: [WorkerPayment] = []
    @Published var timesheets: [Timesheet] = []
    @Published var workers: [User] = []
    @Published var workerSummaries: [WorkerPayrollSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Load Methods
    
    func loadPayments(for workerID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load timesheets for this worker
            let allTimesheets = try await apiService.fetchTimesheets()
            timesheets = allTimesheets.filter { $0.userID == workerID }
            
            // Payments would come from a payments endpoint
            payments = []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadPayrollData(ownerID: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Load workers
                workers = try await apiService.fetchWorkers()
                
                // Load all timesheets
                timesheets = try await apiService.fetchTimesheets()
                
                // Load all payments
                payments = try await apiService.getPayments(ownerID: ownerID)
                
                // Generate summaries
                await MainActor.run {
                    workerSummaries = workers.map { worker in
                        let workerTimesheets = timesheets.filter { $0.userID == worker.id }
                        let totalHoursWorked = workerTimesheets.reduce(0) { $0 + ($1.hours ?? 0) }
                        let hourlyRate = worker.hourlyRate ?? 50.0
                        let totalEarnings = totalHoursWorked * hourlyRate
                        
                        // Calculate actual payments for this worker
                        let workerPayments = payments.filter { $0.workerID == worker.id }
                        let totalPaid = workerPayments.reduce(0) { $0 + $1.amount }
                        let paymentCount = workerPayments.count
                        let lastPaymentDate = workerPayments.map { $0.paymentDate }.max()
                        
                        return WorkerPayrollSummary(
                            workerID: worker.id ?? "",
                            workerName: worker.name,
                            hourlyRate: hourlyRate,
                            totalHoursWorked: totalHoursWorked,
                            totalEarnings: totalEarnings,
                            totalPaid: totalPaid,
                            paymentCount: paymentCount,
                            lastPaymentDate: lastPaymentDate,
                            isActive: worker.active
                        )
                    }
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func getWorker(_ workerID: String) -> User? {
        workers.first { $0.id == workerID }
    }
    
    // MARK: - Payment Methods
    
    func createPayment(_ payment: WorkerPayment) async throws {
        // Create payment record
        payments.append(payment)
    }
    
    func createPayment(
        ownerID: String,
        workerID: String,
        workerName: String,
        amount: Double,
        paymentDate: Date,
        periodStart: Date,
        periodEnd: Date,
        hoursWorked: Double,
        hourlyRate: Double,
        paymentMethod: WorkerPayment.PaymentMethod,
        notes: String?,
        referenceNumber: String?
    ) async throws {
        let payment = WorkerPayment(
            ownerID: ownerID,
            workerID: workerID,
            workerName: workerName,
            amount: amount,
            paymentDate: paymentDate,
            periodStart: periodStart,
            periodEnd: periodEnd,
            hoursWorked: hoursWorked,
            hourlyRate: hourlyRate,
            calculatedEarnings: hoursWorked * hourlyRate,
            paymentMethod: paymentMethod,
            notes: notes,
            referenceNumber: referenceNumber,
            createdAt: Date()
        )
        
        // Save to backend
        let savedPayment = try await apiService.createPayment(payment)
        
        // Add to local array
        await MainActor.run {
            payments.append(savedPayment)
        }
        
        // Refresh payroll data to update balances
        await loadPayrollData(ownerID: ownerID)
    }
    
    // MARK: - Computed Properties
    
    var totalEarned: Double {
        // Calculate from approved timesheets
        timesheets
            .filter { $0.status == "approved" }
            .reduce(0) { $0 + (($1.hours ?? 0) * 50.0) } // Default rate
    }
    
    var totalPaid: Double {
        payments.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalEarned - totalPaid
    }
    
    var totalBalanceOwed: Double {
        workerSummaries.reduce(0) { $0 + $1.balanceOwed }
    }
    
    var paidThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        return payments
            .filter { $0.paymentDate >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalPaidThisMonth: Double {
        paidThisMonth
    }
    
    var totalPaidThisWeek: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        return payments
            .filter { $0.paymentDate >= startOfWeek }
            .reduce(0) { $0 + $1.amount }
    }
    
    func pendingHours() -> Double {
        timesheets
            .filter { $0.status == "pending" }
            .reduce(0) { $0 + ($1.hours ?? 0) }
    }
    
    // MARK: - Formatting
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
