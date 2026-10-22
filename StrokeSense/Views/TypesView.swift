//
//  TypesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct TypesView: View {
    private let types = [
        TopicDetail(
            systemImage: "drop.halffull",
            title: "Ischemic stroke",
            summary: "The most common type, about 87% of strokes.",
            body: "An ischemic stroke happens when a blood clot or narrowed artery blocks blood flow to part of the brain.",
            points: [
                "Clot-dissolving medicine works best when given within a few hours of the first symptoms.",
                "Doctors may also remove large clots with a catheter (thrombectomy).",
                "Every minute counts, so call 911 right away."
            ],
            source: .nhlbiOverview
        ),
        TopicDetail(
            systemImage: "brain.head.profile.fill",
            title: "Hemorrhagic stroke",
            summary: "Less common, about 13% of strokes, but often more severe.",
            body: "A hemorrhagic stroke happens when a weakened blood vessel breaks and bleeds into or around the brain, raising pressure and damaging tissue.",
            points: [
                "High blood pressure is a common cause.",
                "Treatment may include lowering blood pressure and surgery to stop the bleeding or relieve pressure.",
                "Aneurysms can be clipped or coiled to seal the vessel."
            ],
            source: .nhlbiOverview
        ),
        TopicDetail(
            systemImage: "clock.badge.exclamationmark.fill",
            title: "Transient ischemic attack",
            summary: "A \"mini-stroke\" with symptoms that go away.",
            body: "A TIA is a brief blockage of blood flow to the brain. Its symptoms are the same as a stroke but usually last only minutes.",
            points: [
                "A TIA is a warning sign that a stroke may follow.",
                "It needs emergency care, even if the symptoms are gone.",
                "Treating the cause can prevent a future stroke."
            ],
            source: .nhlbiOverview
        )
    ]

    @State private var selected: TopicDetail?

    var body: some View {
        InfoTopicScreen(
            navigationTitle: "Types of Stroke",
            hero: TopicHero(
                eyebrow: "Understand",
                title: "Types of stroke",
                summary: "Strokes are caused either by a blockage or by bleeding. A TIA is a temporary warning.",
                systemImage: "brain.head.profile.fill"
            ),
            sources: [.nhlbiOverview]
        ) {
            TopicDetailList(details: types, selected: $selected)
        }
        .sheet(item: $selected) { TopicDetailSheet(detail: $0, eyebrow: "Type of stroke") }
    }
}

/// Tappable rows that open a detail sheet. Shared by Types and Treatments.
struct TopicDetailList: View {
    let details: [TopicDetail]
    @Binding var selected: TopicDetail?

    var body: some View {
        CardList(items: details) { detail in
            Button {
                selected = detail
            } label: {
                HStack {
                    TopicItemRow(systemImage: detail.systemImage, title: detail.title, detail: detail.summary)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.inkMuted)
                        .padding(.trailing, Spacing.m)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    NavigationStack {
        TypesView()
    }
}
