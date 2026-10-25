//
//  GameView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//
import SwiftUI

/// Ten-question quiz, presented full screen.
struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quiz = Quiz()
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var answers: [AnsweredQuestion] = []
    @State private var showReview = false

    private var isFinished: Bool { currentIndex >= quiz.questions.count }
    private var score: Int { answers.filter(\.isCorrect).count }

    var body: some View {
        NavigationStack {
            Group {
                if isFinished {
                    results
                } else {
                    questionView(quiz.questions[currentIndex])
                }
            }
            .background(.surface)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                if !isFinished {
                    ToolbarItem(placement: .principal) {
                        Text("\(currentIndex + 1) of \(quiz.questions.count)")
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                            .foregroundStyle(.inkMuted)
                            .contentTransition(.numericText())
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showReview) { QuizReview(answers: answers) }
        }
    }

    // MARK: Question

    private func questionView(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            ProgressView(value: Double(currentIndex), total: Double(quiz.questions.count))
                .tint(.brandPrimary)
                .accessibilityLabel("Question \(currentIndex + 1) of \(quiz.questions.count)")

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Text(question.question)
                        .font(.cardTitle)
                        .foregroundStyle(.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.s)

                    VStack(spacing: Spacing.s) {
                        ForEach(question.choices, id: \.self) { choice in
                            AnswerOption(
                                text: choice,
                                state: optionState(choice, question: question)
                            ) {
                                guard selectedAnswer == nil else { return }
                                withAnimation(.snappy) { selectedAnswer = choice }
                            }
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(currentIndex == quiz.questions.count - 1 ? "See Results" : "Next") {
                advance(question)
            }
            .buttonStyle(.primary)
            .disabled(selectedAnswer == nil)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.m)
        .sensoryFeedback(trigger: selectedAnswer) { _, newValue in
            guard let newValue else { return nil }
            return newValue == question.correctAnswer ? .success : .error
        }
    }

    private func optionState(_ choice: String, question: Question) -> AnswerOption.State {
        guard let selectedAnswer else { return .idle }
        if choice == question.correctAnswer { return .correct }
        if choice == selectedAnswer { return .incorrect }
        return .dimmed
    }

    private func advance(_ question: Question) {
        guard let selectedAnswer else { return }
        answers.append(AnsweredQuestion(question: question, answer: selectedAnswer))
        withAnimation(.snappy) {
            self.selectedAnswer = nil
            currentIndex += 1
        }
    }

    // MARK: Results

    private var results: some View {
        let total = quiz.questions.count
        return VStack(spacing: Spacing.l) {
            Spacer()
            ScoreRing(score: score, total: total)
            VStack(spacing: Spacing.xs) {
                Text(resultTitle(total: total))
                    .font(.heroTitle)
                    .foregroundStyle(.ink)
                Text("You answered \(score) of \(total) questions correctly.")
                    .font(.body)
                    .foregroundStyle(.inkMuted)
            }
            .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: Spacing.s) {
                Button("Review Answers") { showReview = true }
                    .buttonStyle(.primary)
                Button("Try a New Quiz", action: restart)
                    .buttonStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.m)
    }

    private func resultTitle(total: Int) -> LocalizedStringKey {
        switch Double(score) / Double(max(total, 1)) {
        case 0.9...: return "Excellent"
        case 0.7..<0.9: return "Well done"
        case 0.5..<0.7: return "Good start"
        default: return "Keep learning"
        }
    }

    private func restart() {
        withAnimation(.snappy) {
            quiz.questions = Quiz.randomQuestions()
            answers = []
            selectedAnswer = nil
            currentIndex = 0
        }
    }
}

struct AnsweredQuestion: Identifiable {
    let id = UUID()
    let question: Question
    let answer: String
    var isCorrect: Bool { answer == question.correctAnswer }
}

private struct AnswerOption: View {
    enum State { case idle, correct, incorrect, dimmed }

    let text: String
    let state: State
    let action: () -> Void

    private var borderColor: Color {
        switch state {
        case .correct: .success
        case .incorrect: .emergency
        default: .hairline
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Spacing.xs)
                switch state {
                case .correct:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.success)
                case .incorrect:
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.emergency)
                default:
                    EmptyView()
                }
            }
            .font(.title3)
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .fill(.card)
                    .strokeBorder(borderColor, lineWidth: state == .idle || state == .dimmed ? 0.5 : 2)
            }
            .opacity(state == .dimmed ? 0.5 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(state == .correct ? "Correct answer" : state == .incorrect ? "Incorrect" : "")
    }
}

private struct ScoreRing: View {
    let score: Int
    let total: Int
    @State private var progress: Double = 0
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 168

    var body: some View {
        ZStack {
            Circle()
                .stroke(.hairline, lineWidth: 12)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.brandPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.statNumber)
                    .foregroundStyle(.ink)
                Text("of \(total)")
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.rounded)
                    .foregroundStyle(.inkMuted)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                progress = Double(score) / Double(max(total, 1))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Score: \(score) of \(total)")
    }
}

private struct QuizReview: View {
    let answers: [AnsweredQuestion]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(answers) { item in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.question.question)
                        .font(.headline)
                        .foregroundStyle(.ink)
                    Label(item.answer, systemImage: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(item.isCorrect ? .success : .emergency)
                    if !item.isCorrect {
                        Label(item.question.correctAnswer, systemImage: "checkmark.circle")
                            .foregroundStyle(.success)
                    }
                }
                .font(.subheadline)
                .padding(.vertical, Spacing.xxs)
                .accessibilityElement(children: .combine)
            }
            .scrollContentBackground(.hidden)
            .background(.surface)
            .localizedNavigationTitle("Your Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    GameView()
}
