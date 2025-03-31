//
//  Message.swift
//  TeamUP
//
//  Created by Marc Fernández on 20/2/25.
//

import Foundation

enum MessageType {
    case text
    case image
    case video
}

struct Message: Identifiable {
    let id = UUID()
    var content: String
    var type: MessageType
    var mediaURL: String?
    var isFromCurrentUser: Bool
    var timestamp: String
    var duration: Double? // Para videos
    
    init(content: String, type: MessageType = .text, mediaURL: String? = nil, isFromCurrentUser: Bool, timestamp: String, duration: Double? = nil) {
        self.content = content
        self.type = type
        self.mediaURL = mediaURL
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
        self.duration = duration
    }
}
