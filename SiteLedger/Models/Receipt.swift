import Foundation

/// Receipt model - Tracks job expenses that subtract from profit
/// When a receipt is added to a job, its amount is subtracted from the job's net profit
struct Receipt: Identifiable, Codable {
    var id: String?
    var ownerID: String?
    var jobID: String?
    var amount: Double?         // Expense amount - subtracted from job profit when jobID is set
    var vendor: String?
    var category: String?
    var date: Date?
    var imageURL: String?
    var notes: String?
    var createdAt: Date?
    
    // AI PROCESSING FIELDS
    var aiProcessed: Bool?
    var aiConfidence: Double?   // 0.0 to 1.0
    var aiFlags: [String]?      // ["duplicate", "unusual_amount", "missing_info", etc.]
    var aiSuggestedCategory: String?
    
    // Receipt Categories
    // IMPORTANT: Raw values MUST match backend database constraint
    // Backend expects: 'materials', 'fuel', 'equipment', 'subcontractors', 'misc'
    enum ReceiptCategory: String, CaseIterable, Codable {
        case materials = "materials"
        case gasFuel = "fuel"
        case equipment = "equipment"
        case other = "misc"
        
        var displayName: String {
            switch self {
            case .materials: return "Materials"
            case .gasFuel: return "Gas/Fuel"
            case .equipment: return "Tools"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .materials: return "hammer.fill"
            case .gasFuel: return "fuelpump.fill"
            case .equipment: return "wrench.and.screwdriver.fill"
            case .other: return "doc.text.fill"
            }
        }
    }
    
    init() {
        // Default initializer
    }
    
    init(
        ownerID: String,
        jobID: String? = nil,
        amount: Double,
        vendor: String,
        category: String? = nil,
        date: Date,
        imageURL: String? = nil,
        notes: String,
        createdAt: Date,
        aiProcessed: Bool,
        aiConfidence: Double? = nil,
        aiFlags: [String]? = nil,
        aiSuggestedCategory: String? = nil
    ) {
        self.id = nil
        self.ownerID = ownerID
        self.jobID = jobID
        self.amount = amount
        self.vendor = vendor
        self.category = category
        self.date = date
        self.imageURL = imageURL
        self.notes = notes
        self.createdAt = createdAt
        self.aiProcessed = aiProcessed
        self.aiConfidence = aiConfidence
        self.aiFlags = aiFlags
        self.aiSuggestedCategory = aiSuggestedCategory
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case jobID
        case amount
        case vendor
        case category
        case date
        case imageURL
        case notes
        case createdAt
        case aiProcessed
        case aiConfidence
        case aiFlags
        case aiSuggestedCategory
    }
}
