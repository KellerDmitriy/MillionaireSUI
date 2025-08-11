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
    
    @Published var selectedCategory: QuestionCategory?
    //  текущий выбор для новой игры
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
    
    func selectCategory(_ category: QuestionCategory?) {
        selectedCategory = category
        // Опционально: сохранить в UserDefaults для персистентности
        UserDefaults.standard.set(category?.id, forKey: "selectedCategoryID")
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
    func startNewGame() async throws {
        let categoryToUse = (selectedCategory?.id == 0) ? nil : selectedCategory?.id
        
        // 1. Загружаем первые 5 easy
        try await createAndStoreInitialSession(for: categoryToUse)
    }
    
    private func loadMediumQuestions(categoryID: Int?) async {
        do {
            print("📦 Начинаем загрузку medium вопросов...")
            let medium = try await questionRepository.fetchQuestions(
                amount: 5,
                categoryID: categoryID,
                difficulty: .medium
            )
            
            await MainActor.run { [weak self] in
                guard var session = self?.currentSession else {
                    print("⚠️ Нет активной сессии для добавления medium")
                    return
                }
                session.appendQuestions(medium)
                self?.currentSession = session
                print("✅ Medium вопросы добавлены. Всего: \(session.questions.count)")
            }
            
            // После medium загружаем hard
            await loadHardQuestions(categoryID: categoryID)
            
        } catch {
            print("❌ Ошибка загрузки medium: \(error)")
            // Можно попробовать еще раз через небольшую задержку
            try? await Task.sleep(for: .seconds(2))
            await loadMediumQuestions(categoryID: categoryID)
        }
    }

    private func loadHardQuestions(categoryID: Int?) async {
        do {
            print("📦 Начинаем загрузку hard вопросов...")
            let hard = try await questionRepository.fetchQuestions(
                amount: 5,
                categoryID: categoryID,
                difficulty: .hard
            )
            
            await MainActor.run { [weak self] in
                guard var session = self?.currentSession else {
                    print("⚠️ Нет активной сессии для добавления hard")
                    return
                }
                session.appendQuestions(hard)
                self?.currentSession = session
                print("✅ Hard вопросы добавлены. Всего: \(session.questions.count)")
            }
        } catch {
            print("❌ Ошибка загрузки hard: \(error)")
            // Повторная попытка
            try? await Task.sleep(for: .seconds(2))
            await loadHardQuestions(categoryID: categoryID)
        }
    }
    
    // MARK: - Emergency Loading (вызывается из GameViewModel)
    func loadRemainingQuestions(categoryID: Int?) async {
        guard let session = currentSession else { return }
        
        let loaded = session.questions.count
        
        // Определяем что нужно догрузить
        if loaded < 10 {
            // Нужны medium вопросы
            await loadMediumQuestions(categoryID: categoryID)
        } else if loaded < 15 {
            // Нужны только hard вопросы
            await loadHardQuestions(categoryID: categoryID)
        }
    }
    
    // MARK: - Helper Methods
    // Создание сессии с easy-вопросами
    private func createAndStoreInitialSession(for categoryID: Int?) async throws {
        let easy = try await questionRepository.fetchQuestions(
            amount: 5,
            categoryID: categoryID,
            difficulty: .easy
        )
        
        guard var session = GameSession(questions: easy) else {
            throw StartGameFailure.invalidQuestions
        }
        
        session.updateSelectedCategory(selectedCategory)
        
        self.currentSession = session
    }
    
//    /// Фоновая догрузка medium и hard
//    func ensureMinimumQuestions(totalNeeded: Int, categoryID: Int?) async {
//        // Проверяем наличие сессии
//        guard var session = self.currentSession else {
//            print("⚠️ GameManager: No current session for background loading")
//            return
//        }
//        
//        print("📦 GameManager: Начинаем догрузку. Сейчас вопросов: \(session.questions.count)")
//        
//        var attempts = 0
//        let maxAttempts = 5
//        let delayBetweenAttempts: TimeInterval = 5
//        
//        while session.questions.count < totalNeeded && attempts < maxAttempts {
//            let remaining = totalNeeded - session.questions.count
//            let batchSize = min(5, remaining)
//            
//            do {
//                let difficulty = self.pickNextDifficulty(for: session)
//                
//                let newQuestions = try await self.questionRepository.fetchQuestions(
//                    amount: batchSize,
//                    categoryID: categoryID,
//                    difficulty: difficulty
//                )
//                
//                session.appendQuestions(newQuestions) // обновляем локальную копию
//                self.currentSession = session // сохраняем обратно в currentSession
//                
//                print("📦 GameManager: После append стало \(session.questions.count) вопросов")
//                
//                if session.questions.count >= totalNeeded {
//                    break
//                }
//            } catch {
//                print("⚠️ Попытка \(attempts + 1) не удалась: \(error)")
//            }
//            
//            attempts += 1
//            // Небольшая задержка между попытками
//            if attempts < maxAttempts {
//                try? await Task.sleep(nanoseconds: UInt64(delayBetweenAttempts * 1_000_000_000))
//            }
//        }
//        
//        print("📦 Итоговое количество вопросов: \(session.questions.count)")
//    }
//    
//    private func pickNextDifficulty(for session: GameSession) -> QuestionDifficulty {
//        let count = session.questions.count
//        if count < 5 {
//            return .easy
//        } else if count < 10 {
//            return .medium
//        } else {
//            return .hard
//        }
//    }
    
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
