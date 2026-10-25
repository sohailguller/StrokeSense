//
//  Question.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//
import Foundation

struct Question: Decodable, Hashable {
    let question: String
    let choices: [String]
    let correctAnswer: String

    private enum CodingKeys: String, CodingKey {
        case question
        case choices
        case correctAnswer = "correct_answer"
    }

    /// The question in the app's language. Questions.json is English and doubles as the keys.
    var localized: Question {
        Question(question: question.localized, choices: choices.map(\.localized), correctAnswer: correctAnswer.localized)
    }
}
