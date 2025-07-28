//
//  PrizeCalculator.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 24.07.25.
//

// Часть логики ScoreLogic
// не взаимодействует с GameSession напрямую
// Взаимодействие с GameSession должно происходить через GameManager/GameEngine

struct PrizeCalculator {
    let prizeStructure: PrizeStructure
    
    init(prizeStructure: PrizeStructure = .standard) {
        self.prizeStructure = prizeStructure
    }
    
    // MARK: - Public API (все внешние вызовы только через эти методы)
    
    /// Получить приз за конкретный вопрос
    func getPrize(for questionIndex: Int) -> Prize? {
        return prizeStructure.getPrize(for: questionIndex)
    }
    
    /// Получить сумму за вопрос
    func getPrizeAmount(for questionIndex: Int) -> Int {
        return getPrize(for: questionIndex)?.amount ?? 0
    }
    
    /// Получить несгораемую сумму при проигрыше
    func getCheckpointPrizeAmount(before questionIndex: Int) -> Int {
        return prizeStructure.getCheckpointPrize(before: questionIndex)?.amount ?? 0
    }
    
    /// Получить следующий приз
    func getNextPrize(after questionIndex: Int) -> Prize? {
        return prizeStructure.getPrize(for: questionIndex + 1)
    }
    
    /// Проверить, является ли текущий вопрос checkpoint
    func isCheckpoint(questionIndex: Int) -> Bool {
        return getPrize(for: questionIndex)?.isCheckpoint ?? false
    }
    
    /// Получить все призы для отображения лестницы
    func getAllPrizes() -> [Prize] {
        return prizeStructure.prizes
    }
    
}
