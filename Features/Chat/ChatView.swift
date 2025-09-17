//
//  ChatView.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var app: AppModel
    @State private var inputText: String = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(app.chatHistory) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: app.chatHistory.count) { _ in
                        if let last = app.chatHistory.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }

                HStack {
                    TextField("Message", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task {
                            await send()
                        }
                    } label: {
                        Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                    }
                    .disabled(isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Coach")
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.text)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if message.role == .assistant { Spacer() }
        }
    }

    private func send() async {
        guard !isSending else { return }
        isSending = true
        let text = inputText
        inputText = ""
        await app.sendChat(text)
        isSending = false
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(AppModel.preview)
    }
}


