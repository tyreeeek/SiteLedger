import Foundation

/// Represents a payment made to a worker
/// Tracks payment history so the owner (admin) can see all payments made to each worker
struct WorkerPayment: Identifiable, Codable, CustomDebugStringConvertible {
    var id: String?
    
    /// Owner who made this payment (admin)
    var ownerID: String
    
    /// Worker who received this payment
    var workerID: String
    
    /// Worker's name (denormalized for display)
    var workerName: String
    
    /// Amount paid
    var amount: Double
    
    /// Date the payment was made
    var paymentDate: Date
    
    /// Start of the pay period this covers
    var periodStart: Date
    
    /// End of the pay period this covers
    var periodEnd: Date
    
    /// Hours worked in this pay period (calculated at time of payment)
    var hoursWorked: Double
    
    /// Hourly rate at time of payment
    var hourlyRate: Double
    
    /// Calculated earnings for the period (hours × rate) - for reference
    var calculatedEarnings: Double
    
    /// Payment method
    var paymentMethod: PaymentMethod
    
    /// Optional notes about the payment
    var notes: String?
    
    /// Reference number (check number, transaction ID, etc.)
    var referenceNumber: String?
    
    /// When this record was created
    var createdAt: Date
    
    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "cash"
        case check = "check"
        case directDeposit = "direct_deposit"
        case venmo = "venmo"
        case zelle = "zelle"
        case paypal = "paypal"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .cash: return "Cash"
            case .check: return "Check"
            case .directDeposit: return "Direct Deposit"
            case .venmo: return "Venmo"
            case .zelle: return "Zelle"
            case .paypal: return "PayPal"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .cash: return "dollarsign.circle.fill"
            case .check: return "doc.text.fill"
            case .directDeposit: return "building.columns.fill"
            case .venmo: return "v.circle.fill"
            case .zelle: return "z.circle.fill"
            case .paypal: return "p.circle.fill"
            case .other: return "creditcard.fill"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case workerID
        case workerName
        case amount
        case paymentDate
        case periodStart
        case periodEnd
        case hoursWorked
        case hourlyRate
        case calculatedEarnings
        case paymentMethod
        case notes
        case referenceNumber
        case createdAt
    }
    
    init(
        ownerID: String,
        workerID: String,
        workerName: String,
        amount: Double,
        paymentDate: Date = Date(),
        periodStart: Date,
        periodEnd: Date,
        hoursWorked: Double,
        hourlyRate: Double,
        calculatedEarnings: Double,
        paymentMethod: PaymentMethod = .cash,
        notes: String? = nil,
        referenceNumber: String? = nil,
        createdAt: Date = Date()
    ) {
        self.ownerID = ownerID
        self.workerID = workerID
        self.workerName = workerName
        self.amount = amount
        self.paymentDate = paymentDate
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.hoursWorked = hoursWorked
        self.hourlyRate = hourlyRate
        self.calculatedEarnings = calculatedEarnings
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.referenceNumber = referenceNumber
        self.createdAt = createdAt
    }
    
    var debugDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return "WorkerPayment(id: \(id ?? "nil"), worker: \(workerName), amount: $\(String(format: "%.2f", amount)), date: \(dateFormatter.string(from: paymentDate)))"
    }
}

/// Summary of a worker's earnings and payments
struct WorkerPayrollSummary: Identifiable {
    var id: String { workerID }
    
    var workerID: String
    var workerName: String
    var hourlyRate: Double
    
    /// Total hours worked (all time or in period)
    var totalHoursWorked: Double
    
    /// Total earnings (hours × rate)
    var totalEarnings: Double
    
    /// Total amount paid to this worker
    var totalPaid: Double
    
    /// Balance owed to worker (earnings - paid)
    var balanceOwed: Double {
        return totalEarnings - totalPaid
    }
    
    /// Number of payments made
    var paymentCount: Int
    
    /// Last payment date
    var lastPaymentDate: Date?
    
    /// Is this worker currently active?
    var isActive: Bool
}
