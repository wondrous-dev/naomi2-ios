//
//  MessageView.swift
//  naomi-ios
//
//  Created by Assistant on 9/19/25.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    @EnvironmentObject var app: AppModel

    var body: some View {
        let isUser = message.isUser
        return HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 8) {
                Text(message.text ?? "")
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)

                if let list = message.habitSuggestion, !list.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(list.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 6)
                                Text(item)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isUser ? Color.accentColor.opacity(0.35) : Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, y: 2)

            // Status indicators for user messages
            if isUser {
                switch message.status {
                case .pending:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 16, height: 16)
                        .padding(.leading, 6)
                case .failed:
                    Button(action: { Task { await app.retrySend(messageId: message.id) } }) {
                        Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 6)
                default:
                    EmptyView()
                }
            }

            if !isUser { Spacer(minLength: 40) }
        }
        .transition(.opacity.combined(with: .move(edge: isUser ? .trailing : .leading)))
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            MessageView(message: ChatMessage(source: .companion, text: "Hello! How can I help today?", userId: nil, companionId: "c1", status: .sent))
            MessageView(message: ChatMessage(source: .user, text: "Sending...", userId: "u1", companionId: "c1", status: .pending))
            MessageView(message: ChatMessage(source: .user, text: "Failed to send", userId: "u1", companionId: "c1", status: .failed))
        }
        .padding()
        .background(
            Image("NaomiBackground").resizable().scaledToFill()
        )
        .environmentObject(AppModel.preview)
    }
}


