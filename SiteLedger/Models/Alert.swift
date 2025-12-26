import Foundation

enum AlertSeverity: String, Codable {
    case info
    case warning
    case critical
}

enum AlertType: String, Codable {
    case budget        // Budget overruns
    case labor         // Labor cost issues
    case receipt       // Receipt anomalies
    case document      // Document issues
    case timesheet     // Timesheet issues
    case payment       // Payment reminders
}

struct Alert: Identifiable, Codable {
    var id: String?
    var ownerID: String
    var jobID: String?
    var type: AlertType
    var severity: AlertSeverity
    var title: String
    var message: String
    var actionURL: String? // Deep link to relevant screen
    var read: Bool
    var createdAt: Date
    
    // Computed property for icon based on alert type
    var icon: String {
        switch type {
        case .budget:
            return "dollarsign.circle.fill"
        case .labor:
            return "person.fill"
        case .receipt:
            return "doc.text.fill"
        case .document:
            return "folder.fill"
        case .timesheet:
            return "clock.fill"
        case .payment:
            return "creditcard.fill"
        }
    }
    
    // Computed property for time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    init(
        ownerID: String,
        jobID: String? = nil,
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        actionURL: String? = nil,
        read: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = nil
        self.ownerID = ownerID
        self.jobID = jobID
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.actionURL = actionURL
        self.read = read
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case jobID
        case type
        case severity
        case title
        case message
        case actionURL
        case read
        case createdAt
    }
}
