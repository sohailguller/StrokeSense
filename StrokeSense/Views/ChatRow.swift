//
//  ChatRow.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/21/25.
//

import SwiftUI
import MarkdownUI

struct ChatRow: View {
    let message: ChatMessage

    var body: some View {
        if message.role == "user" {
            HStack {
                Spacer(minLength: 56)
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.brandPrimary, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .textSelection(.enabled)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You: \(message.content)")
        } else {
            HStack(alignment: .top, spacing: Spacing.s) {
                ExpertMark()
                    .padding(.top, 2)
                Markdown(message.content)
                    .markdownTextStyle(\.text) {
                        FontFamily(.system(.rounded))
                        ForegroundColor(.ink)
                    }
                    .markdownTextStyle(\.strong) {
                        FontWeight(.semibold)
                    }
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatRow(message: ChatMessage(role: "user", content: "What is a stroke?"))
        ChatRow(message: ChatMessage(role: "assistant", content: "A **stroke** happens when blood flow to the brain is blocked."))
    }
    .padding()
}
