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
    @State private var showClearDefaultsAlert: Bool = false

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
                #if DEBUG
                Section("Debug") {
                    Button("Clear Defaults", role: .destructive) {
                        showClearDefaultsAlert = true
                    }
                    .font(.footnote)
                }
                #endif
            }
            .navigationTitle("Settings")
            #if DEBUG
            .alert("Clear all local settings?", isPresented: $showClearDefaultsAlert) {
                Button("Clear", role: .destructive) {
                    #if DEBUG
                    resetDefaults()
                    app.clearAllLocalData()
                    #endif
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes all UserDefaults for this app in Debug builds.")
            }
            #endif
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppModel.preview)
    }
}

#if DEBUG
func resetDefaults() {
    if let bundleID = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
        print("✅ UserDefaults cleared for \(bundleID)")
    }
}
#endif


