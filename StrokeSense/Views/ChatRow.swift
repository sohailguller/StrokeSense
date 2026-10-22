//
//  ChatRow.swift
//  AIChatBot
//
//  Created by Sohail Guller on 2/21/25.
//

import SwiftUI
import MarkdownUI

struct ChatRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == "assistant" || message.role == "system" {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                    .padding(.top, 4)
   
                Markdown(message.content)
                    .padding(12)
                    .background(Color(white: 0.95))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Spacer()
            } else {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    ChatRow(message: ChatMessage(role: "user", content: "What is a stroke"))
}
