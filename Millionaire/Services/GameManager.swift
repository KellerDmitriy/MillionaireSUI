//
//  GameManager.swift
//  Millionaire
//
//  Created by Effin Leffin on 24.07.2025.
//

import Foundation

// Менеджер, хранящий  глобальное состояние (сессия, bestScore, категории, уровни сложности)
// MARK: - GameManager (единственный владелец StorageService)
@MainActor
final class GameManager: ObservableObject {  // Управляет сессиями
    private let questionRepository: IQuestionRepository
    private let storage: IStorageService
    
    /// Лучший результат, если он есть
    private(set) var bestScore: Int {
        didSet {
            storage.saveBestScore(bestScore)
        }
    }
    
    @Published var selectedCategory: QuestionCategory? {
        didSet {
            storage.saveSelectedCategory(selectedCategory?.id)
        }
    }
    
    //  текущий выбор для новой игры
    /// Модель последней игры, если она есть
    @Published private(set) var currentSession: GameSession? {
        didSet {
            // Автосохранение при изменении
            if let session = currentSession, !session.isFinished {
                storage.saveGameSession(session)
            } else if currentSession?.isFinished == true {
                storage.clearSavedSession()
            }
        }
    }
    
    func updateSession(_ session: GameSession) {
        self.currentSession = session
    }
    
    init(
        questionRepository: IQuestionRepository = QuestionRepository(),
        storage: IStorageService = StorageService.shared // Используем синглтон по умолчанию
    ) {
        self.questionRepository = questionRepository
        self.storage = storage
        
        // Загружаем сохраненные данные
        self.bestScore = storage.loadBestScore()
        
        // Восстанавливаем сессию если есть
        if let savedSession = storage.loadGameSession(), !savedSession.isFinished {
            self.currentSession = savedSession
        }
        
        // Загружаем выбранную категорию
        if let categoryId = storage.loadSelectedCategory() {
            self.selectedCategory = QuestionCategory(id: categoryId, name: "")
        }
    }
    
    // MARK: - Public Storage Methods (централизованный доступ)
    
    /// Сохраняет текущее состояние игры
    func saveGameState() {
        if let session = currentSession, !session.isFinished {
            storage.saveGameSession(session)
        }
    }
    
    /// Очищает сохраненную сессию
    func clearSavedGame() {
        storage.clearSavedSession()
    }
    
    /// Проверяет наличие сохраненной игры
    func hasSavedGame() -> Bool {
        return storage.loadGameSession() != nil
    }
    
    /// Загружает статистику
    func getStatistics() -> GameStatistics {
        return storage.loadStatistics()
    }
    
    /// Обновляет статистику после игры
    func updateStatistics(questionsAnswered: Int, winnings: Int, won: Bool, lifelinesUsed: Set<Lifeline>) {
        var stats = storage.loadStatistics()
        stats.recordGame(
            questionsAnswered: questionsAnswered,
            winnings: winnings,
            won: won,
            lifelinesUsed: lifelinesUsed
        )
        storage.saveStatistics(stats)
    }
    
    /// Настройки звука
    func isSoundEnabled() -> Bool {
        return storage.loadSoundEnabled()
    }
    
    func setSoundEnabled(_ enabled: Bool) {
        storage.saveSoundEnabled(enabled)
    }
    
    // TODO: Проверить остальные:
    
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
        currentSession?.finish()
    }
}

