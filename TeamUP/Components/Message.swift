//
//  Message.swift
//  TeamUP
//
//  Created by Marc Fernández on 20/2/25.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
    var content: String
    var isFromCurrentUser: Bool
    var timestamp: String
}
