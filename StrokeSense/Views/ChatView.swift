//
//  ChatView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/21/25.
//
import SwiftUI

/// One conversation shared across the app, so suggestion chips on Today can open Ask mid-question.
@MainActor
final class ChatSession: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // The system prompt lives in the chat Worker (worker/src/index.js).
    private let client = OpenAIClient()

    static let suggestions = [
        "What is a stroke?",
        "What are the symptoms of a stroke?",
        "How can I prevent a stroke?"
    ]

    /// Instant answers for the suggested questions, so they work offline.
    private static let cannedAnswers: [String: String] = [
        "What is a stroke?": """
        A **stroke** is a medical emergency that happens when blood flow to part of the brain is blocked, or when a blood vessel in the brain bursts. Brain cells stop receiving oxygen and nutrients and begin to die within minutes.

        There are two main types:
        1. **Ischemic stroke**: a blockage, such as a blood clot, in an artery supplying the brain.
        2. **Hemorrhagic stroke**: a blood vessel in the brain bursts and bleeds.

        A **transient ischemic attack (TIA)**, sometimes called a mini-stroke, is a temporary blockage. Its symptoms go away, but it is a warning sign of a future stroke and needs urgent care.

        If you notice signs of a stroke, **call an ambulance right away**.
        """,
        "What are the symptoms of a stroke?": """
        Stroke symptoms appear **suddenly**. Use **BE FAST** to remember them:

        - **B**alance: sudden loss of balance or coordination
        - **E**yes: sudden vision changes in one or both eyes
        - **F**ace: one side of the face droops or feels numb
        - **A**rms: weakness or numbness in an arm or leg, often on one side
        - **S**peech: slurred speech or trouble understanding
        - **T**ime: call an ambulance and note when symptoms started

        A sudden, severe headache with no known cause can also be a sign. Call an ambulance even if the symptoms go away.
        """,
        "How can I prevent a stroke?": """
        Many strokes can be prevented by managing risk factors:

        1. **Control blood pressure**, the leading treatable cause of stroke.
        2. **Manage diabetes** and blood sugar.
        3. **Quit smoking** and avoid tobacco.
        4. **Stay active**: aim for about 30 minutes of moderate activity most days.
        5. **Eat a heart-healthy diet** with less salt and fewer processed foods.
        6. **Keep a healthy weight.**
        7. **Limit alcohol.**
        8. **Manage cholesterol.**
        9. **Get atrial fibrillation (AFib) treated** if you have it.

        Your doctor can help you understand your own risk and whether medication would help.
        """
    ]

    func ask(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isLoading else { return }

        errorMessage = nil
        messages.append(ChatMessage(role: "user", content: question))

        if let answer = Self.cannedAnswers[question] {
            messages.append(ChatMessage(role: "assistant", content: answer))
        } else {
            requestAnswer()
        }
    }

    func retry() {
        guard messages.last?.role == "user", !isLoading else { return }
        errorMessage = nil
        requestAnswer()
    }

    func startOver() {
        guard !isLoading else { return }
        messages.removeAll()
        errorMessage = nil
    }

    private func requestAnswer() {
        let history = messages.map { Message(role: $0.role, content: $0.content) }
        isLoading = true

        Task {
            do {
                let reply = try await client.sendMessage(messages: history)
                messages.append(ChatMessage(role: "assistant", content: reply.content))
            } catch {
                print("Error: \(error)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct ChatView: View {
    @EnvironmentObject private var session: ChatSession
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    private let bottomID = "bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if session.messages.isEmpty {
                    ChatIntro { session.ask($0) }
                        .padding(.horizontal, Spacing.l)
                        .padding(.top, Spacing.xl)
                } else {
                    LazyVStack(alignment: .leading, spacing: Spacing.l) {
                        ForEach(session.messages) { message in
                            ChatRow(message: message)
                        }
                        if session.isLoading {
                            TypingIndicatorRow()
                        }
                        if let error = session.errorMessage {
                            ChatErrorRow(message: error) { session.retry() }
                        }
                        Color.clear.frame(height: 1).id(bottomID)
                    }
                    .padding(.horizontal, Spacing.l)
                    .padding(.vertical, Spacing.m)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(session.messages.isEmpty ? .top : .bottom)
            .onChange(of: session.messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: session.isLoading) { _, _ in scrollToBottom(proxy) }
        }
        .safeAreaInset(edge: .bottom) {
            ChatInputBar(text: $inputText, isFocused: $inputFocused, isLoading: session.isLoading) {
                session.ask(inputText)
                inputText = ""
            }
        }
        .background(.surface)
        .navigationTitle("Stroke Expert")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !session.messages.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Conversation", systemImage: "square.and.pencil") {
                        session.startOver()
                    }
                    .disabled(session.isLoading)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: session.messages.filter { $0.role == "user" }.count)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.snappy) {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
}

/// Empty state with suggested questions.
private struct ChatIntro: View {
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.largeTitle.weight(.semibold))
                .imageScale(.large)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Ask anything about stroke")
                .font(.heroTitle)
                .foregroundStyle(.ink)
            Text("Plain-language answers about symptoms, risk factors, treatment and recovery.")
                .font(.body)
                .foregroundStyle(.inkMuted)

            VStack(spacing: 0) {
                ForEach(Array(ChatSession.suggestions.enumerated()), id: \.element) { index, question in
                    Button {
                        onSelect(question)
                    } label: {
                        HStack {
                            Text(question)
                                .font(.body)
                                .foregroundStyle(.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                        .padding(Spacing.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < ChatSession.suggestions.count - 1 {
                        Rectangle().fill(.hairline).frame(height: 0.5).padding(.leading, Spacing.m)
                    }
                }
            }
            .cardStyle()
            .padding(.top, Spacing.s)
        }
    }
}

/// Floating input field. Liquid Glass on iOS 26.
private struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSend: () -> Void

    private var canSend: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                TextField("Ask about stroke", text: $text, axis: .vertical)
                    .lineLimit(1...5)
                    .focused(isFocused)
                    .submitLabel(.send)
                    .onSubmit { if canSend { onSend() } }
                    .padding(.leading, Spacing.m)
                    .padding(.vertical, 12)

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, canSend ? AnyShapeStyle(.brandPrimary) : AnyShapeStyle(.inkMuted.opacity(0.4)))
                }
                .disabled(!canSend)
                .padding(5)
                .accessibilityLabel("Send")
            }
            .floatingGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("AI answers can be wrong and aren't medical advice. Questions are processed by OpenAI and may be used to improve their models.")
                .font(.caption2)
                .foregroundStyle(.inkMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.xs)
    }
}

private struct TypingIndicatorRow: View {
    var body: some View {
        HStack(spacing: Spacing.s) {
            ExpertMark()
            Image(systemName: "ellipsis")
                .font(.title2.weight(.bold))
                .foregroundStyle(.inkMuted)
                .symbolEffect(.variableColor.iterative.dimInactiveLayers, options: .repeating)
        }
        .accessibilityElement()
        .accessibilityLabel("The Stroke Expert is answering")
    }
}

private struct ChatErrorRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.emergency)
                .font(.title3)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Couldn't get an answer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.inkMuted)
                Button("Try Again", action: onRetry)
                    .font(.subheadline.weight(.semibold))
                    .tint(.accentColor)
            }
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(radius: Radius.control)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
    .environmentObject(ChatSession())
}
