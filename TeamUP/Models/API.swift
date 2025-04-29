import Foundation

struct API {
    static let baseURL = "http://localhost:3001/api"
    
    enum Endpoint {
        case messages
        case uploadChatMedia
        
        var path: String {
            switch self {
            case .messages:
                return "\(baseURL)/messages"
            case .uploadChatMedia:
                return "\(baseURL)/upload-chat-media"
            }
        }
    }
} 