//
//  GoalsView.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var app: AppModel
    @State private var newGoalTitle: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Add Goal") {
                    HStack {
                        TextField("Goal title", text: $newGoalTitle)
                        Button("Add") {
                            let title = newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !title.isEmpty else { return }
                            app.addGoal(title: title)
                            newGoalTitle = ""
                        }
                        .disabled(newGoalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Goals") {
                    ForEach(app.goals) { goal in
                        GoalRow(goal: goal)
                    }
                    .onDelete { indexSet in
                        indexSet.map { app.goals[$0] }.forEach { app.deleteGoal($0) }
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar { EditButton() }
        }
    }
}

private struct GoalRow: View {
    @EnvironmentObject var app: AppModel
    @State var goal: Goal
    @State private var isEditing = false

    var body: some View {
        HStack {
            if isEditing {
                TextField("Title", text: $goal.title)
                Button("Save") {
                    app.updateGoal(goal, title: goal.title)
                    isEditing = false
                }
            } else {
                Text(goal.title)
                Spacer()
                Toggle("Active", isOn: Binding(
                    get: { goal.isActive },
                    set: { newValue in
                        goal.isActive = newValue
                        app.updateGoal(goal, isActive: newValue)
                    }
                ))
                .labelsHidden()
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
            .environmentObject(AppModel.preview)
    }
}


