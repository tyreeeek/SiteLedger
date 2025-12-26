import Foundation

enum TimesheetStatus: String, Codable {
    case working
    case completed
    case flagged  // Flagged by AI for review
}

// Friendly debug description for Timesheet to avoid revealing property-wrapper internals
extension Timesheet: CustomDebugStringConvertible {
    var debugDescription: String {
        let idDesc = id ?? "nil"
        let clockInStr = clockIn != nil ? ISO8601DateFormatter().string(from: clockIn!) : "nil"
        let clockOutStr = clockOut != nil ? ISO8601DateFormatter().string(from: clockOut!) : "nil"
        return "Timesheet(id: \(idDesc), ownerID: \(ownerID ?? "nil"), userID: \(userID ?? "nil"), jobID: \(jobID ?? "nil"), clockIn: \(clockInStr), clockOut: \(clockOutStr), status: \(status ?? "nil"))"
    }
}

struct Timesheet: Identifiable, Codable {
    var id: String?
    var ownerID: String?
    var userID: String?  // Worker ID - renamed from workerID to match API
    var jobID: String?
    var jobName: String?  // Job name from backend
    var clockIn: Date?
    var clockOut: Date?
    var hours: Double?
    var status: String?  // Changed from TimesheetStatus to String for flexibility
    var notes: String?
    var createdAt: Date?
    
    // LOCATION TRACKING
    var clockInLocation: String?  // GPS coordinates or address
    var clockOutLocation: String?
    
    // GEO-DISTANCE VALIDATION
    var clockInLatitude: Double?
    var clockInLongitude: Double?
    var clockOutLatitude: Double?
    var clockOutLongitude: Double?
    var distanceFromJobSite: Double?  // Distance in meters from job site when clocking in
    var isLocationValid: Bool?  // Whether location is within acceptable radius
    
    // AI FLAGS
    var aiFlags: [String]?  // ["auto_checkout", "unusual_hours", "location_mismatch", etc.]
    
    // Compatibility property
    var workerID: String? {
        get { userID }
        set { userID = newValue }
    }
    
    var isActive: Bool {
        return status == "working" || status == "active"
    }
    
    /// Computed hours from clockIn/clockOut (fallback if hours not set)
    var hoursWorked: Double {
        guard let clockIn = clockIn, let clockOut = clockOut else { return 0 }
        return clockOut.timeIntervalSince(clockIn) / 3600.0
    }
    
    /// Returns stored hours if set, otherwise computes from clockIn/clockOut
    var effectiveHours: Double {
        if let h = hours, h > 0 {
            return h
        }
        return hoursWorked
    }
    
    init() {
        // Default initializer
    }
    
    // Full init
    init(
        id: String? = nil,
        userID: String?,
        jobID: String?,
        clockIn: Date?,
        clockOut: Date? = nil,
        hours: Double? = nil,
        notes: String? = nil,
        status: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.userID = userID
        self.jobID = jobID
        self.clockIn = clockIn
        self.clockOut = clockOut
        self.hours = hours
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
    }
    
    // Legacy init for compatibility
    init(
        id: String? = nil,
        ownerID: String,
        workerID: String,
        jobID: String,
        clockIn: Date,
        clockOut: Date? = nil,
        hours: Double? = nil,
        status: TimesheetStatus,
        notes: String,
        createdAt: Date,
        clockInLocation: String? = nil,
        clockOutLocation: String? = nil,
        clockInLatitude: Double? = nil,
        clockInLongitude: Double? = nil,
        clockOutLatitude: Double? = nil,
        clockOutLongitude: Double? = nil,
        distanceFromJobSite: Double? = nil,
        isLocationValid: Bool? = nil,
        aiFlags: [String]? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.userID = workerID
        self.jobID = jobID
        self.clockIn = clockIn
        self.clockOut = clockOut
        self.status = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.clockInLocation = clockInLocation
        self.clockOutLocation = clockOutLocation
        self.clockInLatitude = clockInLatitude
        self.clockInLongitude = clockInLongitude
        self.clockOutLatitude = clockOutLatitude
        self.clockOutLongitude = clockOutLongitude
        self.distanceFromJobSite = distanceFromJobSite
        self.isLocationValid = isLocationValid
        self.aiFlags = aiFlags
        
        // Auto-calculate hours if clockOut is provided and hours is nil
        if let clockOut = clockOut, hours == nil {
            self.hours = clockOut.timeIntervalSince(clockIn) / 3600.0
        } else {
            self.hours = hours
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case userID
        case status
        case aiFlags
        case jobID
        case jobName
        case clockIn
        case clockOut
        case hours
        case notes
        case createdAt
        case clockInLocation
        case clockOutLocation
        case clockInLatitude
        case clockInLongitude
        case clockOutLatitude
        case clockOutLongitude
        case distanceFromJobSite
        case isLocationValid
    }
}
