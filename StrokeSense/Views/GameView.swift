//
//  GameView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//
import SwiftUI

struct GameView: View {
    @EnvironmentObject var store: UserStore
    @EnvironmentObject var favoritesManager: FavoritesManager
    @StateObject var quiz = Quiz()
    @State private var currentQuestionIndex = 0
    @State private var isNavigating = false
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var isAnswerCorrect: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if currentQuestionIndex < quiz.questions.count-1 {
                HStack {
                    NavigationLink {
                        NavigationTabView(saveAction: {})
                            .environmentObject(store)
                            .environmentObject(favoritesManager)
                            .navigationBarBackButtonHidden()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Stroke Quiz")
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.black)
                            .hidden()
                        Text("2:00")
                            .font(.subheadline)
                            .hidden()
                    }
                }
                .padding(.horizontal)
                
                Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Text(quiz.questions[currentQuestionIndex].question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                ForEach(quiz.questions[currentQuestionIndex].choices, id: \.self) { choice in
                    Button(action: {
                        selectedAnswer = choice
                        isAnswerCorrect = (choice == quiz.questions[currentQuestionIndex].correctAnswer)
                    }) {
                        HStack {
                            Text(choice)
                                .font(.body)
                                .padding()
                            Spacer()
                            
                            if selectedAnswer == choice {
                                Image(systemName: isAnswerCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isAnswerCorrect == true ? .green : .red)
                            }
                        }
                        .foregroundColor(selectedAnswer == choice ? .black : .gray)
                        .padding()
                        .background(selectedAnswer == choice ? (isAnswerCorrect == true ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                if let selectedAnswer = selectedAnswer, !isAnswerCorrect! {
                    Text("Correct Answer: \(quiz.questions[currentQuestionIndex].correctAnswer)")
                        .font(.body)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: {
                    handleNextQuestion()
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(selectedAnswer == nil)
            } else {
                VStack(alignment: .center, spacing: 15) {
                    HStack {
                        Spacer()
                        
                        Text("Quiz Complete!")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text(score < 5 ? "Good effort!" : (score < 7 ? "Great job!" : "Congratulations!"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text("You scored \(score) out of \(10).")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    LottieView(animationName: score < 5 ? "1Stars" : (score < 7 ? "2Stars" : "3Stars"))
                        
                        .frame(width: 400, height: 400)
                    
                    Spacer()
                    
                    Button(action: restartQuiz) {
                        Text("Restart Quiz")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    NavigationLink {
                        NavigationTabView{
                            Task {
                                do {
                                    try await store.save(user: store.user)
                                } catch {
                                    fatalError(error.localizedDescription)
                                }
                            }
                        }
                        .environmentObject(store)
                        .environmentObject(favoritesManager)
                        .navigationBarBackButtonHidden()
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
        .padding()
    }
    
    private func handleNextQuestion() {
        if let selectedAnswer = selectedAnswer,
           selectedAnswer == quiz.questions[currentQuestionIndex].correctAnswer {
            score += 1
        }
        
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            isAnswerCorrect = nil
        }
    }
    
    private func restartQuiz() {
        let allQuestions: [Question] = load("Questions")
        quiz.questions = Array(allQuestions.shuffled().prefix(10))
        currentQuestionIndex = 0
        selectedAnswer = nil
        isAnswerCorrect = nil
        score = 0
    }
}

#Preview {
    GameView()
        .environmentObject(UserStore())
        .environmentObject(FavoritesManager())
}
