//
//  BefastView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct BefastView: View {
    let symptoms = [
        ("Balance", "Loss of balance or dizziness", "🧍‍♂️"),
        ("Eyes", "Vision changes", "👀"),
        ("Face", "Facial drooping, severe headache", "😊"),
        ("Arms", "Weakness, numbness", "💪"),
        ("Speech", "Slurred speech, trouble speaking, confusion", "🗣️"),
        ("Time", "To call 911", "⏰")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("B.E.F.A.S.T")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.pink)
                    Text("WHEN IT COMES TO STROKE")
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(symptoms, id: \.0) { item in
                        VStack(spacing: 10) {
                            Text(item.2)
                                .font(.largeTitle)
                            Text(item.0)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(item.1)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 10) {
                    Text("STROKE. REACT. DON'T REGRET.")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("Call 911")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
            .padding()
        }
        .background(Color(.systemTeal).opacity(0.05))
    }
}

#Preview {
    BefastView()
}
