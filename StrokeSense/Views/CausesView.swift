//
//  CausesView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 11/10/24.
//
import SwiftUI

struct CausesView: View {
    let topRow = [
        ("Diabetes", "🩸"),
        ("High blood pressure", "🩺")
    ]

    let middleRow = ("Cardio vascular disease", "❤️")

    let bottomRow = [
        ("Drug usage", "💊"),
        ("Sleep apnea", "😴")
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 10) {
                    Text("Risk Factors")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Factors that make you prone to having a stroke")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 20)

                // Top row
                HStack(spacing: 20) {
                    ForEach(topRow, id: \.0) { item in
                        riskBox(icon: item.1, title: item.0, width: geo.size.width * 0.42, height: 140)
                    }
                }

                // Middle full-width
                riskBox(icon: middleRow.1, title: middleRow.0, width: geo.size.width * 0.88, height: 140)

                // Bottom row
                HStack(spacing: 20) {
                    ForEach(bottomRow, id: \.0) { item in
                        riskBox(icon: item.1, title: item.0, width: geo.size.width * 0.42, height: 140)
                    }
                }

                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color(.systemPink).opacity(0.1))
        }
    }

    func riskBox(icon: String, title: String, width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 48)) // Larger emoji
            Text(title)
                .font(.title3)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding()
        .frame(width: width, height: height)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    CausesView()
}
