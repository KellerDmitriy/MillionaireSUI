//
//  GameViewModel.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 22.07.2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Navigation States
extension GameViewModel {
    
    enum ScoreboardMode: Hashable, Equatable {
        case intermediate
        case roundWon
        case victoryMillionare
        case gameOver
    }
}


// локальное UI состояние + управление сервисами
@MainActor
final class GameViewModel: ObservableObject {
    
    private weak var navigation: NavigationCoordinator?
    private weak var gameManager: GameManager?
    
    // MARK: - Services
    private let timerService: ITimerService
    private let audioService: IAudioService
    private let storage: IStorageService
    
    private var cancellables = Set<AnyCancellable>()
    
    private let prizeCalculator = PrizeCalculator()
    
    private var session: GameSession {
        get {
            guard let currentSession = gameManager?.currentSession else {
                preconditionFailure("GameManager.currentSession is nil - this should never happen")
            }
            return currentSession
        }
        set {
            gameManager?.updateSession(newValue)
        }
    }
    
    /// Массив вариантов ответа в порядке их отображения
    @Published private(set) var answers: [String] = []

    @Published private(set) var disabledAnswers: Set<String> = []  /// Недоступные для выбора варианты ответов
    @Published var correctAnswer: String?
    @Published var duration: String = "00:00"
    @Published private(set) var timerType: TimerType = .normal /// Доп состояния для UI
    @Published var audienceVotes: [Int]? /// хранение версий от помощи зала в процентах
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var selectedAnswer: String?
    @Published var answerResultState: AnswerResult?

    // Храним текущую задачу для возможности отмены
    private var answerProcessingTask: Task<Void, Never>?
    
    // Важно: отменять задачу при деинициализации
    deinit {
        answerProcessingTask?.cancel()
        
        // Когда GameViewModel уничтожается, все его свойства тоже
        // Если при возврате назад нет этих сообщений - есть утечка!
#if DEBUG
        print(" GameViewModel деинициализирован")
#endif
    }
    
    var question: GameQuestion { session.currentQuestion }
    
    var numberQuestion: Int { session.currentQuestionIndex + 1 }
    
    var priceQuestion: String {
        prizeCalculator
            .getPrizeAmount(for: session.currentQuestionIndex)
            .formatted()
    }
    
    var lifelines: Set<Lifeline> { session.lifelines }
    

    @Published private(set) var isLoadingQuestions = false
    
    // MARK: Init
    init(
        navigation: NavigationCoordinator? = nil,
        gameManager: GameManager,
        audioService: IAudioService,
        timerService: ITimerService,
        storage: IStorageService = StorageService.shared
    ) {
        // инициализируем stored properties
        self.navigation = navigation
        self.gameManager = gameManager          // сохраняем ссылку
        self.audioService = audioService
        self.storage = storage
        self.timerService = timerService
        
        // ✅ Вместо этого просто читаем текущее состояние
        if let currentSession = gameManager.currentSession {
            self.answers = currentSession.currentQuestion.allAnswers.shuffled()
            print("   Инициализирован с \(currentSession.questions.count) вопросами")
        } else {
            preconditionFailure("GameManager must have active session before creating GameViewModel")
        }
        
        bindTimer()
        subscribeToSessionChanges()
    }
    
