//
//  SettingsView.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppModel
    @State private var nameDraft: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display name", text: Binding(
                        get: { nameDraft.isEmpty ? app.profile.displayName : nameDraft },
                        set: { nameDraft = $0 }
                    ))
                    Button("Save") {
                        app.setDisplayName(nameDraft)
                        nameDraft = ""
                    }
                    .disabled((nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)).isEmpty)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppModel.preview)
    }
}


