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
    
    init(gameSession: GameSession, audioService: IAudioService = AudioService.shared) {
        self.gameSession = gameSession
        self.audioService = audioService
        updateLevels()
    }
    
    func updateLevels() {
        let prizes = prizeCalculator.getAllPrizes().reversed()
        self.levels = prizes.map { prize in
            ScoreboardRow(
                id: prize.questionNumber,
                number: prize.questionNumber,
                amount: prize.amount,
                isCheckpoint: prize.isCheckpoint,
                isCurrent: prize.questionNumber == gameSession.currentQuestionIndex,
                isTop: prize.questionNumber == 15
            )
        }
    }
    
    func playSound(mode: GameViewModel.ScoreboardMode) {
        switch mode {
        case .intermediate:
            audioService.playCorrectAnswerSfx()
        case .victory:
            audioService.playCorrectAnswerSfx()
        case .gameOver:
            audioService.playWrongAnswerSfx()
        }
    }
    
    func takeMoney() {
        print("take money")
    }
    
    func deinitAudioService() {
        audioService.stop()
    }
}
