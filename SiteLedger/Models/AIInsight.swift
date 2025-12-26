import Foundation

struct AIInsight: Identifiable, Codable {
    var id: String?
    var ownerID: String
    var insight: String
    var category: String  // "cost", "profit", "labor", "efficiency"
    var severity: String  // "info", "warning", "critical"
    var actionable: Bool
    var createdAt: Date
    
    init(
        ownerID: String,
        insight: String,
        category: String,
        severity: String = "info",
        actionable: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = nil
        self.ownerID = ownerID
        self.insight = insight
        self.category = category
        self.severity = severity
        self.actionable = actionable
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerID
        case insight
        case category
        case severity
        case actionable
        case createdAt
    }
}
