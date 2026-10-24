//
//  ChatView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 2/21/25.
//
import SwiftUI
import OSLog

/// One conversation shared across the app, so suggestion chips on Today can open Ask mid-question.
@MainActor
final class ChatSession: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    /// A question asked (e.g. from the Home card) before the user agreed; sent once they do.
    @Published private(set) var pendingQuestion: String?
    /// Unsent text in Ask's input field. Shared so the Home card can show it instead of examples.
    @Published var draft = ""

    /// Apple requires explicit permission before sharing personal data with a third-party AI.
    static let consentKey = "openAIConsentGiven"
    private var hasConsent: Bool { UserDefaults.standard.bool(forKey: Self.consentKey) }

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

        If you notice signs of a stroke, **call 911 or your local emergency number right away**.
        """,
        "What are the symptoms of a stroke?": """
        Stroke symptoms appear **suddenly**. Use **BE FAST** to remember them:

        - **B**alance: sudden loss of balance or coordination
        - **E**yes: sudden vision changes in one or both eyes
        - **F**ace: one side of the face droops or feels numb
        - **A**rms: weakness or numbness in an arm or leg, often on one side
        - **S**peech: slurred speech or trouble understanding
        - **T**ime: call 911 or your local emergency number and note when symptoms started

        A sudden, severe headache with no known cause can also be a sign. Call 911 or your local emergency number even if the symptoms go away.
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

        // Nothing is answered until the user has agreed; Ask shows the agreement meanwhile.
        guard hasConsent else {
            pendingQuestion = question
            return
        }

        errorMessage = nil
        messages.append(ChatMessage(role: "user", content: question))

        if let answer = Self.cannedAnswers[question] {
            messages.append(ChatMessage(role: "assistant", content: answer))
        } else {
            requestAnswer()
        }
    }

    func acceptConsent() {
        UserDefaults.standard.set(true, forKey: Self.consentKey)
        let question = pendingQuestion
        pendingQuestion = nil
        if let question { ask(question) }
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
                Logger.app.error("Stroke Expert request failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct ChatView: View {
    @EnvironmentObject private var session: ChatSession
    @EnvironmentObject private var router: AppRouter
    @AppStorage(ChatSession.consentKey) private var hasConsent = false
    @FocusState private var inputFocused: Bool

    private let bottomID = "bottom"

    var body: some View {
        // The agreement is the first thing on Ask, not tucked away in settings: nothing can be
        // asked until the user has read it and agreed.
        if hasConsent {
            chat
        } else {
            AIConsentView()
                .navigationTitle("Stroke Expert")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var chat: some View {
        ScrollViewReader { proxy in
            ScrollView {
                conversation
            }
            // Any scroll of the conversation lowers the keyboard. `.interactively` needed a drag
            // all the way into the keyboard, which left people feeling stuck.
            .scrollDismissesKeyboard(.immediately)
            // Let short content (the empty state) scroll too, so the swipe always registers.
            .scrollBounceBehavior(.always)
            .defaultScrollAnchor(session.messages.isEmpty ? .top : .bottom)
            .onChange(of: session.messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: session.isLoading) { _, _ in scrollToBottom(proxy) }
        }
        .bottomBar {
            ChatInputBar(text: $session.draft, isFocused: $inputFocused, isLoading: session.isLoading) {
                let question = session.draft
                session.draft = ""
                session.ask(question)
            }
        }
        .onDisappear { inputFocused = false }
        .background(.surface)
        // Opened from the Home card's field: bring up the keyboard once the tab has appeared.
        .task(id: router.focusChatInput) {
            guard router.focusChatInput else { return }
            try? await Task.sleep(for: .milliseconds(350))
            inputFocused = true
            router.focusChatInput = false
        }
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

    @ViewBuilder
    private var conversation: some View {
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

            SuggestionList(questions: ChatSession.suggestions, onSelect: onSelect)
                .cardStyle()
                .padding(.top, Spacing.s)
        }
    }
}

/// Suggested questions as tappable rows separated by hairlines.
struct SuggestionList: View {
    let questions: [String]
    var horizontalPadding: CGFloat = Spacing.m
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(questions.enumerated()), id: \.element) { index, question in
                if index > 0 {
                    Rectangle()
                        .fill(.hairline)
                        .frame(height: 0.5)
                        .padding(.leading, horizontalPadding)
                }
                Button {
                    onSelect(question)
                } label: {
                    HStack(spacing: Spacing.s) {
                        Text(question)
                            .font(.body)
                            .foregroundStyle(.ink)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, Spacing.m)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Floating input field. Liquid Glass on iOS 26.
private struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSend: () -> Void
    @ScaledMetric(relativeTo: .title) private var sendSize: CGFloat = 32
    /// Space around the send button, the same on every side so it sits concentric in the bar.
    private let sendInset: CGFloat = 7

    private var canSend: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            // Return adds a line and the button sends, as in Messages. Sending from the return key
            // let the keyboard re-insert autocorrected text after the field was cleared.
            TextField("Ask about stroke", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .focused(isFocused)
                .padding(.leading, Spacing.m)
                .padding(.vertical, 12)
                // One line is exactly as tall as the button, so the button stays centered on it.
                .frame(minHeight: sendSize + 2 * sendInset)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: sendSize, height: sendSize)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, canSend ? AnyShapeStyle(.brandPrimary) : AnyShapeStyle(.inkMuted.opacity(0.4)))
            }
            .disabled(!canSend)
            .padding(sendInset)
            .accessibilityLabel("Send")
        }
        .floatingGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.xs)
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
    .environmentObject(AppRouter())
}

/// Fills the Ask tab until the user agrees. Turning sharing off in Profile brings it back.
private struct AIConsentView: View {
    @EnvironmentObject private var session: ChatSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                ExpertMark(font: .largeTitle)
                Text("Before you ask")
                    .font(.heroTitle)
                    .foregroundStyle(.ink)
                Text("The Stroke Expert answers questions about stroke in plain language, using AI.")
                    .font(.body)
                    .foregroundStyle(.inkMuted)

                VStack(alignment: .leading, spacing: Spacing.m) {
                    point("arrow.up.message.fill", "Your questions are sent to OpenAI to write the answers. OpenAI may use them to improve its models.")
                    point("exclamationmark.bubble.fill", "AI answers can be wrong. Check important information with a doctor.")
                    point("person.crop.circle.badge.xmark", "Don't include your name or personal health details.")
                    point("stethoscope", "Answers are general information, not medical advice. In an emergency, call 911 or your local emergency number.")
                }
            }
            .padding(Spacing.l)
            .padding(.top, Spacing.m)
        }
        .scrollBounceBehavior(.basedOnSize)
        .bottomBar {
            Button("Agree and Continue") { session.acceptConsent() }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.s)
        }
        .background(.surface)
    }

    private func point(_ systemImage: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            TopicSymbol(systemImage: systemImage)
            Text(text)
                .font(.body)
                .foregroundStyle(.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
