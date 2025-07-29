//
//  QuestionRepository.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

// MARK: - Repository

protocol IQuestionRepository {
    func fetchCategories() async throws -> [QuestionCategory]
    func fetchQuestions(
        amount: Int,
        categoryID: Int?,
        difficulty: QuestionDifficulty?
    ) async throws -> [Question]
}

/// Provides access to trivia questions and categories from Open Trivia DB API
final class QuestionRepository: IQuestionRepository {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Fetch Categories
    /// Fetches available trivia categories from the API
    func fetchCategories() async throws -> [QuestionCategory] {
        let endpoint = QuestionAPIEndpoint.categories.makeEndpoint()
        let response: CategoryResponse = try await networkService.request(endpoint)
        return response.triviaCategories
    }

    // MARK: - Fetch Questions

    /// Fetches trivia questions with optional filters for category and difficulty
    /// - Parameters:
    ///   - amount: Number of questions to fetch (default is 15)
    ///   - categoryID: Optional category ID to filter by
    ///   - difficulty: Optional difficulty level (easy, medium, hard)
    func fetchQuestions(
        amount: Int,
        categoryID: Int? = nil,
        difficulty: QuestionDifficulty? = nil
    ) async throws -> [Question] {
        let endpoint = QuestionAPIEndpoint
            .questions(amount: amount, categoryID: categoryID, difficulty: difficulty)
            .makeEndpoint()
        let response: QuestionsResponse = try await networkService.request(endpoint)
        return response.results
    }
}
