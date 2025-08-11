//
//  ScoreboardViewModel.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 25.07.2025.
//

import Foundation

final class ScoreboardViewModel: ObservableObject {
    @Published var levels: [ScoreboardRow] = []
    
    private let prizeCalculator = PrizeCalculator()
    
    var gameSession: GameSession
    private let audioService: IAudioService
    
    /// Текущий приз игрока
    var currentPrize: Int {
        return prizeCalculator.getPrizeAmount(for: gameSession.currentQuestionIndex)
    }
    
    let mode: GameViewModel.ScoreboardMode
    
    private var highlightedQuestionNumber: Int {
        // Базовый человекочитаемый номер (индекс + 1)
        let base = gameSession.currentQuestionIndex + 1
        
        let number: Int = {
            switch mode {
            case .roundWon, .victoryMillionare:
                // Подсвечиваем только что пройденный уровень
                return base
            case .gameOver:
                // Подсвечиваем уровень, на котором ошиблись
                return base
            case .intermediate:
                // Во время игры можно захотеть подсветить «следующий»
                // Если твоя логика именно так и трактует — оставляем base
                // Если хотелось бы «текущий уже заданный», верни base без +1 в расчёте выше
                return base
            }
        }()
        
        // На всякий случай ограничим диапазон 1...15 (или твой максимум)
        return min(max(number, 1), 15)
    }
    
    init(gameSession: GameSession,
         mode: GameViewModel.ScoreboardMode,
         audioService: IAudioService = AudioService.shared) {
        self.gameSession = gameSession
        self.mode = mode
        self.audioService = audioService
    }
    
    func updateLevels(mode: GameViewModel.ScoreboardMode) {
        let prizes = prizeCalculator.getAllPrizes().reversed()
        self.levels = prizes.map { prize in
            ScoreboardRow(
                id: prize.questionNumber,
                number: prize.questionNumber,
                amount: prize.amount,
                isCheckpoint: prize.isCheckpoint,
                isCurrent: prize.questionNumber == highlightedQuestionNumber,
                isWrongAnswer: mode == .gameOver,
                isTop: prize.questionNumber == prizeCalculator.getAllPrizes().count
            )
        }
    }
    
    func playSound(mode: GameViewModel.ScoreboardMode) {
        switch mode {
        case .intermediate:
            audioService.pause()
        case .roundWon:
            audioService.playCorrectAnswerSfx()
        case .gameOver:
            audioService.playWrongAnswerSfx()
        case .victoryMillionare:
            audioService.playVictorySfx()
        }
    }
    
    func takeMoney() {
        print("take money")
    }
    
    func deinitAudioService() {
        audioService.stop()
    }
}
