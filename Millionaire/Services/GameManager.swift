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
    
    @Published var selectedCategoryID: Int? = 0 //  текущий выбор для новой игры
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
    
    func selectCategory(_ categoryID: Int?) {
        selectedCategoryID = categoryID
        // Опционально: сохранить в UserDefaults для персистентности
        UserDefaults.standard.set(categoryID, forKey: "selectedCategoryID")
    }
    
    func getCategories() async throws -> [QuestionCategory] {
        do {
            // Используем QuestionRepository для получения категорий
            let repository = QuestionRepository()
            let categories = try await repository.fetchCategories()
            
            print(" GameManager: Received \(categories.count) categories from API")
            return categories
            
        } catch {
            print(" GameManager: Failed to fetch categories: \(error)")
            throw error
        }
    }
    
    /// Начинает новую игру
    func startNewGame() async throws -> GameSession {
        
        let categoryToUse = (selectedCategoryID == 0) ? nil : selectedCategoryID
        let session = try await createInitialSession(for: categoryToUse)
        
        // ❌ ВРЕМЕННО ОТКЛЮЧЕНО - фоновая догрузка
//        Task.detached(priority: .background) { [weak self] in
//               await self?.ensureMinimumQuestions(totalNeeded: 15, categoryID: categoryToUse)
//           }
//        
        return session
    }
    
    // MARK: - Helper Methods
    // Создание сессии с easy-вопросами
    private func createInitialSession(for categoryID: Int?) async throws -> GameSession {
        let easy = try await questionRepository.fetchQuestions(
            amount: 5,
            categoryID: categoryID,
            difficulty: .easy
        )
        
        guard var session = GameSession(questions: easy) else {
            throw StartGameFailure.invalidQuestions
        }
        
        let selectedCategory = try await getCategories().first(where: { $0.id == categoryID })
        session.updateSelectedCategory(selectedCategory)
        
        self.currentSession = session
        
        return session
    }
    
    /// Фоновая догрузка medium и hard
    func ensureMinimumQuestions(totalNeeded: Int, categoryID: Int?) async {
        guard let session = self.currentSession else { return }

        print("📦 GameManager: Начинаем догрузку. Сейчас вопросов: \(session.questions.count)")
        
        var attempts = 0
        let maxAttempts = 5
        let delayBetweenAttempts: TimeInterval = 5

        while session.questions.count < totalNeeded && attempts < maxAttempts {
            let remaining = totalNeeded - session.questions.count
            let batchSize = min(5, remaining)

            do {
                let difficulty = self.pickNextDifficulty(for: session)
                
                let newQuestions = try await self.questionRepository.fetchQuestions(
                    amount: batchSize,
                    categoryID: categoryID,
                    difficulty: difficulty
                )

                self.currentSession?.appendQuestions(newQuestions)
                
                // Проверка, что изменения сохранились
                if let updatedCount = self.currentSession?.questions.count {
                    print("📦 GameManager: После append в currentSession стало \(updatedCount) вопросов")
                } else {
                    print("⚠️ GameManager: currentSession is nil!")
                }

                if self.currentSession?.questions.count ?? 0 >= totalNeeded {
                
                    break
                }
            } catch {
                print("⚠️ Попытка \(attempts + 1) не удалась: \(error)")
            }

            attempts += 1
            try? await Task.sleep(nanoseconds: UInt64(delayBetweenAttempts * 1_000_000_000))
        }

        print("📦 Итоговое количество вопросов: \(self.currentSession?.questions.count ?? 0)")
    }
    
    private func pickNextDifficulty(for session: GameSession) -> QuestionDifficulty {
        let count = session.questions.count
        if count < 5 {
            return .easy
        } else if count < 10 {
            return .medium
        } else {
            return .hard
        }
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
        case invalidCategory
        case notEnoughQuestions
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
