//
//  GameEndView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/29/24.
//

import SwiftUI

struct GameEndView: View {
    @EnvironmentObject var store: UserStore
    var score: Int
    var totalQuestions: Int
    var onRestart: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            // Header
            HStack {
                Spacer()
                
                Text("Quiz Complete!")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Result Text
            VStack(spacing: 10) {
                Text(score < 5 ? "Good effort!" : (score < 7 ? "Great job!" : "Congratulations!"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("You scored \(score) out of \(totalQuestions).")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Confetti Animation Placeholder (for potential future design)
            LottieView(animationName: score < 5 ? "1Stars" : (score < 7 ? "2Stars" : "3Stars"))
                .frame(width: 400, height: 400)
            
            Spacer()
            
            // Restart Button
            Button(action: onRestart) {
                Text("Restart Quiz")
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // End Button
            NavigationLink {
                NavigationTabView(saveAction: {})
            } label: {
                Text("Home")
                    .font(.body.bold())
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    GameEndView(score: 7, totalQuestions: 10) {
        ()
    }
    .environmentObject(UserStore())
}
