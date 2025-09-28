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
    @Published var snackbarMessage: String?

    private let remoteChatService: RemoteChatService
    private var hasLoadedChatHistoryOnce = false
    private static let migrationFlagKey = "store.migrated.removeGoalsEntries.v1"

    // Realtime
    private var realtime: RealtimeChatListening? = RealtimeChatService()
    private var realtimeCancellable: AnyCancellable?
    private var eventCancellable: AnyCancellable?

    init(
        profile: UserProfile = CodableStore.load(UserProfile.self, forKey: StoreKeys.profile) ?? UserProfile(),
        chatHistory: [ChatMessage] = CodableStore.load([ChatMessage].self, forKey: StoreKeys.chat) ?? [],
        remoteChatService: RemoteChatService = RemoteChatService()
    ) {
        // One-time migration: remove legacy keys from pre-chat-only versions
        Self.migrateIfNeeded()
        self.profile = profile
        self.chatHistory = chatHistory.isEmpty ? [] : chatHistory.sorted { $0.sentAt < $1.sentAt }
        self.remoteChatService = remoteChatService
        startRealtimeIfNeeded()
    }

    // MARK: - Persistence
    private func persistAll() {
        CodableStore.save(profile, forKey: StoreKeys.profile)
        CodableStore.save(chatHistory, forKey: StoreKeys.chat)
    }

    // MARK: - Utilities
    func clearAllLocalData() {
        // Reset in-memory state
        profile = UserProfile()
        chatHistory = []
        // Persist cleared state so UI and storage are consistent
        persistAll()
    }

    // Goals and daily entries removed

    // MARK: - Profile
    func setDisplayName(_ name: String) {
        profile.displayName = name
        persistAll()
    }

    // MARK: - Realtime
    private func startRealtimeIfNeeded() {
        guard realtimeCancellable == nil else { return }
        realtimeCancellable = realtime?.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.ingestRealtime(message)
            }
        eventCancellable = realtime?.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleRealtimeEvent(event)
            }
        realtime?.start(userId: "1")
    }

    private func stopRealtime() {
        realtime?.stop()
        realtimeCancellable?.cancel()
        realtimeCancellable = nil
        eventCancellable?.cancel()
        eventCancellable = nil
    }

    private func ingestRealtime(_ message: ChatMessage) {
        // Merge single message into history
        mergeMessages([message])
    }

    private func handleRealtimeEvent(_ event: RealtimeEvent) {
        switch event {
        case .habitsCreated:
            showSnackbar("Habit created")
        }
    }

    private func showSnackbar(_ text: String) {
        snackbarMessage = text
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if self?.snackbarMessage == text {
                self?.snackbarMessage = nil
            }
        }
    }

    // MARK: - Chat
    func sendChat(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Optimistic local append with a temporary id so UI is instant
        let tempId = UUID().uuidString
        let pending = ChatMessage(id: tempId, source: .user, text: trimmed, userId: nil, companionId: "1234567", metadata: nil, status: .pending)
        chatHistory.append(pending)
        persistAll()
        do {
            if let serverUserEcho = try await remoteChatService.sendMessage(userId: nil, message: trimmed, companionId: "1234567") {
                // Replace the pending local message with the server-authoritative one (id/sentAt)
                if let idx = chatHistory.lastIndex(where: { $0.id == tempId }) {
                    chatHistory[idx] = ChatMessage(
                        id: serverUserEcho.id,
                        sentAt: serverUserEcho.sentAt,
                        source: .user,
                        text: serverUserEcho.text ?? trimmed,
                        userId: serverUserEcho.userId,
                        companionId: serverUserEcho.companionId,
                        metadata: serverUserEcho.metadata,
                        status: .sent
                    )
                    chatHistory = sortMessages(chatHistory)
                } else {
                    // Fallback: just append if we lost track of the pending item
                    var sentEcho = serverUserEcho
                    sentEcho.status = .sent
                    chatHistory.append(sentEcho)
                    chatHistory = sortMessages(chatHistory)
                }
                persistAll()
            }
            // Reconcile with server after send to avoid drift/duplicates
            Task { [weak self] in
                await self?.refreshChatHistoryDelta(limit: 15, offset: 0)
            }
        } catch {
            print("[AppModel] sendChat error: \(error)")
            // Mark pending as failed so user can retry
            if let idx = chatHistory.lastIndex(where: { $0.id == tempId }) {
                var failed = chatHistory[idx]
                failed.status = .failed
                chatHistory[idx] = failed
                persistAll()
            }
        }
    }

    func loadChatHistory(limit: Int = 15, offset: Int = 0) async {
        print("[AppModel] loadChatHistory(limit: \(limit), offset: \(offset))")
        do {
            let history = try await remoteChatService.fetchHistory(companionId: "1234567", limit: limit, offset: offset)
            chatHistory = sortMessages(history)
            persistAll()
        } catch {
            print("[AppModel] loadChatHistory error: \(error)")
            // Keep existing local history on failure
        }
    }

    func ensureChatHistoryLoadedOnce(limit: Int = 15, offset: Int = 0) async {
        guard !hasLoadedChatHistoryOnce else { return }
        hasLoadedChatHistoryOnce = true
        await refreshChatHistoryDelta(limit: limit, offset: offset)
    }

    /// Merge latest server history into local without disrupting immediately-shown cached messages
    func refreshChatHistoryDelta(limit: Int = 15, offset: Int = 0) async {
        print("[AppModel] refreshChatHistoryDelta(limit: \(limit), offset: \(offset))")
        do {
            let incoming = try await remoteChatService.fetchHistory(companionId: "1234567", limit: limit, offset: offset)
            mergeMessages(incoming)
        } catch {
            print("[AppModel] refreshChatHistoryDelta error: \(error)")
        }
    }

    // MARK: - Merge
    private func mergeMessages(_ incoming: [ChatMessage]) {
        // Build map from existing messages by id
        var mergedById: [String: ChatMessage] = Dictionary(uniqueKeysWithValues: chatHistory.map { ($0.id, $0) })

        for message in incoming {
            if var existing = mergedById[message.id] {
                // Prefer non-nil fields from server and the most recent sentAt
                existing.text = message.text ?? existing.text
                let newerTs = max(existing.sentAt, message.sentAt)
                let newStatus: MessageStatus? = message.status ?? .sent
                mergedById[message.id] = ChatMessage(
                    id: existing.id,
                    sentAt: newerTs,
                    source: message.source,
                    text: existing.text,
                    userId: message.userId ?? existing.userId,
                    companionId: message.companionId ?? existing.companionId,
                        metadata: message.metadata ?? existing.metadata,
                        habitSuggestion: message.habitSuggestion ?? existing.habitSuggestion,
                    status: newStatus
                )
            } else {
                // Soft de-duplication: if same source/text and close sentAt exists, replace it with server one
                if let dup = mergedById.values.first(where: { $0.source == message.source && $0.text == message.text && abs($0.sentAt - message.sentAt) <= 30 }) {
                    mergedById.removeValue(forKey: dup.id)
                }
                var msg = message
                if msg.status == nil { msg.status = .sent }
                mergedById[message.id] = msg
            }
        }

        // Sort by sentAt ascending only
        let merged = sortMessages(Array(mergedById.values))
        chatHistory = merged
        persistAll()
    }

    // MARK: - Retry
    func retrySend(messageId: String) async {
        guard let idx = chatHistory.firstIndex(where: { $0.id == messageId }) else { return }
        var msg = chatHistory[idx]
        guard msg.isUser else { return }
        guard (msg.status == .failed || msg.status == .pending) else { return }
        let text = msg.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { return }

        // Mark as pending
        msg.status = .pending
        chatHistory[idx] = msg
        persistAll()

        do {
            if let serverUserEcho = try await remoteChatService.sendMessage(userId: msg.userId, message: text, companionId: msg.companionId) {
                // Replace with server echo
                chatHistory[idx] = ChatMessage(
                    id: serverUserEcho.id,
                    sentAt: serverUserEcho.sentAt,
                    source: .user,
                    text: serverUserEcho.text ?? text,
                    userId: serverUserEcho.userId,
                    companionId: serverUserEcho.companionId,
                    metadata: serverUserEcho.metadata,
                    status: .sent
                )
                chatHistory = sortMessages(chatHistory)
                persistAll()
            } else {
                // Treat no echo as sent for now, will reconcile in delta
                msg.status = .sent
                chatHistory[idx] = msg
                persistAll()
            }
            Task { [weak self] in
                await self?.refreshChatHistoryDelta(limit: 15, offset: 0)
            }
        } catch {
            var failed = chatHistory[idx]
            failed.status = .failed
            chatHistory[idx] = failed
            persistAll()
        }
    }

    private func sortMessages(_ messages: [ChatMessage]) -> [ChatMessage] {
        messages.sorted { a, b in
            if a.sentAt == b.sentAt { return a.id < b.id }
            return a.sentAt < b.sentAt
        }
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



