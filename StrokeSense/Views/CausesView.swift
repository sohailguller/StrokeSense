//
//  CausesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

/// Risk factors for stroke.
struct CausesView: View {
    private struct RiskFactor: Identifiable {
        let systemImage: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        var id: String { systemImage }
    }

    private let factors = [
        RiskFactor(systemImage: "gauge.with.dots.needle.67percent", title: "High blood pressure", detail: "The leading cause of stroke. Over time it damages and weakens blood vessels."),
        RiskFactor(systemImage: "drop.fill", title: "Diabetes", detail: "High blood sugar damages blood vessels and makes clots more likely."),
        RiskFactor(systemImage: "waveform.path.ecg", title: "Heart disease", detail: "Conditions such as atrial fibrillation (AFib) can cause clots that travel to the brain."),
        RiskFactor(systemImage: "lungs.fill", title: "Smoking", detail: "Damages blood vessels and raises blood pressure."),
        RiskFactor(systemImage: "bed.double.fill", title: "Sleep apnea", detail: "Repeated pauses in breathing during sleep strain the heart and blood vessels."),
        RiskFactor(systemImage: "pills.fill", title: "Drug use", detail: "Drugs such as cocaine and amphetamines can trigger a stroke, even in young people.")
    ]

    var body: some View {
        InfoTopicScreen(
            navigationTitle: "Risk Factors",
            hero: TopicHero(
                title: "Risk factors",
                summary: "Some conditions and habits make a stroke more likely. Many of them can be treated or changed.",
                systemImage: "exclamationmark.triangle.fill"
            ),
            sources: [.nhlbiCauses]
        ) {
            CardList(items: factors) { factor in
                TopicItemRow(systemImage: factor.systemImage, title: factor.title, detail: factor.detail)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CausesView()
    }
}