    // MARK: Subscribe
    private func subscribeToSessionChanges() {
        gameManager?.$currentSession
            .compactMap { $0 }  // Фильтруем nil
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)  // ВАЖНО: UI обновления только на main
            .sink { [weak self] updatedSession in
                guard let self = self else { return }
                
                print("📱 GameViewModel: смена вопроса на №\(updatedSession.currentQuestionIndex + 1)")
                
                // Обновляем answers когда меняется вопрос
                if !updatedSession.isFinished {
                    self.answers = updatedSession.currentQuestion.allAnswers.shuffled()
                }
                
                // Проверяем необходимость догрузки
                self.checkIfNeedMoreQuestions(session: updatedSession)
            }
            .store(in: &cancellables)
    }
    
    // MARK: FetchQuestions
    private func checkIfNeedMoreQuestions(session: GameSession) {
        let currentIndex = session.currentQuestionIndex
        let totalLoaded = session.questions.count
        print("GameViewModel: FetchQuestions")
        if totalLoaded - currentIndex <= 2 && totalLoaded < 15 {
            print("🚨 Экстренная догрузка! Вопрос: \(currentIndex + 1), Загружено: \(totalLoaded)")
            
            isLoadingQuestions = true
            
            Task(priority: .high) {
                await gameManager?.loadRemainingQuestions(
                    categoryID: session.selectedCategory?.id
                )
                
                await MainActor.run { [weak self] in
                    self?.isLoadingQuestions = false
                }
            }
        }
    }
    
    
    private func onTimeExpired() {
        audioService.playAnswerLockedSfx()
        stopGame()
        
        var newSession = session
        let checkpoint = prizeCalculator.getCheckpointPrizeAmount(before: newSession.currentQuestionIndex)
        newSession.setScore(checkpoint)
        newSession.finish()
        session = newSession
        print("время вышло")
        //  Время вышло - показываем скорборд как поражение
        checkGameEnd(answerResult: .incorrect) // ответ не выбран
    }
    
    private func stopGameResources() {
        audioService.stop()
        timerService.stopTimer()
        print("STOP TIMER")
    }
    
    // MARK: - Timer Binding
    private func bindTimer() {
        timerService.displayPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] displayData in
                self?.duration = displayData.formattedTime
                self?.timerType = displayData.type
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Answer Tap
    func onAnswer(_ answer: String) {
        // Отменяем предыдущую задачу, если она есть
        answerProcessingTask?.cancel() // Если пользователь быстро нажал другой ответ
        
        // обновляем значение выделленного ответа
        selectedAnswer = answer
        
        // Запускаем новую
        answerProcessingTask = Task {
            await processAnswerWithDelay(answer: answer)
        }
    }
    
    @MainActor
    private func processAnswerWithDelay(answer: String) async {
        
        // Cтавим на паузу таймер
        timerService.pauseTimer()
        
        // Играем звук интриги
        audioService.playAnswerLockedSfx()
        
        do {
            // Ждем для драматизма
            try await Task.sleep(for: .seconds(3))
            
            // Проверяем, не была ли задача отменена
            try Task.checkCancellation()
            
            // Обрабатываем ответ
            await processAnswer(answer)
            
        } catch {
            // Задача была отменена
            audioService.stop()
        }
    }
    
    @MainActor
    private func processAnswer(_ answer: String) async {
        
        // Получаем актуальную сессию из GameManager
        var updatedSession = session  // Это уже читает из gameManager?.currentSession
        
        print("Текущий вопрос №\(updatedSession.currentQuestionIndex + 1) из \(updatedSession.questions.count)")
        
        print("🎮 Следующий индекс будет: \(updatedSession.currentQuestionIndex + 1)")
        if updatedSession.currentQuestionIndex + 1 >= updatedSession.questions.count {
            print("⚠️ ВНИМАНИЕ: Следующего вопроса НЕТ!")
        }
        
        // Сохраняем индекс текущего вопроса ДО обработки
        let currentQuestionIndex = updatedSession.currentQuestionIndex
        
        // Сохраняем выбранный ответ — важно для подсветки
        selectedAnswer = answer
        correctAnswer = updatedSession.currentQuestion.correctAnswer
        
        // Обрабатываем ответ — получаем результат, но не начисляем тут ничего
        guard let answerResult = updatedSession.answer(answer: answer) else {
            return
        }
        
        // после обработки ответа
        print("📱 После ответа: индекс стал \(updatedSession.currentQuestionIndex), всего вопросов: \(updatedSession.questions.count)")
        
        // Начисляем призы используя PrizeCalculator
        switch answerResult {
        case .correct:
            let prize = prizeCalculator.getPrizeAmount(for: currentQuestionIndex)
            updatedSession.setScore(prize)
            
        case .incorrect:
            let checkpoint = prizeCalculator.getCheckpointPrizeAmount(before: currentQuestionIndex)
            updatedSession.setScore(checkpoint)
            answerResultState = .incorrect
        }
        
        // Устанавливаем состояние результата для анимации
        answerResultState = answerResult == .incorrect ? .incorrect : .correct
        
        // Ждём анимации результата
        do {
            try await Task.sleep(for: .seconds(2))
            try Task.checkCancellation()
            
            // Обновляем GameManager
            gameManager?.updateSession(updatedSession)
            // Подписка subscribeToSessionChanges автоматически обновит UI (answers, etc.)
            
            // Проверяем окончание игры
            if answerResult == .correct && !session.isFinished {
                // Подготовка следующего вопрос
                selectedAnswer = nil
                answerResultState = nil
                correctAnswer = nil
            }
            // Игра окончена
            checkGameEnd(answerResult: answerResult)
            
        } catch {
            // Отменено
            audioService.stop()
        }
    }
    
    private func checkGameEnd(answerResult: AnswerResult?) {
        let mode: ScoreboardMode
        
        if session.isFinished {
            if session.currentQuestionIndex == 14 {
                print(" ПОБЕДА! Выигран миллион!")
                mode = .victoryMillionare
                
            } else {
                print(" Игра окончена на вопросе \(session.currentQuestionIndex + 1)")
                print(" Выигрыш: \(session.score) ")
                mode = .gameOver
            }
        } else {
            mode = .roundWon
            print(" Выигрыш: \(session.score) ")
        }
        print(mode)
        // Делегируем навигацию родительскому компоненту
        navigation?.showScoreboard(session, mode: mode)
    }
    
    // MARK: - Help Button Actions
    func fiftyFiftyButtonTap() {
        guard let result = session.useFiftyFiftyLifeline() else {
            return
        }
        
        // Обновляем сессию
        session = session // Триггерим onSessionUpdated
        
        // Помечаем недоступные ответы
        disabledAnswers = result.disabledAnswers
    }
    
    func audienceButtonTap() {
        let visibleAnswers = answers.filter { !disabledAnswers.contains($0) }
        
        guard let result = session.useAudienceLifeline(allAnswers: visibleAnswers) else {
            return
        }
        var votes = Array(repeating: 0, count: 4)
        for (index, answer) in visibleAnswers.enumerated() {
            if let originalIndex = answers.firstIndex(of: answer) {
                votes[originalIndex] = result.votesPerAnswer[index]
            }
        }
        audienceVotes = votes
    }
    
    func secondChanceButtonTap() {
        guard session.useSecondChanceLifeline() != nil else { return }
    }
    
    // MARK: - NavigationCoordinator
    func setNavigation(_ navigation: NavigationCoordinator) {
        self.navigation = navigation
    }
    
    func routeToScoreboardWithIntermediate() {
        pauseGame()
        navigation?.showScoreboard(session, mode: .intermediate)
    }
}

