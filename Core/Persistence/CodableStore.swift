//
//  CodableStore.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

enum StoreKeys {
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

    static func remove(forKey key: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    static func remove(keys: [String], defaults: UserDefaults = .standard) {
        keys.forEach { defaults.removeObject(forKey: $0) }
    }

    static func keys(withPrefix prefix: String, defaults: UserDefaults = .standard) -> [String] {
        Array(defaults.dictionaryRepresentation().keys).filter { $0.hasPrefix(prefix) }
    }

    static func wipeAllStoreKeys(defaults: UserDefaults = .standard) {
        let keys = keys(withPrefix: "store.", defaults: defaults)
        remove(keys: keys, defaults: defaults)
    }
}


