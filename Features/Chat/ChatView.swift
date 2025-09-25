//
//  ChatView.swift
//  naomi-ios
//
//  Created by Assistant on 9/12/25.
//

import SwiftUI
import Inject

struct ChatView: View {
    @ObserveInjection var inject
    @EnvironmentObject var app: AppModel
    @State private var inputText: String = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background image
                Image("NaomiBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Readability gradient overlay
                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(app.chatHistory) { message in
                                    MessageView(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 120) // room for input bar inset
                        }
                        .onChange(of: app.chatHistory.count) { _ in
                            if let last = app.chatHistory.last { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                        .task {
                            // Load once per app lifetime to avoid dup fetches
                            await app.ensureChatHistoryLoadedOnce(limit: 15, offset: 0)
                        }
                        .onAppear {
                            if let last = app.chatHistory.last { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Hana")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 6)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    TextField("Message", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .padding(.vertical, 8)
                        .padding(.leading, 8)

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(
                                Circle().fill(Color.accentColor.opacity(
                                    (isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 0.95
                                ))
                            )
                    }
                    .disabled(isSending || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
                )
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            .enableInjection()
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


