import Foundation

struct Document: Identifiable, Codable {
    var id: String?
    var ownerID: String
    var jobID: String?
    var fileURL: String
    var fileType: DocumentType
    var title: String
    var notes: String
    var createdAt: Date
    
    // AI PROCESSING FIELDS (Phase 8)
    var aiProcessed: Bool
    var aiSummary: String?
    var aiExtractedData: [String: String]? // Key-value pairs extracted by AI
    var aiConfidence: Double? // 0.0 to 1.0 confidence score
    var aiFlags: [String]? // Flags like "low_quality", "missing_signature", etc.
    var documentCategory: DocumentCategory? // AI-detected document type
    
    enum DocumentType: String, Codable {
        case pdf = "pdf"
        case image = "image"
        case other = "other"
    }
    
    enum DocumentCategory: String, Codable {
        case contract = "contract"
        case invoice = "invoice"
        case estimate = "estimate"
        case permit = "permit"
        case receipt = "receipt"
        case photo = "photo"
        case blueprint = "blueprint"
        case other = "other"
    }
    
    init(
        ownerID: String,
        jobID: String? = nil,
        fileURL: String,
        fileType: DocumentType,
        title: String,
        notes: String = "",
        createdAt: Date = Date(),
        aiProcessed: Bool = false,
        aiSummary: String? = nil,
        aiExtractedData: [String: String]? = nil,
        aiConfidence: Double? = nil,
        aiFlags: [String]? = nil,
        documentCategory: DocumentCategory? = nil
    ) {
        self.id = nil
        self.ownerID = ownerID
        self.jobID = jobID
        self.fileURL = fileURL
        self.fileType = fileType
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.aiProcessed = aiProcessed
        self.aiSummary = aiSummary
        self.aiExtractedData = aiExtractedData
        self.aiConfidence = aiConfidence
        self.aiFlags = aiFlags
        self.documentCategory = documentCategory
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case title
        case jobID
        case fileURL
        case fileType
        case notes
        case createdAt
        case aiProcessed
        case aiSummary
        case aiExtractedData
        case aiConfidence
        case aiFlags
        case documentCategory
    }
}
