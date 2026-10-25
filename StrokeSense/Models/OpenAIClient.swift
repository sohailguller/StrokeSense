//
//  OpenAIClient.swift
//  AIChatBot
//
//  Created by Sohail Guller on 2/21/25.
//
import Foundation
import OSLog
import FirebaseAppCheck

struct Message: Codable {
    let role: String
    let content: String
}

private struct ChatRequest: Encodable {
    let messages: [Message]
    /// The app's language, so the Stroke Expert answers in it.
    let language: String
}

private struct ChatResponse: Decodable {
    let reply: String?
    let error: String?
}

enum OpenAIClientError: LocalizedError {
    case busy
    case unavailable
    case emptyResponse

    // Written here rather than taken from the server, so they're in the app's language.
    var errorDescription: String? {
        switch self {
        case .busy:
            String(localized: "The Stroke Expert is busy right now. Please try again later.")
        case .unavailable:
            String(localized: "The Stroke Expert couldn't answer right now. Please try again.")
        case .emptyResponse:
            String(localized: "The Stroke Expert returned an empty response.")
        }
    }
}

/// Sends chat messages to the StrokeSense Cloudflare Worker (worker/src/index.js), which holds
/// the OpenAI API key and system prompt server-side and only accepts App Check–verified requests.
class OpenAIClient {
    private let endpoint = URL(string: "https://strokesense-chat.ims03g.workers.dev")!

    func sendMessage(messages: [Message]) async throws -> Message {
        let appCheckToken = try await AppCheck.appCheck().token(forcingRefresh: false).token

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        request.httpBody = try JSONEncoder().encode(ChatRequest(messages: messages, language: AppLanguage.current.rawValue))

        let (data, response) = try await URLSession.shared.data(for: request)
        let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data)

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            Logger.app.error("Chat server error \(httpResponse.statusCode): \(decoded?.error ?? "no message")")
            throw httpResponse.statusCode == 429 ? OpenAIClientError.busy : OpenAIClientError.unavailable
        }

        guard let reply = decoded?.reply, !reply.isEmpty else {
            throw OpenAIClientError.emptyResponse
        }
        return Message(role: "assistant", content: reply)
    }
}
