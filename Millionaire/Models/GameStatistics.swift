//
//  GameStatistics.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 12.08.25.
//

struct GameStatistics: Codable {
    var totalGamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalWinnings: Int = 0
    var averageQuestionReached: Double = 0
    var lifelinesUsed: [String: Int] = [:]
    var bestStreak: Int = 0
    
    mutating func recordGame(
        questionsAnswered: Int,
        winnings: Int,
        won: Bool,
        lifelinesUsed: Set<Lifeline>
    ) {
        totalGamesPlayed += 1
        if won { gamesWon += 1 }
        totalWinnings += winnings
        
        // Update average
        let total = averageQuestionReached * Double(totalGamesPlayed - 1) + Double(questionsAnswered)
        averageQuestionReached = total / Double(totalGamesPlayed)
        
        // Update lifelines usage
        for lifeline in lifelinesUsed {
            let key = String(describing: lifeline)
            self.lifelinesUsed[key, default: 0] += 1
        }
    }
}
