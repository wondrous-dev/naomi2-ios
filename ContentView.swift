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
        ZStack(alignment: .bottom) {
            TabView {
                ChatView()
                    .tabItem {
                        Label("Coach", systemImage: "message")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            if let message = appModel.snackbarMessage {
                SnackbarView(text: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appModel.snackbarMessage)
        .environmentObject(appModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Snackbar View
struct SnackbarView: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial.opacity(0.2))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12))
        )
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

struct SnackbarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()
            SnackbarView(text: "Habit created")
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
        }
        .previewLayout(.sizeThatFits)
    }
}