extension GameManager {
    // Обработка ответа
    func processAnswer(_ answer: String) -> AnswerResult? {
        guard var session = currentSession else {
            // Если нет сессии - это критическая ошибка
            preconditionFailure("processAnswer called without active session")
        }
        
        // ДО обработки ответа
        print("📱 Обработка ответа на вопрос №\(session.currentQuestionIndex + 1) из \(session.questions.count)")
        
        let currentIndex = session.currentQuestionIndex
        
        // Проверяеv, правильный ли ответ, БЕЗ перехода к следующему вопросу
        let result = session.checkAnswer(answer)
        
        // ПОСЛЕ обработки (session.answer уже изменил индекс)
        print("🎮 После ответа: индекс стал \(session.currentQuestionIndex)")
        print("🎮 Следующий индекс будет: \(session.currentQuestionIndex + 1)")
        if session.currentQuestionIndex + 1 > session.questions.count {
            print("⚠️ ВНИМАНИЕ: Следующего вопроса НЕТ! Требуется дозагрузка")
        }
        
        // Начисление призов
        switch result {
        case .correct:
            let prize = PrizeCalculator().getPrizeAmount(for: currentIndex)
            session.setScore(prize)
            print("✅ Правильный ответ! Приз: $\(prize)")
            
            // Если был правильный ответ и было активно право на ошибку - деактивируем
            if session.secondChanceActive {
                session.deactivateSecondChance()
                print("✅ Правильный ответ! Право на ошибку сохранено")
            }
            
        case .incorrect:
            // Проверяем, активно ли право на ошибку
            if session.secondChanceActive {
                print("⚠️ Неправильный ответ, но использовано право на ошибку")
                // Деактивируем право на ошибку
                session.deactivateSecondChance()  // Использовали подсказку
            } else {
                let checkpoint = PrizeCalculator().getCheckpointPrizeAmount(before: currentIndex)
                session.setScore(checkpoint)
                session.finish()  // Завершаем игру
                print("❌ Неправильный ответ. Игра окончена. Выигрыш: $\(checkpoint)")
            }
        }
        
        currentSession = session  // Триггерит @Published
        return result
    }
    
    // Для перехода к следующему вопросу
    func moveToNextQuestion() {
        guard var session = currentSession else {
            print("❌ moveToNextQuestion: нет активной сессии")
            return
        }
        
        print("🎮 Переход к следующему вопросу...")
        print("   Текущий индекс ДО: \(session.currentQuestionIndex)")
        session.moveToNextQuestion()
        print("   Текущий индекс ПОСЛЕ: \(session.currentQuestionIndex)")
        
        currentSession = session // Обновляем сессию!
    }
    
    // Завершение по таймеру
    func finishGameWithTimeout() {
        guard var session = currentSession else { return }
        let checkpoint = PrizeCalculator().getCheckpointPrizeAmount(before: session.currentQuestionIndex)
        session.setScore(checkpoint)
        session.finish()
        currentSession = session
    }
    
    // Подсказки
    func useFiftyFiftyLifeline() -> FiftyFiftyLifelineResult? {
        guard var session = currentSession else { return nil }
        let result = session.useFiftyFiftyLifeline()
        currentSession = session
        return result
    }
    
    func useAudienceLifeline(allAnswers: [String]) -> AudienceLifelineResult? {
        guard var session = currentSession else { return nil }
        let result = session.useAudienceLifeline(allAnswers: allAnswers)
        currentSession = session
        return result
    }
    
    func useSecondChanceLifeline() -> SecondChanceLifelineResult? {
        guard var session = currentSession else { return nil }
        let result = session.useSecondChanceLifeline()
        currentSession = session
        return result
    }
}

// MARK: - Testing Support
extension GameManager {
#if DEBUG
    /// Фабричный метод для тестирования с моками
    @MainActor
    static func makeForTesting(
        questionRepository: IQuestionRepository = MockQuestionRepository(),
        storage: IStorageService = MockStorageService()
    ) -> GameManager {
        return GameManager(
            questionRepository: questionRepository,
            storage: storage
        )
    }
    
    /// Создает GameManager с предустановленными данными для Preview
    @MainActor
    static func makeForPreview(
        withBestScore bestScore: Int = 0,
        withActiveSession: Bool = false
    ) -> GameManager {
        let mockRepo = MockQuestionRepository()
        mockRepo.setupForSuccessfulGame()
        
        let mockStorage = MockStorageService()
        if bestScore > 0 {
            mockStorage.saveBestScore(bestScore)
        }
        
        let manager = GameManager(
            questionRepository: mockRepo,
            storage: mockStorage
        )
        
        if withActiveSession {
            // Создаем тестовую сессию
            let questions = MockQuestionRepository.createPredictableQuestions()
            if var session = GameSession(questions: questions) {
                session.setScore(5000)
                manager.currentSession = session
            }
        }
        
        return manager
    }
#endif
}
