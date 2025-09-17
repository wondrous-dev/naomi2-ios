//
//  Goal.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public struct Goal: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var isActive: Bool
    public let createdAt: Date

    public init(id: UUID = UUID(), title: String, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isActive = isActive
        self.createdAt = createdAt
    }
}


