//
//  ContentView.swift
//  naomi-ios
//
//  Created by Junhe Li on 9/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appModel = AppModel()

    var body: some View {
        TabView {
            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "checkmark.circle")
                }
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            ChatView()
                .tabItem {
                    Label("Coach", systemImage: "message")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(appModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
