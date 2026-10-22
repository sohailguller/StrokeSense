//
//  EducationView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//

import SwiftUI

/// The Learn tab: education topics, videos and the quiz.
struct EducationView: View {
    @StateObject private var videoVM = VideoViewModel()
    @Namespace private var transition
    @State private var showQuiz = false

    var body: some View {
        List {
            Section {
                topicLink(.befast, title: "B.E. F.A.S.T.", subtitle: "Recognize a stroke and act fast", systemImage: "bolt.heart.fill", tint: .emergency)
            } header: {
                Text("Recognize")
            }

            Section {
                topicLink(.types, title: "Types of stroke", subtitle: "Ischemic, hemorrhagic and TIA", systemImage: "brain.head.profile.fill")
                topicLink(.riskFactors, title: "Risk factors", subtitle: "What raises your chance of stroke", systemImage: "exclamationmark.triangle.fill")
                topicLink(.prevention, title: "Prevention", subtitle: "Eight habits that lower your risk", systemImage: "shield.lefthalf.filled")
                topicLink(.treatments, title: "Treatments", subtitle: "How doctors treat a stroke", systemImage: "cross.case.fill")
            } header: {
                Text("Understand")
            }

            Section {
                NavigationLink {
                    InterviewsView(viewModel: videoVM)
                } label: {
                    LearnRow(title: "Videos", subtitle: "Stories and explainers", systemImage: "play.rectangle.fill")
                }
                Button {
                    showQuiz = true
                } label: {
                    LearnRow(title: "Quiz", subtitle: "10 questions · about 3 minutes", systemImage: "checkmark.seal.fill")
                }
                .tint(.ink)
            } header: {
                Text("Practice")
            } footer: {
                Text("General information based on the sources listed in each topic. It is not medical advice. Talk to a doctor about your health.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.surface)
        .navigationTitle("Learn")
        .navigationDestination(for: LearnTopic.self) { topic in
            topic.destination
                .navigationTransition(.zoom(sourceID: topic, in: transition))
        }
        .fullScreenCover(isPresented: $showQuiz) { GameView() }
        .onAppear { videoVM.fetchVideos() }
    }

    private func topicLink(_ topic: LearnTopic, title: String, subtitle: String, systemImage: String, tint: Color = .accentColor) -> some View {
        NavigationLink(value: topic) {
            LearnRow(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
        }
        .matchedTransitionSource(id: topic, in: transition)
    }
}

enum LearnTopic: Hashable {
    case befast, types, riskFactors, prevention, treatments

    @ViewBuilder
    var destination: some View {
        switch self {
        case .befast: BefastView()
        case .types: TypesView()
        case .riskFactors: CausesView()
        case .prevention: PreventionView()
        case .treatments: TreatmentsView()
        }
    }
}

private struct LearnRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: Spacing.m) {
            TopicSymbol(systemImage: systemImage, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    NavigationStack {
        EducationView()
    }
}
