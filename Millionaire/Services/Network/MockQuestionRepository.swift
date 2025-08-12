//
//  MockQuestionRepository.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 12.08.25.
//

// Mock implementation for testing

import Foundation

#if DEBUG

// MARK: - Mock Question Repository
final class MockQuestionRepository: IQuestionRepository {
    
    // Настраиваемые параметры для тестов
    var shouldFailCategories = false
    var shouldFailQuestions = false
    var categoriesDelay: TimeInterval = 0
    var questionsDelay: TimeInterval = 0
    
    // Счетчики вызовов для проверки
    private(set) var fetchCategoriesCallCount = 0
    private(set) var fetchQuestionsCallCount = 0
    private(set) var lastQuestionsAmount: Int?
    private(set) var lastQuestionsCategoryID: Int?
    private(set) var lastQuestionsDifficulty: QuestionDifficulty?
    
    // Предустановленные данные для возврата
    var mockCategories: [QuestionCategory] = []
    var mockQuestions: [QuestionDTO] = []
    
    init() {
        // Устанавливаем дефолтные моковые данные
        setupDefaultMockData()
    }
    
    // MARK: - IQuestionRepository Implementation
    
    func fetchCategories() async throws -> [QuestionCategory] {
        fetchCategoriesCallCount += 1
        
        // Симуляция задержки сети
        if categoriesDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(categoriesDelay * 1_000_000_000))
        }
        
        // Симуляция ошибки
        if shouldFailCategories {
            throw MockRepositoryError.networkError
        }
        
        return mockCategories.isEmpty ? generateMockCategories() : mockCategories
    }
    
    func fetchQuestions(
        amount: Int,
        categoryID: Int?,
        difficulty: QuestionDifficulty?
    ) async throws -> [QuestionDTO] {
        fetchQuestionsCallCount += 1
        lastQuestionsAmount = amount
        lastQuestionsCategoryID = categoryID
        lastQuestionsDifficulty = difficulty
        
        // Симуляция задержки сети
        if questionsDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(questionsDelay * 1_000_000_000))
        }
        
        // Симуляция ошибки
        if shouldFailQuestions {
            throw MockRepositoryError.networkError
        }
        
        // Возвращаем либо предустановленные, либо генерируем
        if !mockQuestions.isEmpty {
            return Array(mockQuestions.prefix(amount))
        } else {
            return generateMockQuestions(amount: amount, difficulty: difficulty)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Сбрасывает счетчики и настройки
    func reset() {
        fetchCategoriesCallCount = 0
        fetchQuestionsCallCount = 0
        lastQuestionsAmount = nil
        lastQuestionsCategoryID = nil
        lastQuestionsDifficulty = nil
        shouldFailCategories = false
        shouldFailQuestions = false
        categoriesDelay = 0
        questionsDelay = 0
        mockCategories = []
        mockQuestions = []
        setupDefaultMockData()
    }
    
    /// Устанавливает дефолтные моковые данные
    private func setupDefaultMockData() {
        mockCategories = generateMockCategories()
        mockQuestions = []  // Будут генерироваться по запросу
    }
    
    /// Генерирует моковые категории
    private func generateMockCategories() -> [QuestionCategory] {
        return [
            QuestionCategory(id: 0, name: "All Categories"),
            QuestionCategory(id: 9, name: "General Knowledge"),
            QuestionCategory(id: 10, name: "Entertainment: Books"),
            QuestionCategory(id: 11, name: "Entertainment: Film"),
            QuestionCategory(id: 12, name: "Entertainment: Music"),
            QuestionCategory(id: 17, name: "Science & Nature"),
            QuestionCategory(id: 18, name: "Science: Computers"),
            QuestionCategory(id: 21, name: "Sports"),
            QuestionCategory(id: 22, name: "Geography"),
            QuestionCategory(id: 23, name: "History"),
            QuestionCategory(id: 24, name: "Politics"),
            QuestionCategory(id: 25, name: "Art"),
            QuestionCategory(id: 26, name: "Celebrities"),
            QuestionCategory(id: 27, name: "Animals"),
            QuestionCategory(id: 28, name: "Vehicles")
        ]
    }
    
    /// Генерирует моковые вопросы
    private func generateMockQuestions(
        amount: Int,
        difficulty: QuestionDifficulty?
    ) -> [QuestionDTO] {
        return (0..<amount).map { index in
            let questionDifficulty: QuestionDifficulty
            if let difficulty = difficulty {
                questionDifficulty = difficulty
            } else {
                // Автоматически распределяем сложность
                if index < 5 {
                    questionDifficulty = .easy
                } else if index < 10 {
                    questionDifficulty = .medium
                } else {
                    questionDifficulty = .hard
                }
            }
            
            return createMockQuestion(
                index: index,
                difficulty: questionDifficulty
            )
        }
    }
    
    /// Создает один моковый вопрос
    private func createMockQuestion(
        index: Int,
        difficulty: QuestionDifficulty
    ) -> QuestionDTO {
        let questions = getMockQuestionsByDifficulty(difficulty)
        let questionData = questions[index % questions.count]
        
        return QuestionDTO(
            difficulty: difficulty,
            category: "Mock Category",
            question: questionData.question,
            correctAnswer: questionData.correct,
            incorrectAnswers: questionData.incorrect
        )
    }
    
    /// Возвращает наборы вопросов по сложности
    private func getMockQuestionsByDifficulty(_ difficulty: QuestionDifficulty) -> [(question: String, correct: String, incorrect: [String])] {
        switch difficulty {
        case .easy:
            return [
                ("What color is the sky?", "Blue", ["Red", "Green", "Yellow"]),
                ("How many days in a week?", "7", ["5", "6", "8"]),
                ("What is 2 + 2?", "4", ["3", "5", "6"]),
                ("Capital of France?", "Paris", ["London", "Berlin", "Madrid"]),
                ("How many months in a year?", "12", ["10", "11", "13"])
            ]
            
        case .medium:
            return [
                ("Who painted the Mona Lisa?", "Leonardo da Vinci", ["Michelangelo", "Raphael", "Donatello"]),
                ("What year did World War II end?", "1945", ["1944", "1946", "1943"]),
                ("What is the capital of Australia?", "Canberra", ["Sydney", "Melbourne", "Brisbane"]),
                ("Who wrote 'Romeo and Juliet'?", "Shakespeare", ["Dickens", "Austen", "Wilde"]),
                ("What is the largest planet?", "Jupiter", ["Saturn", "Neptune", "Uranus"])
            ]
            
        case .hard:
            return [
                ("What is the speed of light?", "299,792,458 m/s", ["199,792,458 m/s", "399,792,458 m/s", "499,792,458 m/s"]),
                ("When was the Byzantine Empire founded?", "330 AD", ["476 AD", "285 AD", "395 AD"]),
                ("What is Avogadro's number?", "6.022×10²³", ["6.022×10²²", "6.022×10²⁴", "6.022×10²¹"]),
                ("Who discovered penicillin?", "Alexander Fleming", ["Louis Pasteur", "Robert Koch", "Edward Jenner"]),
                ("What is the Chandrasekhar limit?", "1.4 solar masses", ["2.4 solar masses", "0.4 solar masses", "3.4 solar masses"])
            ]
        }
    }
}

