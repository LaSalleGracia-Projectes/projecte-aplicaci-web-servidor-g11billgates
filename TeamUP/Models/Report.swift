import Foundation

struct Report: Codable {
    let id: String
    let userId: String
    let type: ReportType
    let description: String
    let timestamp: Date
    let status: ReportStatus
    
    enum ReportType: String, Codable {
        case inappropriateContent = "inappropriate_content"
        case spam = "spam"
        case harassment = "harassment"
        case other = "other"
    }
    
    enum ReportStatus: String, Codable {
        case pending = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
        case dismissed = "dismissed"
    }
} 