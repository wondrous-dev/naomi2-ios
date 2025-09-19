//
//  MessageView.swift
//  naomi-ios
//
//  Created by Assistant on 9/19/25.
//

import SwiftUI

struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        let isUser = message.isUser
        return HStack(alignment: .bottom) {
            if isUser { Spacer(minLength: 40) }

            Text(message.text ?? "")
                .font(.system(size: 16))
                .foregroundStyle(.primary)
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

            if !isUser { Spacer(minLength: 40) }
        }
        .transition(.opacity.combined(with: .move(edge: isUser ? .trailing : .leading)))
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            MessageView(message: ChatMessage(source: .companion, text: "Hello! How can I help today?", userId: nil, companionId: "c1"))
            MessageView(message: ChatMessage(source: .user, text: "What's the weather like?", userId: "u1", companionId: "c1"))
        }
        .padding()
        .background(
            Image("NaomiBackground").resizable().scaledToFill()
        )
    }
}