private extension GameQuestion {
    var allAnswers: [String] {
        [correctAnswer] + incorrectAnswers
    }
}

extension GameViewModel {
    // MARK: - Game Control Methods
    
    // MARK: - Game State
    func handleGameStateOnAppear() async {
        await MainActor.run {
            switch gameManager?.gameState {
            case .startGame, .nextRound:
                startGame()
            case .resumeGame:
                resumeGame()
            case .none:
                stopGame()
            }
        }
    }

    // MARK: - Game Start
    func startGame() {
        // Стартуем только если нет выбранного ответа И это первый вопрос
        guard selectedAnswer == nil else { return }
        
        audioService.playGameSfx()
        
        startNewRound()
    }
    
    private func startNewRound() {
        // Печатаем для каждого нового вопроса
        print("category: \(String(describing: session.getCurrentCategory()?.name))")
        print("difficulty: \(session.currentQuestion.difficulty)")
        print("correctAnswer: \(session.currentQuestion.correctAnswer)")
        
        timerService.start30SecondTimer { [weak self] in
            self?.onTimeExpired()
        }
    }
    
    /// Ставит игру на паузу (при уходе с экрана)
    func pauseGame() {
        timerService.pauseTimer()
        audioService.pause()
        storage.saveGameSession(session)
    }
    
    /// Возобновляет игру (при возврате на экран)
    func resumeGame() {
        // Возобновляем только если нет выбранного ответа
        guard selectedAnswer == nil else { return }
        // Переустанавливаем коллбэк, чтобы он вызывал onTimeExpired у НОВОЙ VM
        timerService.setOnExpire { [weak self] in
            self?.onTimeExpired()
        }
        
        timerService.resumeTimer()
        audioService.resume()
    }
    
    /// Полностью останавливает игру (при выходе)
    func stopGame() {
        stopGameResources()
        answerProcessingTask?.cancel()
        session.finish()
        storage.clearSavedSession()
    }
}
