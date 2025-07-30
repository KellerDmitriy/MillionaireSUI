//
//  GameQuestion.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 30.07.2025.
//

import Foundation

// Domain-модель
struct GameQuestion: Codable, Hashable {
    let difficulty: QuestionDifficulty
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
}
