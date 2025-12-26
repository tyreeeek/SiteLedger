import Foundation

/// Represents a contractor project/job with financial tracking
struct Job: Identifiable, Codable {
    var id: String?
    
    /// Owner ID
    var ownerID: String
    
    /// Name of the project
    var jobName: String
    
    /// Name of the client/customer
    var clientName: String
    
    /// Project address
    var address: String
    
    /// Job site GPS coordinates for geo-fencing (optional)
    var latitude: Double?
    var longitude: Double?
    
    /// Project start date
    var startDate: Date
    
    /// Project end date (optional)
    var endDate: Date?
    
    /// Job status: Active, Completed, or On Hold
    var status: JobStatus
    
    /// User notes about the job
    var notes: String
    
    /// When this job was created
    var createdAt: Date
    
    // FINANCIAL FIELDS
    /// Total project value (contract amount)
    var projectValue: Double
    
    /// Amount client has paid so far
    var amountPaid: Double
    
    /// Assigned worker IDs
    var assignedWorkers: [String]?
    
    enum JobStatus: String, Codable {
        case active = "active"
        case completed = "completed"
        case onHold = "on_hold"
    }
    
    init(
        ownerID: String,
        jobName: String,
        clientName: String,
        address: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        startDate: Date,
        endDate: Date? = nil,
        status: JobStatus,
        notes: String,
        createdAt: Date,
        projectValue: Double,
        amountPaid: Double,
        assignedWorkers: [String]? = nil
    ) {
        self.id = nil
        self.ownerID = ownerID
        self.jobName = jobName
        self.clientName = clientName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.projectValue = projectValue
        self.amountPaid = amountPaid
        self.assignedWorkers = assignedWorkers
    }
    
    // COMPUTED PROFIT PROPERTIES
    /// Calculate profit: projectValue - laborCost - receiptExpenses
    /// Receipts now affect profit as job expenses
    func calculateProfit(laborCost: Double = 0, receiptExpenses: Double = 0) -> Double {
        return projectValue - laborCost - receiptExpenses
    }
    
    /// Remaining balance owed by client
    var remainingBalance: Double {
        return projectValue - amountPaid
    }
    
    /// Calculate total labor cost for this job
    func calculateLaborCost(timesheets: [Timesheet], workers: [User]) -> Double {
        var totalCost: Double = 0
        
        for timesheet in timesheets where timesheet.jobID == self.id {
            let workerID = timesheet.workerID
            let hours = timesheet.effectiveHours  // Use effectiveHours to handle nil hours
            if let worker = workers.first(where: { $0.id == workerID }),
               let hourlyRate = worker.hourlyRate,
               hours > 0 {
                totalCost += hours * hourlyRate
            }
        }
        
        return totalCost
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case jobName
        case clientName
        case address
        case latitude
        case longitude
        case startDate
        case endDate
        case status
        case notes
        case createdAt
        case projectValue
        case amountPaid
        case assignedWorkers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Debug: Try to decode ID
        let idValue = try? container.decode(String.self, forKey: .id)
        #if DEBUG
        print("🔴 Decoding Job ID: \(idValue ?? "FAILED TO DECODE")")
        #endif
        self.id = idValue
        
        self.ownerID = try container.decode(String.self, forKey: .ownerID)
        self.jobName = try container.decode(String.self, forKey: .jobName)
        self.clientName = try container.decode(String.self, forKey: .clientName)
        self.address = try container.decode(String.self, forKey: .address)
        self.latitude = try? container.decode(Double.self, forKey: .latitude)
        self.longitude = try? container.decode(Double.self, forKey: .longitude)
        
        // Decode dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let startDateString = try? container.decode(String.self, forKey: .startDate),
           let date = dateFormatter.date(from: startDateString) {
            self.startDate = date
        } else {
            self.startDate = Date()
        }
        
        if let endDateString = try? container.decode(String.self, forKey: .endDate),
           let date = dateFormatter.date(from: endDateString) {
            self.endDate = date
        } else {
            self.endDate = nil
        }
        
        self.status = try container.decode(JobStatus.self, forKey: .status)
        self.notes = try container.decode(String.self, forKey: .notes)
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            self.createdAt = date
        } else {
            self.createdAt = Date()
        }
        
        self.projectValue = try container.decode(Double.self, forKey: .projectValue)
        self.amountPaid = try container.decode(Double.self, forKey: .amountPaid)
        self.assignedWorkers = try? container.decode([String].self, forKey: .assignedWorkers)
    }
}
