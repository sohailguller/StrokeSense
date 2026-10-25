//
//  EducationView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//

import SwiftUI

/// The Learn tab: education topics, podcast episodes and the quiz.
struct EducationView: View {
    @StateObject private var videoVM = VideoViewModel()
    @State private var showQuiz = false

    var body: some View {
        List {
            Section {
                topicLink(.befast, title: "B.E. F.A.S.T.", subtitle: "Recognize a stroke and act fast", systemImage: "bolt.heart.fill", tint: .emergency)
            } header: {
                Text("Recognize")
            }

            Section {
                topicLink(.types, title: "Types of Stroke", subtitle: "Ischemic, hemorrhagic and TIA", systemImage: "brain.head.profile.fill")
                topicLink(.riskFactors, title: "Risk Factors", subtitle: "What raises your chance of stroke", systemImage: "exclamationmark.triangle.fill")
                topicLink(.prevention, title: "Prevention", subtitle: "Eight habits that lower your risk", systemImage: "shield.lefthalf.filled")
                topicLink(.treatments, title: "Treatments", subtitle: "How doctors treat a stroke", systemImage: "cross.case.fill")
            } header: {
                Text("Understand")
            }

            Section {
                NavigationLink {
                    InterviewsView(viewModel: videoVM)
                } label: {
                    LearnRow(title: "Podcast Episodes", subtitle: "Conversations about stroke", systemImage: "headphones")
                }
            } header: {
                Text("Listen")
            }

            Section {
                Button {
                    showQuiz = true
                } label: {
                    LearnRow(title: "Quiz", subtitle: "10 questions · about 3 minutes", systemImage: "checkmark.seal.fill")
                }
                .tint(.ink)
            } header: {
                Text("Practice")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.surface)
        .localizedNavigationTitle("Learn")
        .navigationDestination(for: LearnTopic.self) { $0.destination }
        .fullScreenCover(isPresented: $showQuiz) { GameView() }
        .onAppear { videoVM.fetchVideos() }
    }

    private func topicLink(_ topic: LearnTopic, title: LocalizedStringKey, subtitle: LocalizedStringKey, systemImage: String, tint: Color = .accentColor) -> some View {
        NavigationLink(value: topic) {
            LearnRow(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
        }
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
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    var tint: Color = .accentColor
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 56

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
            // Pin dividers to the text so every row lines up, whatever the symbol's width.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
        // Whole-point row heights; fractional ones leave a hairline seam between rows.
        .frame(minHeight: minHeight.rounded(), alignment: .leading)
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    NavigationStack {
        EducationView()
    }
}
