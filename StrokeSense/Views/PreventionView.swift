//
//  PreventionView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct PreventionView: View {
    private struct Tip: Identifiable {
        let systemImage: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        var id: String { systemImage }
    }

    private let tips = [
        Tip(systemImage: "gauge.with.dots.needle.33percent", title: "Control blood pressure", detail: "Check it regularly and take medicine as prescribed."),
        Tip(systemImage: "drop.fill", title: "Manage blood sugar", detail: "Keep diabetes under control with your care team."),
        Tip(systemImage: "heart.text.square.fill", title: "Manage cholesterol", detail: "Ask your doctor how often to get it checked."),
        Tip(systemImage: "nosign", title: "Quit smoking and tobacco", detail: "Your risk starts dropping soon after you quit."),
        Tip(systemImage: "figure.walk", title: "Stay active", detail: "Aim for about 30 minutes of moderate activity most days."),
        Tip(systemImage: "fork.knife", title: "Eat a heart-healthy diet", detail: "More vegetables, fruit and whole grains; less salt and processed food."),
        Tip(systemImage: "scalemass.fill", title: "Keep a healthy weight", detail: "Even modest weight loss can lower blood pressure."),
        Tip(systemImage: "moon.zzz.fill", title: "Sleep well", detail: "Aim for 7 to 9 hours, and get checked if you snore heavily.")
    ]

    var body: some View {
        InfoTopicScreen(
            navigationTitle: "Prevention",
            hero: TopicHero(
                title: "Lower your risk",
                summary: "Most strokes are linked to risk factors you can manage. These habits help at any age.",
                systemImage: "shield.lefthalf.filled"
            ),
            sources: [.nhlbiCauses, .nhlbiOverview]
        ) {
            CardList(items: tips) { tip in
                TopicItemRow(systemImage: tip.systemImage, title: tip.title, detail: tip.detail)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PreventionView()
    }
}
