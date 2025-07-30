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
    #warning("застрял на момоенте как лучше догружать воппросы исходя из сложности чтобы не фильтровать их после, а просто догружать")
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
//        let selectedCategory = try await getCategories().first(where: { $0.id == categoryID })
//        session.updateSelectedCategory(selectedCategory)

        self.currentSession = session

//        // 🔄 Заранее подгрузим medium и hard
//        let medium = try await questionRepository.fetchQuestions(
//            amount: 5,
//            categoryID: categoryID,
//            difficulty: .medium
//        )
//        session.appendQuestions(medium, difficulty: .medium)
//
//        let hard = try await questionRepository.fetchQuestions(
//            amount: 5,
//            categoryID: categoryID,
//            difficulty: .hard
//        )
//        session.appendQuestions(hard, difficulty: .hard)

        self.currentSession = session
        return session
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
        //currentSession?.isFinished = true
        
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

// Фоновая загрузка medium и hard
extension GameManager {
    func loadNextDiffultyIfNeeded() async throws {
        guard var session = currentSession else { return }
        let index = session.currentQuestionIndex
        
        do {
            if index == 5 && !session.loadedDifficulties.contains(.medium) {
                let medium = try await questionRepository.fetchQuestions(
                    amount: 5,
                    categoryID: session.selectedCategory?.id,
                    difficulty: .medium
                )
                session.appendQuestions(medium, difficulty: .medium)
                self.currentSession = session
            }
            
            if index == 10 && !session.loadedDifficulties.contains(.hard) {
                let hard = try await questionRepository.fetchQuestions(
                    amount: 5,
                    categoryID: session.selectedCategory?.id,
                    difficulty: .hard
                )
                session.appendQuestions(hard, difficulty: .medium)
                self.currentSession = session
            }
        } catch {
            throw StartGameFailure.invalidQuestions
        }
    }
}
