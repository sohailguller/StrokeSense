//
//  TreatmentsView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 6/30/25.
//
import SwiftUI

struct TreatmentsView: View {
    private let treatments = [
        TopicDetail(
            systemImage: "syringe.fill",
            title: "Clot-dissolving medicine",
            summary: "Medicine given through an IV to break up a clot.",
            body: "For ischemic stroke, a clot-dissolving medicine such as tPA can restore blood flow to the brain.",
            points: [
                "Works best when started within 3 to 4.5 hours of the first symptoms.",
                "Can improve recovery and reduce disability.",
                "Not used when there is a high risk of bleeding, such as after recent surgery."
            ],
            source: .nhlbiTreatment
        ),
        TopicDetail(
            systemImage: "arrow.down.to.line.compact",
            title: "Mechanical thrombectomy",
            summary: "A catheter procedure to remove a large clot.",
            body: "A thin tube is guided through an artery to the brain, where doctors remove the clot directly.",
            points: [
                "Can be done up to 24 hours after symptoms start for some patients.",
                "Often used together with clot-dissolving medicine for strokes in large arteries.",
                "Restores blood flow quickly to limit brain damage."
            ],
            source: .nhlbiTreatment
        ),
        TopicDetail(
            systemImage: "cross.case.fill",
            title: "Surgery for bleeding",
            summary: "Procedures to stop bleeding and relieve pressure.",
            body: "In a hemorrhagic stroke, surgery may be needed to stop the bleeding and lower pressure on the brain.",
            points: [
                "An aneurysm can be clipped or coiled to seal the bleeding vessel.",
                "A craniotomy can remove pooled blood and relieve pressure.",
                "Quick treatment helps prevent further brain injury."
            ],
            source: .nhlbiTreatment
        ),
        TopicDetail(
            systemImage: "figure.walk.motion",
            title: "Rehabilitation",
            summary: "Therapy to regain skills after a stroke.",
            body: "Recovery often continues for months. Rehabilitation helps people relearn movement, speech and everyday tasks.",
            points: [
                "May include physical, occupational and speech therapy.",
                "Starting early, while still in the hospital, tends to help.",
                "Family and caregivers are an important part of recovery."
            ],
            source: .nhlbiRecovery
        )
    ]

    @State private var selected: TopicDetail?

    var body: some View {
        InfoTopicScreen(
            navigationTitle: "Treatments",
            hero: TopicHero(
                title: "Treatments",
                summary: "Treatment depends on the type of stroke and how quickly it begins. The sooner, the better.",
                systemImage: "cross.case.fill"
            ),
            sources: [.nhlbiTreatment, .nhlbiRecovery]
        ) {
            TopicDetailList(details: treatments, selected: $selected)
        }
        .sheet(item: $selected) { TopicDetailSheet(detail: $0) }
    }
}

#Preview {
    NavigationStack {
        TreatmentsView()
    }
}
