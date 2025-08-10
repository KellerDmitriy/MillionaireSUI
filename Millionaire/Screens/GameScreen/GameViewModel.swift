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
final class GameViewModel: ObservableObject {
    
    // MARK: - Services
    
    private let timerService: ITimerService
    private let audioService: IAudioService
    private let storage: IStorageService
    
    private var cancellables = Set<AnyCancellable>()
    
    private let prizeCalculator = PrizeCalculator()
    
    /// Обработчик изменения состояния игры
    private let onSessionUpdated: (GameSession) -> Void
    
    /// Обработчик перехода к скорборду
    private let onNavigateToScoreboard: ((GameSession, ScoreboardMode) -> Void)?
    
    @Published private var session: GameSession {
        didSet {
            // Сообщаем обработчику об изменении состояния игры
            onSessionUpdated(session)
        }
    }
    
    /// Массив вариантов ответа в порядке их отображения
    @Published private(set) var answers: [String] {
        didSet {
            // Очищаем недоступные варианты при смене ответов (а значит и вопроса)
            disabledAnswers = []
        }
    }
    
    /// Недоступные для выбора варианты ответов
    @Published private(set) var disabledAnswers: Set<String> = []
    
    @Published var correctAnswer: String?
    
    @Published var duration: String = "00:00"
    
    // Доп состояния для UI
    @Published private(set) var timerType: TimerType = .normal
    
    /// хранение версий от помощи зала в процентах
    @Published var audienceVotes: [Int]?
    
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
    
    // MARK: Init
    init(
        initialSession: GameSession,
        onSessionUpdated: @escaping (GameSession) -> Void = { _ in },
        onNavigateToScoreboard: ((GameSession, ScoreboardMode) -> Void)? = nil,
        audioService: IAudioService = AudioService.shared,
        storage: IStorageService = StorageService.shared,
        timerService: ITimerService = TimerService()
    ) {
        self.session = initialSession
        self.onSessionUpdated = onSessionUpdated
        self.audioService = audioService
        self.storage = storage
        self.timerService = timerService
        self.onNavigateToScoreboard = onNavigateToScoreboard
        
        answers = initialSession.currentQuestion.allAnswers.shuffled()
        
        bindTimer()
    }
    
    // MARK: - Game Start
    func startGame() {
        // Стартуем только если нет выбранного ответа
        guard selectedAnswer == nil else { return }
        
        audioService.playGameSfx()
        timerService.start30SecondTimer { [weak self] in
            self?.onTimeExpired()
        }
        print("category: \(String(describing: session.getCurrentCategory()?.name))")
        print("difficulty: \(session.currentQuestion.difficulty)")
        print("correctAnswer: \(session.currentQuestion.correctAnswer)")
    }
    
    private func onTimeExpired() {
        audioService.playAnswerLockedSfx()
        stopGame()
        
        var newSession = session
        let checkpoint = prizeCalculator.getCheckpointPrizeAmount(before: newSession.currentQuestionIndex)
        newSession.setScore(checkpoint)
        newSession.finish()
        session = newSession
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
        var newSession = session
        
        // Сохраняем индекс текущего вопроса ДО обработки
        let currentQuestionIndex = session.currentQuestionIndex
        
        // Сохраняем выбранный ответ — важно для подсветки
        selectedAnswer = answer
        correctAnswer = newSession.currentQuestion.correctAnswer
        
        // Обрабатываем ответ — получаем результат, но не начисляем тут ничего
        guard let answerResult = newSession.answer(answer: answer) else {
            return
        }
        
        // Начисляем призы используя PrizeCalculator
        switch answerResult {
        case .correct:
            let prize = prizeCalculator.getPrizeAmount(for: currentQuestionIndex)
            newSession.setScore(prize)
        case .incorrect:
            let checkpoint = prizeCalculator.getCheckpointPrizeAmount(before: currentQuestionIndex)
            newSession.setScore(checkpoint)
            answerResultState = .incorrect
        }
        
        // НЕ обновляем сессию сразу!
        // session = newSession
        
        // Устанавливаем состояние результата для анимации
        answerResultState = answerResult == .incorrect ? .incorrect : .correct
        
        // Ждём анимации результата
        do {
            try await Task.sleep(for: .seconds(2))
            try Task.checkCancellation()
            
            // ТЕПЕРЬ обновляем сессию
            session = newSession
            
            // Проверяем окончание игры
            if answerResult == .correct && !session.isFinished {
                // Подготовка следующего вопрос
                selectedAnswer = nil  // <-- переносим сюда
                answerResultState = nil
                correctAnswer = nil
                answers = session.currentQuestion.allAnswers.shuffled()
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
        onNavigateToScoreboard?(session, mode)
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
        session.finish()
        storage.clearSavedSession()
    }
}
