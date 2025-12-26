import Foundation

enum UserRole: String, Codable {
    case owner
    case worker
}

struct WorkerPermissions: Codable {
    var canViewFinancials: Bool
    var canUploadReceipts: Bool
    var canApproveTimesheets: Bool
    var canSeeAIInsights: Bool
    var canViewAllJobs: Bool
    
    static var `default`: WorkerPermissions {
        WorkerPermissions(
            canViewFinancials: false,
            canUploadReceipts: true,
            canApproveTimesheets: false,
            canSeeAIInsights: false,
            canViewAllJobs: false
        )
    }
}

struct User: Identifiable, Codable {
    var id: String?
    var ownerID: String?  // Owner who manages this worker (worker role only)
    var name: String
    var email: String
    var phone: String?       // Contact phone number
    var photoURL: String?    // Profile photo URL
    var role: UserRole
    var hourlyRate: Double?  // For workers - used in labor cost calculations
    var active: Bool
    var assignedJobIDs: [String]?  // Jobs this worker is assigned to (worker role only)
    var workerPermissions: WorkerPermissions?  // Permissions for worker role
    var hasPassword: Bool?   // False for Apple Sign-In users who don't have passwords
    var isAppleUser: Bool {
        // Heuristic: Apple users have no password and email ends with 'privaterelay.appleid.com'
        (hasPassword == false) || (email.contains("appleid.com"))
    }
    var hasNoPassword: Bool {
        hasPassword == false
    }
    var createdAt: Date
    
    init(
        id: String? = nil,
        ownerID: String? = nil,
        name: String,
        email: String,
        phone: String? = nil,
        photoURL: String? = nil,
        role: UserRole = .owner,
        hourlyRate: Double? = nil,
        active: Bool = true,
        assignedJobIDs: [String]? = nil,
        workerPermissions: WorkerPermissions? = nil,
        hasPassword: Bool? = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.email = email
        self.phone = phone
        self.photoURL = photoURL
        self.role = role
        self.hourlyRate = hourlyRate
        self.active = active
        self.assignedJobIDs = assignedJobIDs
        self.workerPermissions = workerPermissions
        self.hasPassword = hasPassword
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, ownerID, name, email, phone, photoURL, role, hourlyRate, active, assignedJobIDs, workerPermissions, hasPassword, createdAt
    }
    
    // Custom decoder to handle hourlyRate as either String or Double
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        ownerID = try container.decodeIfPresent(String.self, forKey: .ownerID)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        role = try container.decode(UserRole.self, forKey: .role)
        active = try container.decode(Bool.self, forKey: .active)
        assignedJobIDs = try container.decodeIfPresent([String].self, forKey: .assignedJobIDs)
        workerPermissions = try container.decodeIfPresent(WorkerPermissions.self, forKey: .workerPermissions)
        hasPassword = try container.decodeIfPresent(Bool.self, forKey: .hasPassword)
        
        // Handle hourlyRate as either String or Double
        if let hourlyRateString = try? container.decodeIfPresent(String.self, forKey: .hourlyRate) {
            hourlyRate = Double(hourlyRateString)
        } else {
            hourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)
        }
        
        // Handle createdAt
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                createdAt = Date()
            }
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
    }
}
