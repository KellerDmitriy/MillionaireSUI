//
//  Questions.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 22.07.2025.
//

import Foundation

// MARK: - API Base

/// Static base URL for Open Trivia API (default with amount and type)
enum QuestionsAPI {
    static let baseURL = URL(string: "https://opentdb.com/api.php?amount=15&type=multiple")!
}

// MARK: - Difficulty

/// Represents the difficulty level of a trivia question
enum QuestionDifficulty: String, Codable {
    case easy, medium, hard
}

// MARK: - Questions Response

/// Top-level response from the questions API
struct QuestionsResponse: Codable {
    let responseCode: Int
    let results: [Question]
}

// MARK: - Question Model

/// Represents a single trivia question
struct Question: Codable, Hashable {
    let difficulty: QuestionDifficulty
    let category: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
}

// MARK: - Category Response

/// Top-level response from the category list API
struct CategoryResponse: Codable {
    let triviaCategories: [QuestionCategory]
}

// MARK: - Category Model

/// Represents a trivia category
struct QuestionCategory: Codable, Identifiable, Equatable, Hashable {
    let id: Int?
    let name: String
}
