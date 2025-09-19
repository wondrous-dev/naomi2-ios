//
//  ChatMessage.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public enum MessageSource: Codable, Equatable {
    case user
    case companion

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Backend may send "1"/"2" or strings like "user"/"companion"
        if let intString = try? container.decode(String.self) {
            switch intString.lowercased() {
            case "1", "user": self = .user
            case "2", "assistant", "companion": self = .companion
            default: self = .companion
            }
            return
        }
        if let intVal = try? container.decode(Int.self) {
            self = (intVal == 1) ? .user : .companion
            return
        }
        if let raw = try? container.decode(Bool.self) {
            self = raw ? .user : .companion
            return
        }
        self = .companion
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Encode as backend numeric string for safety
        switch self {
        case .user: try container.encode("1")
        case .companion: try container.encode("2")
        }
    }
}

public enum JSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let i = try? container.decode(Int.self) { self = .number(Double(i)); return }
        if let d = try? container.decode(Double.self) { self = .number(d); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        if let obj = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
            var result: [String: JSONValue] = [:]
            for key in obj.allKeys {
                if let value = try? obj.decode(JSONValue.self, forKey: key) {
                    result[key.stringValue] = value
                }
            }
            self = .object(result)
            return
        }
        var arrContainer = try decoder.unkeyedContainer()
        var arr: [JSONValue] = []
        while !arrContainer.isAtEnd {
            if let v = try? arrContainer.decode(JSONValue.self) { arr.append(v) }
        }
        self = .array(arr)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let s): var c = encoder.singleValueContainer(); try c.encode(s)
        case .number(let n): var c = encoder.singleValueContainer(); try c.encode(n)
        case .bool(let b): var c = encoder.singleValueContainer(); try c.encode(b)
        case .null: var c = encoder.singleValueContainer(); try c.encodeNil()
        case .object(let obj):
            var container = encoder.container(keyedBy: DynamicCodingKeys.self)
            for (k, v) in obj { try container.encode(v, forKey: DynamicCodingKeys(stringValue: k)!) }
        case .array(let arr):
            var container = encoder.unkeyedContainer()
            for v in arr { try container.encode(v) }
        }
    }
}

private struct DynamicCodingKeys: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: String
    public let timestamp: Int
    public let source: MessageSource
    public var text: String?
    public let userId: String?
    public let companionId: String?
    public let metadata: [String: JSONValue]?

    public var isUser: Bool { source == .user }

    public init(
        id: String = UUID().uuidString,
        timestamp: Int = Int(Date().timeIntervalSince1970),
        source: MessageSource,
        text: String?,
        userId: String? = nil,
        companionId: String? = nil,
        metadata: [String: JSONValue]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.text = text
        self.userId = userId
        self.companionId = companionId
        self.metadata = metadata
    }
}

// MARK: - API DTO mapping
public struct ChatMessageDTO: Codable {
    public let id: String
    public let timestamp: Int
    public let source: MessageSource
    public let text: String?
    public let userId: String?
    public let companionId: String?
    public let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case createdAt = "created_at"
        case source
        case text
        case userId = "user_id"
        case companionId = "companion_id"
        case metadata
    }

    public func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            timestamp: timestamp,
            source: source,
            text: text,
            userId: userId,
            companionId: companionId,
            metadata: metadata
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.source = (try? container.decode(MessageSource.self, forKey: .source)) ?? .companion
        self.text = try? container.decodeIfPresent(String.self, forKey: .text)
        self.userId = try? container.decodeIfPresent(String.self, forKey: .userId)
        self.companionId = try? container.decodeIfPresent(String.self, forKey: .companionId)
        self.metadata = try? container.decodeIfPresent([String: JSONValue].self, forKey: .metadata)

        if let ts = try? container.decode(Int.self, forKey: .timestamp) {
            self.timestamp = ts
        } else if let createdString = try? container.decode(String.self, forKey: .createdAt) {
            // Try numeric string first
            if let numericTs = Int(createdString) {
                self.timestamp = numericTs
            } else {
                let iso = ISO8601DateFormatter()
                if let date = iso.date(from: createdString) {
                    self.timestamp = Int(date.timeIntervalSince1970)
                } else {
                    // Last resort: current time
                    self.timestamp = Int(Date().timeIntervalSince1970)
                }
            }
        } else {
            self.timestamp = Int(Date().timeIntervalSince1970)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(companionId, forKey: .companionId)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}


