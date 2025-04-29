import Foundation

struct MessageResponse: Codable {
    let _id: String
    let chatId: String
    let senderId: String
    let text: String
    let tipo: String
    let mediaUrl: String?
    let mediaType: String?
    let fileName: String?
    let fileSize: Int?
    let timestamp: String
    let estado: String
} 