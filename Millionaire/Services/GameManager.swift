//
//  GameManager.swift
//  Millionaire
//
//  Created by Effin Leffin on 24.07.2025.
//

import Foundation

/// Менеджер, хранящий  глобальное состояние (сессия, bestScore, категории, уровни сложности)

@MainActor
final class GameManager: ObservableObject {  // Управляет сессиями
    private let questionRepository: IQuestionRepository
    
    /// Лучший результат, если он есть
    private(set) var bestScore: Int
    
    /// Модель последней игры, если она есть
    @Published private(set) var currentSession: GameSession?
    
    func updateSession(_ session: GameSession) {
        self.currentSession = session
    }
    
    init(
        questionRepository: QuestionRepository = QuestionRepository(),
        bestScore: Int = 0,
        lastSession: GameSession? = nil
    ) {
        self.questionRepository = questionRepository
        
        // TODO: Добавить чтение начальных значений из UserDefaults?
        self.bestScore = bestScore
        self.currentSession = lastSession
    }
    
    /// отдает категории из апишки
    func getCategories() async throws -> [QuestionCategory] {
        return try await questionRepository.fetchCategories()
    }

    /// Начинает новую игру
    func startNewGame(for categoryID: Int?) async throws -> GameSession {
        let easy = try await questionRepository.fetchQuestions(
            amount: 5,
            categoryID: categoryID,
            difficulty: .easy
        )
    
        guard var session = GameSession(questions: easy) else {
            throw StartGameFailure.invalidQuestions
        }
        
        // Установим выбранную категорию
        let selectedCategory = try await getCategories().first(where: { $0.id == categoryID })
        session.updateSelectedCategory(selectedCategory)
        
        self.currentSession = session
        
        return session
    }
    
    /// догружаем вопросы текущего уровня сложности
    func fetchQuestions(for difficulty: QuestionDifficulty) async throws -> [QuestionDTO] {
        let currentCategory = currentSession?.getCurrentCategory()
        return try await questionRepository.fetchQuestions(
            amount: 5,
            categoryID: currentCategory?.id,
            difficulty: difficulty
        )
  
    }
    
    /// Восстанавливает сохранённую сессию
    func restoreSession(_ session: GameSession) {
        Task {
            await MainActor.run { [weak self] in
                self?.currentSession = session
            }
        }
    }
    
    /// Актуализирует лучший результат при изменении сессии
    private func updateBestScoreIfNeeded() {
        // Результат применяем только для завершенной игры
        guard let currentSession, currentSession.isFinished else {
            return
        }
        
        // Сохраним результат, если он оказался больше ранее сохраненного
        bestScore = max(bestScore, currentSession.score)
    }
}

private extension GameManager {
    enum StartGameFailure: Error {
        case invalidQuestions
    }
}

extension GameManager {
    func endGame(withScore score: Int) {
        // Завершаем текущую сессию
        // currentSession?.isFinished = true
        
        // Обновляем лучший результат если нужно
        if score > bestScore {
            bestScore = score
            // Сохраняем в UserDefaults
            // UserDefaults.standard.set(bestScore, forKey: "bestScore")
        }
        
        // Очищаем текущую сессию
        currentSession = nil
    }
}
