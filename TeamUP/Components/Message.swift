//
//  Message.swift
//  TeamUP
//
//  Created by Marc Fernández on 20/2/25.
//

import Foundation

public enum MessageType {
    case text
    case image
    case video
    case voice
}

public struct Message: Identifiable {
    public let id: String
    public var content: String
    public var type: MessageType
    public var mediaURL: String?
    public var isFromCurrentUser: Bool
    public var timestamp: String
    public var duration: Double? // Para videos y mensajes de voz
    
    public init(id: String = UUID().uuidString, content: String, type: MessageType = .text, mediaURL: String? = nil, isFromCurrentUser: Bool, timestamp: String, duration: Double? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.mediaURL = mediaURL
        self.isFromCurrentUser = isFromCurrentUser
        self.timestamp = timestamp
        self.duration = duration
    }
}
