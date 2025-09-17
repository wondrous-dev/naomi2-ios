//
//  ChatMessage.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public enum ChatRole: String, Codable {
    case user
    case assistant
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let role: ChatRole
    public var text: String
    public let timestamp: Date

    public init(id: UUID = UUID(), role: ChatRole, text: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}


