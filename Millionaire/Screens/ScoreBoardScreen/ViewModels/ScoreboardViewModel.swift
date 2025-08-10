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
    
    private var highlightedQuestionNumber: Int {
        if !gameSession.isFinished {
            return gameSession.currentQuestionIndex
        } else {
            return gameSession.currentQuestionIndex + 1
        }
    }
    
    init(gameSession: GameSession, audioService: IAudioService = AudioService.shared) {
        self.gameSession = gameSession
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
