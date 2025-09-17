//
//  CodableStore.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

enum StoreKeys {
    static let goals = "store.goals"
    static let entries = "store.entries"
    static let profile = "store.profile"
    static let chat = "store.chat"
}

struct CodableStore {
    static func load<T: Decodable>(_ type: T.Type, forKey key: String, defaults: UserDefaults = .standard) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    static func save<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults = .standard) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            // Intentionally no-op for now
        }
    }
}


