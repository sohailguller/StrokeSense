//
//  BefastView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct BefastView: View {
    private struct Sign: Identifiable {
        let letter: String
        let title: String
        let detail: String
        var id: String { letter }
    }

    private let signs = [
        Sign(letter: "B", title: "Balance", detail: "Sudden loss of balance or coordination, or dizziness."),
        Sign(letter: "E", title: "Eyes", detail: "Sudden vision changes or loss of vision in one or both eyes."),
        Sign(letter: "F", title: "Face", detail: "One side of the face droops or feels numb. Ask the person to smile."),
        Sign(letter: "A", title: "Arms", detail: "Weakness or numbness in an arm or leg, often on one side. Ask them to raise both arms."),
        Sign(letter: "S", title: "Speech", detail: "Slurred speech, trouble speaking, or confusion."),
        Sign(letter: "T", title: "Time", detail: "Call 911 right away, even if the symptoms go away. Note the time they started.")
    ]

    @ScaledMetric(relativeTo: .largeTitle) private var letterWidth: CGFloat = 52

    var body: some View {
        InfoTopicScreen(
            navigationTitle: "B.E. F.A.S.T.",
            hero: TopicHero(
                eyebrow: "Recognize a stroke",
                title: "B.E. F.A.S.T.",
                summary: "Stroke symptoms come on suddenly. If you notice any one of these signs, call an ambulance immediately. Fast treatment can save brain function.",
                systemImage: "bolt.heart.fill",
                tint: .emergency
            ),
            sources: [.nhlbiSymptoms]
        ) {
            CardList(items: signs, dividerInset: letterWidth + Spacing.m * 2) { sign in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                    Text(sign.letter)
                        .font(.letterMark)
                        .foregroundStyle(.emergency)
                        .frame(width: letterWidth, alignment: .center)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(sign.title)
                            .font(.headline)
                            .foregroundStyle(.ink)
                        Text(sign.detail)
                            .font(.subheadline)
                            .foregroundStyle(.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Spacing.m)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BefastView()
    }
}
