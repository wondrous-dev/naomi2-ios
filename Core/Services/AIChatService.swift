//
//  AIChatService.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import Foundation

public struct AIChatService {
    public init() {}

    public func reply(to userText: String, contextGoals: [Goal], profile: UserProfile) async -> String {
        // Simple local stub. In future, integrate with an LLM API.
        let name = profile.displayName.isEmpty ? "there" : profile.displayName
        let goalsList = contextGoals.filter { $0.isActive }.map { $0.title }.joined(separator: ", ")
        let encouragements = [
            "You’ve got this!",
            "Small steps add up.",
            "Consistency beats intensity.",
            "Proud of your progress!"
        ]
        let encouragement = encouragements.randomElement() ?? "Keep going!"
        let prefix = goalsList.isEmpty ? "Let’s set a goal together." : "Your active goals are: \(goalsList)."
        return "Hi \(name), \(prefix) \(encouragement) You said: \"\(userText)\""
    }
}


