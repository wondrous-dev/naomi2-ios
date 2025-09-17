//
//  DailyEntry.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public enum EntryStatus: String, Codable, CaseIterable, Equatable {
    case pending
    case done
    case skipped
}

public struct DailyEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public var date: Date
    public let goalId: UUID
    public var status: EntryStatus
    public var notes: String?

    public init(id: UUID = UUID(), date: Date, goalId: UUID, status: EntryStatus = .pending, notes: String? = nil) {
        self.id = id
        self.date = date
        self.goalId = goalId
        self.status = status
        self.notes = notes
    }

    // Backward compatibility with older stored data using isCompleted: Bool
    private enum CodingKeys: String, CodingKey { case id, date, goalId, status, notes, isCompleted }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(Date.self, forKey: .date)
        self.goalId = try container.decode(UUID.self, forKey: .goalId)
        if let status = try container.decodeIfPresent(EntryStatus.self, forKey: .status) {
            self.status = status
        } else if let oldCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) {
            self.status = oldCompleted ? .done : .pending
        } else {
            self.status = .pending
        }
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(goalId, forKey: .goalId)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}


