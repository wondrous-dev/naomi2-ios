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
    @Published var goals: [Goal]
    @Published var entries: [DailyEntry]
    @Published var profile: UserProfile
    @Published var chatHistory: [ChatMessage]

    private let chatService: AIChatService

    init(
        goals: [Goal] = CodableStore.load([Goal].self, forKey: StoreKeys.goals) ?? [],
        entries: [DailyEntry] = CodableStore.load([DailyEntry].self, forKey: StoreKeys.entries) ?? [],
        profile: UserProfile = CodableStore.load(UserProfile.self, forKey: StoreKeys.profile) ?? UserProfile(),
        chatHistory: [ChatMessage] = CodableStore.load([ChatMessage].self, forKey: StoreKeys.chat) ?? [],
        chatService: AIChatService = AIChatService()
    ) {
        self.goals = goals
        self.entries = entries
        self.profile = profile
        self.chatHistory = chatHistory
        self.chatService = chatService
    }

    // MARK: - Persistence
    private func persistAll() {
        CodableStore.save(goals, forKey: StoreKeys.goals)
        CodableStore.save(entries, forKey: StoreKeys.entries)
        CodableStore.save(profile, forKey: StoreKeys.profile)
        CodableStore.save(chatHistory, forKey: StoreKeys.chat)
    }

    // MARK: - Goals
    func addGoal(title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        goals.append(Goal(title: title))
        persistAll()
    }

    func updateGoal(_ goal: Goal, title: String? = nil, isActive: Bool? = nil) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        var copy = goals[index]
        if let title = title { copy.title = title }
        if let isActive = isActive { copy.isActive = isActive }
        goals[index] = copy
        persistAll()
    }

    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        // Optionally also remove related entries
        entries.removeAll { $0.goalId == goal.id }
        persistAll()
    }

    // MARK: - Daily Entries
    func entry(for goalId: UUID, on date: Date) -> DailyEntry? {
        let day = date.stripTime()
        return entries.first { $0.goalId == goalId && $0.date.stripTime() == day }
    }

    func setStatus(for goal: Goal, on date: Date = Date(), status: EntryStatus) {
        let day = date.stripTime()
        if let idx = entries.firstIndex(where: { $0.goalId == goal.id && $0.date.stripTime() == day }) {
            entries[idx].status = status
        } else {
            entries.append(DailyEntry(date: day, goalId: goal.id, status: status))
        }
        persistAll()
    }

    func clearStatus(for goal: Goal, on date: Date = Date()) {
        let day = date.stripTime()
        if let idx = entries.firstIndex(where: { $0.goalId == goal.id && $0.date.stripTime() == day }) {
            entries[idx].status = .pending
            persistAll()
        }
    }

    // MARK: - Profile
    func setDisplayName(_ name: String) {
        profile.displayName = name
        persistAll()
    }

    // MARK: - Chat
    func sendChat(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatHistory.append(ChatMessage(role: .user, text: trimmed))
        persistAll()

        let response = await chatService.reply(to: trimmed, contextGoals: goals, profile: profile)
        chatHistory.append(ChatMessage(role: .assistant, text: response))
        persistAll()
    }
}

// MARK: - Helpers
private extension Date {
    func stripTime() -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: comps) ?? self
    }
}

// MARK: - Preview Mock
extension AppModel {
    static var preview: AppModel {
        let model = AppModel()
        model.goals = [
            Goal(title: "Meditate"),
            Goal(title: "Workout"),
            Goal(title: "Read 20 min", isActive: false)
        ]
        model.profile = UserProfile(displayName: "Alex")
        return model
    }
}



