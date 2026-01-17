import Foundation

struct AppNotification: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    var read: Bool
    let data: [String: AnyCodable]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, message, read, data
        case createdAt = "created_at"
    }
}

// Helper to handle any JSON value
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let array as [AnyCodable]:
            try container.encode(array)
        default:
            try container.encodeNil()
        }
    }
}

struct NotificationsResponse: Codable {
    let notifications: [AppNotification]
    let unreadCount: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case notifications
        case unreadCount = "unreadCount"
        case hasMore
    }
}
