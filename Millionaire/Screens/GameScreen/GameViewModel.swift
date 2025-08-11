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
    
    private weak var gameManager: GameManager?
    
    // MARK: - Services
    
    private let timerService: ITimerService
    private let audioService: IAudioService
    private let storage: IStorageService
    
    private var cancellables = Set<AnyCancellable>()
    
    private let prizeCalculator = PrizeCalculator()
    
    /// Обработчик перехода к скорборду
    private let onNavigateToScoreboard: ((GameSession, ScoreboardMode) -> Void)?
    
    private var session: GameSession {
        guard let currentSession = gameManager?.currentSession else {
            preconditionFailure("GameManager.currentSession is nil - this should never happen")
        }
        return currentSession
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
        timerService.stopTimer()
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
    
    // MARK: Init
    init(
        gameManager: GameManager,
        onNavigateToScoreboard: ((GameSession, ScoreboardMode) -> Void)? = nil,
        audioService: IAudioService = AudioService.shared,
        storage: IStorageService = StorageService.shared,
        timerService: ITimerService = TimerService()
    ) {
        // инициализируем stored properties
        self.gameManager = gameManager          // сохраняем ссылку
        self.audioService = audioService
        self.storage = storage
        self.timerService = timerService
        self.onNavigateToScoreboard = onNavigateToScoreboard
        
        // читаем текущее состояние
        if let currentSession = gameManager.currentSession {
            self.answers = currentSession.currentQuestion.allAnswers.shuffled()
            print("   Инициализирован с \(currentSession.questions.count) вопросами")
        } else {
            preconditionFailure("GameManager must have active session before creating GameViewModel")
        }
        
        bindTimer()
        subscribeToSessionChanges()
    }
    
    private func subscribeToSessionChanges() {
        gameManager?.$currentSession
            .compactMap { $0 }  // Фильтруем nil
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)  // ВАЖНО: UI обновления только на main
            .sink { [weak self] updatedSession in
                guard let self = self else { return }
                
                print("📱 GameViewModel: сессия обновлена")
                print("   Вопрос №\(updatedSession.currentQuestionIndex + 1) из \(updatedSession.questions.count)")

                // Обновляем answers когда меняется вопрос
                if self.selectedAnswer == nil && // Нет выбранного ответа (новый вопрос)
                   !updatedSession.isFinished { // Игра не завершена
                    print("    Перемешиваем ответы для нового вопроса")
                    self.answers = updatedSession.currentQuestion.allAnswers.shuffled()
                } else {
                    print("    Не перемешиваем - показываем результат")
                }
                
                // Проверяем необходимость догрузки
                self.checkIfNeedMoreQuestions(session: updatedSession)
            }
            .store(in: &cancellables)
    }
    
    @Published private(set) var isLoadingQuestions = false
    
    private func checkIfNeedMoreQuestions(session: GameSession) {
        let currentIndex = session.currentQuestionIndex
        let totalLoaded = session.questions.count
        
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
    
    // MARK: - Game Start
    func startGame() {
        // Стартуем только если нет выбранного ответа И это первый вопрос
        guard selectedAnswer == nil else { return }
        
        audioService.playGameSfx()
        
        startNewRound()
    }
    
    private func startNewRound() {
        print("Запускаем таймер для нового вопроса")
        
        // Печатаем для каждого нового вопроса
        print("category: \(String(describing: session.getCurrentCategory()?.name))")
        print("difficulty: \(session.currentQuestion.difficulty)")
        print("correctAnswer: \(session.currentQuestion.correctAnswer)")
        
        timerService.start30SecondTimer { [weak self] in
            self?.onTimeExpired()
        }
    }
    
    // MARK: - Continue Game
    
    // при возврате со Scoreboard
    func continueAfterScoreboard() {
        print("🎮 Продолжаем игру после Scoreboard")
        
        // Упрощаем логику - если игра не окончена, значит был правильный ответ
        // (иначе бы игра завершилась)
        if !session.isFinished {
            print("📍 Переход к следующему вопросу...")
            gameManager?.moveToNextQuestion()
            
            // Очищаем UI состояние для нового вопроса
            selectedAnswer = nil
            answerResultState = nil
            correctAnswer = nil
            disabledAnswers = []
            audienceVotes = nil
            
            // Запускаем таймер для нового вопроса
            startNewRound()
        } else {
            print("⚠️ Не переходим к следующему вопросу: isFinished=\(session.isFinished), answerResult=\(String(describing: answerResultState))")
        }
    }
    
    // при возврате со Scoreboard с правом на ошибку
    func continueAfterIncorrectWithSecondChance() {
        if !session.isFinished {
            gameManager?.moveToNextQuestion()
            
            // Очистка UI
            selectedAnswer = nil
            answerResultState = nil
            correctAnswer = nil
            disabledAnswers = []
            
            startNewRound()
        }
    }
    
    private func onTimeExpired() {
        //  Защита от повторного срабатывания
        guard !session.isFinished else {
               print("⚠️ Таймер сработал, но игра уже завершена")
               return
           }
           
           //  Защита если уже выбран ответ
           guard selectedAnswer == nil else {
               print("⚠️ Таймер сработал, но ответ уже обрабатывается")
               return
           }
        
        audioService.playAnswerLockedSfx()
        stopGame()
        
        gameManager?.finishGameWithTimeout()
        
        //  Время вышло - показываем скорборд как поражение
        checkGameEnd(answerResult: .incorrect) // ответ не выбран
    }
    
    private func stopGameResources() {
        audioService.stop()
        timerService.stopTimer()
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
        
        // Сохраняем выбранный ответ — важно для подсветки
        correctAnswer = session.currentQuestion.correctAnswer
        selectedAnswer = answer
        
        // Делегируем обработку GameManager
        guard let answerResult = gameManager?.processAnswer(answer) else { return }
        
        // Устанавливаем состояние результата для анимации
        answerResultState = answerResult
        
        // Ждём анимации результата
        do {
            try await Task.sleep(for: .seconds(2))
            try Task.checkCancellation()
            
            // Теперь session уже обновлена через GameManager
            // Проверяем окончание игры
            if answerResult == .correct && !session.isFinished {
                // Подготовка к следующему вопросу
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
            timerService.stopTimer()
        } else {
            mode = .roundWon
            print(" Выигрыш: \(session.score) ")
            timerService.pauseTimer()
        }
        print(mode)
        // Делегируем навигацию родительскому компоненту
        onNavigateToScoreboard?(session, mode)
    }
    
    // MARK: - Help Button Actions
    func fiftyFiftyButtonTap() {
        
        guard let result = gameManager?.useFiftyFiftyLifeline() else { return }
        
        // Помечаем недоступные ответы
        disabledAnswers = result.disabledAnswers
    }
    
    func audienceButtonTap() {
        let visibleAnswers = answers.filter { !disabledAnswers.contains($0) }
        
        guard let result = gameManager?.useAudienceLifeline(allAnswers: visibleAnswers) else { return }
        
        var votes = Array(repeating: 0, count: 4)
        for (index, answer) in visibleAnswers.enumerated() {
            if let originalIndex = answers.firstIndex(of: answer) {
                votes[originalIndex] = result.votesPerAnswer[index]
            }
        }
        audienceVotes = votes
    }
    
    func secondChanceButtonTap() {
        guard gameManager?.useSecondChanceLifeline() != nil else { return }
    }
    
    func testScoreboard() {
        pauseGame()
        onNavigateToScoreboard?(session, .intermediate)
    }
}

private extension GameQuestion {
    var allAnswers: [String] {
        [correctAnswer] + incorrectAnswers
    }
}

extension GameViewModel {
    // MARK: - Game Control Methods
    
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
        
        timerService.resumeTimer()
        audioService.resume()
    }
    
    /// Полностью останавливает игру (при выходе)
    func stopGame() {
        stopGameResources()
        answerProcessingTask?.cancel()
        gameManager?.finishGameWithTimeout()
        storage.clearSavedSession()
    }
}