// MARK: - Mock Repository Error
enum MockRepositoryError: LocalizedError {
    case networkError
    case invalidData
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Mock network error"
        case .invalidData:
            return "Mock invalid data error"
        case .timeout:
            return "Mock timeout error"
        }
    }
}

// MARK: - Testing Helpers
extension MockQuestionRepository {
    
    /// Настраивает репозиторий для симуляции успешной игры
    func setupForSuccessfulGame() {
        shouldFailCategories = false
        shouldFailQuestions = false
        categoriesDelay = 0.1  // Небольшая задержка для реализма
        questionsDelay = 0.2
    }
    
    /// Настраивает репозиторий для симуляции проблем с сетью
    func setupForNetworkFailure() {
        shouldFailCategories = false
        shouldFailQuestions = true
        questionsDelay = 1.0  // Долгая задержка перед ошибкой
    }
    
    /// Настраивает специфичные вопросы для тестирования
    func setupWithCustomQuestions(_ questions: [QuestionDTO]) {
        mockQuestions = questions
    }
    
    /// Создает предсказуемый набор вопросов для тестирования
    static func createPredictableQuestions(count: Int = 15) -> [QuestionDTO] {
        return (0..<count).map { index in
            QuestionDTO(
                difficulty: index < 5 ? .easy : index < 10 ? .medium : .hard,
                category: "Test Category",
                question: "Test Question \(index + 1)?",
                correctAnswer: "Correct Answer \(index + 1)",
                incorrectAnswers: [
                    "Wrong Answer A\(index + 1)",
                    "Wrong Answer B\(index + 1)",
                    "Wrong Answer C\(index + 1)"
                ]
            )
        }
    }
}

// MARK: - Usage Examples
/*
 // В тестах:
 let mockRepo = MockQuestionRepository()
 mockRepo.setupForSuccessfulGame()
 let gameManager = GameManager(questionRepository: mockRepo)
 
 // Проверка вызовов:
 XCTAssertEqual(mockRepo.fetchQuestionsCallCount, 1)
 XCTAssertEqual(mockRepo.lastQuestionsDifficulty, .easy)
 
 // Симуляция ошибки:
 mockRepo.shouldFailQuestions = true
 */

#endif
