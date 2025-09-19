//
//  RemoteChatService.swift
//  naomi-ios
//
//  Created by Assistant on 9/19/25.
//

import Foundation

public struct RemoteChatService {
    public struct HistoryResponse: Codable { public let messages: [ChatMessageDTO] }

    public init() {}

    private let baseURL = URL(string: "http://localhost:8005")!

    public func fetchHistory(companionId: String?, limit: Int = 15, offset: Int = 0) async throws -> [ChatMessage] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/chat/history"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        if let companionId, !companionId.isEmpty {
            queryItems.append(URLQueryItem(name: "companion_id", value: companionId))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        print("[RemoteChatService] GET \(request.url?.absoluteString ?? "?")")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Try to decode as array of messages or wrapped object
        if let messages = try? JSONDecoder.api.decode([ChatMessageDTO].self, from: data) {
            return messages.map { $0.toDomain() }
        } else if let wrapped = try? JSONDecoder.api.decode(HistoryResponse.self, from: data) {
            return wrapped.messages.map { $0.toDomain() }
        } else {
            if let body = String(data: data, encoding: .utf8) {
                print("[RemoteChatService] history decode fallback. Raw body=\(body.prefix(500))")
            }
            // Fallback: try generic shape [{"role":"user","message":"..."}]
            struct Fallback: Codable { let role: String; let message: String }
            if let fallback = try? JSONDecoder.api.decode([Fallback].self, from: data) {
                return fallback.enumerated().map { idx, f in
                    ChatMessage(
                        id: UUID().uuidString,
                        timestamp: Int(Date().timeIntervalSince1970),
                        source: (f.role.lowercased() == "user") ? .user : .companion,
                        text: f.message,
                        userId: nil,
                        companionId: companionId,
                        metadata: nil
                    )
                }
            }
            throw URLError(.cannotParseResponse)
        }
    }

    public func sendMessage(userId: String?, message: String, companionId: String?) async throws -> ChatMessage? {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/chat/new-message"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String?] = [
            "user_id": userId,
            "message": message,
            "companion_id": companionId
        ]
        request.httpBody = try JSONEncoder.api.encode(body)

        print("[RemoteChatService] POST \(request.url?.absoluteString ?? "?") bodySize=\(request.httpBody?.count ?? 0)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Try to decode an assistant reply from server; otherwise, return nil (fire-and-forget)
        if let dto = try? JSONDecoder.api.decode(ChatMessageDTO.self, from: data) {
            return dto.toDomain()
        }
        return nil
    }
}

private extension JSONDecoder {
    static var api: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

private extension JSONEncoder {
    static var api: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}


