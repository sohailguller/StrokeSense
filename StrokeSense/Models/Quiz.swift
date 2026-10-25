//
//  Quiz.swift
//  StrokeSense
//
//  Created by Sohail Guller on 7/8/24.
//

import Foundation
import SwiftUI

public func load<T: Decodable>(_ filename: String) -> T {
    guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
        fatalError("Couldn't find \(filename).json in main bundle.")
    }

    do {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(T.self, from: data)
        return decodedData
    } catch {
        fatalError("Couldn't parse \(filename).json as \(T.self):\n\(error)")
    }
}

func findDuplicates<T: Hashable>(in array: [T]) -> [T] {
    var elementCounts: [T: Int] = [:]
    var duplicates: Set<T> = []

    for element in array {
        elementCounts[element, default: 0] += 1
        if elementCounts[element]! > 1 {
            duplicates.insert(element)
        }
    }

    return Array(duplicates)
}

class Quiz: ObservableObject {
    @Published var questions: [Question] = []

    init() {
        questions = Self.randomQuestions()
    }

    /// Ten questions in random order, in the app's language.
    static func randomQuestions() -> [Question] {
        let allQuestions: [Question] = load("Questions")
        return allQuestions.shuffled().prefix(10).map(\.localized)
    }
}

