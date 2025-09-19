//
//  AppModel.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var chatHistory: [ChatMessage]

    private let remoteChatService: RemoteChatService
    private var hasLoadedChatHistoryOnce = false
    private static let migrationFlagKey = "store.migrated.removeGoalsEntries.v1"

    init(
        profile: UserProfile = CodableStore.load(UserProfile.self, forKey: StoreKeys.profile) ?? UserProfile(),
        chatHistory: [ChatMessage] = CodableStore.load([ChatMessage].self, forKey: StoreKeys.chat) ?? [],
        remoteChatService: RemoteChatService = RemoteChatService()
    ) {
        // One-time migration: remove legacy keys from pre-chat-only versions
        Self.migrateIfNeeded()
        self.profile = profile
        self.chatHistory = chatHistory
        self.remoteChatService = remoteChatService
    }

    // MARK: - Persistence
    private func persistAll() {
        CodableStore.save(profile, forKey: StoreKeys.profile)
        CodableStore.save(chatHistory, forKey: StoreKeys.chat)
    }

    // Goals and daily entries removed

    // MARK: - Profile
    func setDisplayName(_ name: String) {
        profile.displayName = name
        persistAll()
    }

    // MARK: - Chat
    func sendChat(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatHistory.append(ChatMessage(source: .user, text: trimmed, userId: nil, companionId: "1234567", metadata: nil))
        persistAll()
        do {
            if let reply = try await remoteChatService.sendMessage(userId: nil, message: trimmed, companionId: "1234567") {
                chatHistory.append(reply)
                persistAll()
            }
        } catch {
            print("[AppModel] sendChat error: \(error)")
            // Keep user message; consider surfacing an error toast if needed.
        }
    }

    func loadChatHistory(limit: Int = 15, offset: Int = 0) async {
        print("[AppModel] loadChatHistory(limit: \(limit), offset: \(offset))")
        do {
            let history = try await remoteChatService.fetchHistory(companionId: "1234567", limit: limit, offset: offset)
            chatHistory = history
            persistAll()
        } catch {
            print("[AppModel] loadChatHistory error: \(error)")
            // Keep existing local history on failure
        }
    }

    func ensureChatHistoryLoadedOnce(limit: Int = 15, offset: Int = 0) async {
        guard !hasLoadedChatHistoryOnce else { return }
        hasLoadedChatHistoryOnce = true
        await loadChatHistory(limit: limit, offset: offset)
    }
}

// MARK: - Migration
extension AppModel {
    private static func migrateIfNeeded(defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: migrationFlagKey) { return }
        // Remove legacy keys for old features
        CodableStore.remove(keys: [
            "store.goals",
            "store.entries"
        ], defaults: defaults)
        defaults.set(true, forKey: migrationFlagKey)
    }
}

// MARK: - Preview Mock
extension AppModel {
    static var preview: AppModel {
        let model = AppModel()
        model.profile = UserProfile(displayName: "Alex")
        return model
    }
}



