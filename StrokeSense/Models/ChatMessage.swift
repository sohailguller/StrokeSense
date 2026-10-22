//
//  ChatMessage.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/23/25.
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}
