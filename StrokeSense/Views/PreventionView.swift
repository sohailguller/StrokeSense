//
//  PreventionView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct PreventionView: View {
    let tips = [
        ("Eat healthy food", "🥗"),
        ("Sleep", "🧘‍♀️"),
        ("Exercise regularly", "🏋️‍♂️👟"),
        ("Control blood pressure", "🩺"),
        ("Quit smoking and tobacco", "🚭"),
        ("Maintain healthy weight", "⚖️"),
        ("Control Cholesterol", "🧬"),
        ("Manage Blood Sugar", "🩸")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 5) {
                    Text("Reduce Your Risk")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("8 tips for prevention for all ages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(tips, id: \.0) { tip in
                        VStack(spacing: 10) {
                            Text(tip.1)
                                .font(.largeTitle)
                            Text(tip.0)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                }
                .padding()
            }
            .padding()
            
        }
        .background(Color(.systemPink).opacity(0.1))
    }
}

#Preview {
    PreventionView()
}
