//
//  DailyView.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import SwiftUI

private enum DailyFilter: String, CaseIterable, Identifiable {
    case todos = "To-dos"
    case done = "Done"
    case skipped = "Skipped"
    var id: String { rawValue }
}

struct DailyView: View {
    @EnvironmentObject var app: AppModel
    private let today = Date()
    @State private var filter: DailyFilter = .todos

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                filterHeader
                    .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredGoals) { goal in
                            GoalCard(goal: goal, status: status(for: goal)) { action in
                                switch action {
                                case .markDone:
                                    app.setStatus(for: goal, on: today, status: .done)
                                case .markSkipped:
                                    app.setStatus(for: goal, on: today, status: .skipped)
                                case .reset:
                                    app.clearStatus(for: goal, on: today)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Daily")
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filter)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: app.entries)
    }

    private var filterHeader: some View {
        HStack(spacing: 10) {
            Pill(title: "To-dos", count: count(.todos), isSelected: filter == .todos) { filter = .todos }
            Pill(title: "Done", count: count(.done), isSelected: filter == .done) { filter = .done }
            Pill(title: "Skipped", count: count(.skipped), isSelected: filter == .skipped) { filter = .skipped }
            Spacer()
            Button {
                // Placeholder for add new quick action
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }

    private var filteredGoals: [Goal] {
        let activeGoals = app.goals.filter { $0.isActive }
        switch filter {
        case .todos:
            return activeGoals.filter { status(for: $0) == .pending }
        case .done:
            return activeGoals.filter { status(for: $0) == .done }
        case .skipped:
            return activeGoals.filter { status(for: $0) == .skipped }
        }
    }

    private func status(for goal: Goal) -> EntryStatus {
        app.entry(for: goal.id, on: today)?.status ?? .pending
    }

    private func count(_ filter: DailyFilter) -> Int {
        let goals = app.goals.filter { $0.isActive }
        switch filter {
        case .todos:
            return goals.filter { status(for: $0) == .pending }.count
        case .done:
            return goals.filter { status(for: $0) == .done }.count
        case .skipped:
            return goals.filter { status(for: $0) == .skipped }.count
        }
    }
}

private struct Pill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text("\(count)")
                    .font(.footnote.weight(.bold))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Color.white.opacity(0.25), in: Capsule())
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                ? AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(Color.secondary.opacity(0.15)),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}

private enum GoalAction { case markDone, markSkipped, reset }

private struct GoalCard: View {
    let goal: Goal
    let status: EntryStatus
    let onAction: (GoalAction) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22)
                .fill(cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 12) {
                Text(goal.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 14) {
                    Label("Everyday", systemImage: "arrow.triangle.2.circlepath")
                    Label("Difficulty", systemImage: "chart.bar")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

                HStack(spacing: 10) {
                    if status == .pending {
                        actionButton(title: "Done", icon: "checkmark.circle.fill", bg: .green) { onAction(.markDone) }
                        actionButton(title: "Skip", icon: "xmark.circle.fill", bg: .orange) { onAction(.markSkipped) }
                    } else {
                        actionButton(title: "Reset", icon: "arrow.uturn.backward", bg: .gray) { onAction(.reset) }
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(20)

            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 34, height: 34)
                .overlay(Image(systemName: "info.circle").foregroundStyle(.white))
                .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }

    private var cardGradient: LinearGradient {
        let colors: [Color]
        switch status {
        case .pending:
            colors = [.blue, .purple]
        case .done:
            colors = [.green, .teal]
        case .skipped:
            colors = [.orange, .pink]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func actionButton(title: String, icon: String, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.bold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(bg.opacity(0.9), in: Capsule())
            .foregroundStyle(.white)
            .shadow(radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct DailyView_Previews: PreviewProvider {
    static var previews: some View {
        DailyView()
            .environmentObject(AppModel.preview)
    }
}


