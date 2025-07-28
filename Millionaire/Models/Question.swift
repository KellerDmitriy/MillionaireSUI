//
//  Questions.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 22.07.2025.
//

import Foundation

enum QuestionsAPI {
    static let baseURL = URL(string: "https://opentdb.com/api.php?amount=15&type=multiple")!
}

enum QuestionDifficulty: String, Codable {
    case easy, medium, hard
}

struct QuestionsResponse: Codable {
    let responseCode: Int
    let results: [Question]
}

struct Question: Codable, Hashable {
    let difficulty: QuestionDifficulty
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
}
