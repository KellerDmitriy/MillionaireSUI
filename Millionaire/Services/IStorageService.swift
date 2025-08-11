//
//  StorageManagerProtocol.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 27.07.2025.
//

import Foundation

// MARK: - StorageManagerProtocol
protocol IStorageService {
    // Game Session
    func saveGameSession(_ session: GameSession)
    func loadGameSession() -> GameSession?
    func clearSavedSession()
    
    // Best Score
    func saveBestScore(_ score: Int)
    func loadBestScore() -> Int
    
    // Statistics
    func saveStatistics(_ stats: GameStatistics)
    func loadStatistics() -> GameStatistics
    
    // Settings
    func saveSoundEnabled(_ enabled: Bool)
    func loadSoundEnabled() -> Bool
    
    // Selected Category
    func saveSelectedCategory(_ categoryId: Int?)
    func loadSelectedCategory() -> Int?
    
    // Clear all data
    func clearAllData()
}

// MARK: - StorageManager
final class StorageService: IStorageService {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard
    
    // Keys
    private enum Keys {
        static let savedGameSession = "SavedGameSession"
        static let bestScore = "BestScore"
        static let statistics = "GameStatistics"
        static let soundEnabled = "SoundEnabled"
        static let selectedCategory = "SelectedCategoryID"
        static let totalGamesPlayed = "TotalGamesPlayed"
    }
    
    private init() {
    }
    
    func saveGameSession(_ session: GameSession) {
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: Keys.savedGameSession)
            print(" Game session saved successfully")
        } catch {
            print(" Failed to save session: \(error)")
        }
    }
    
    func loadGameSession() -> GameSession? {
        guard let data = defaults.data(forKey: Keys.savedGameSession) else {
            print(" No saved game session found")
            return nil
        }
        
        do {
            let session = try JSONDecoder().decode(GameSession.self, from: data)
            print(" Game session loaded successfully")
            return session
        } catch {
            print(" Failed to load session: \(error)")
            // Clear corrupted data
            clearSavedSession()
            return nil
        }
    }
    
    func clearSavedSession() {
        defaults.removeObject(forKey: Keys.savedGameSession)
        print(" Saved session cleared")
    }
    
    // MARK: - Best Score
    func saveBestScore(_ score: Int) {
        let currentBest = loadBestScore()
        if score > currentBest {
            defaults.set(score, forKey: Keys.bestScore)
            print(" New best score saved: \(score)")
        }
    }
    
    func loadBestScore() -> Int {
        return defaults.integer(forKey: Keys.bestScore)
    }
    
    // MARK: - Statistics
    func saveStatistics(_ stats: GameStatistics) {
        do {
            let data = try JSONEncoder().encode(stats)
            defaults.set(data, forKey: Keys.statistics)
            print(" Statistics saved")
        } catch {
            print(" Failed to save statistics: \(error)")
        }
    }
    
    func loadStatistics() -> GameStatistics {
        guard let data = defaults.data(forKey: Keys.statistics) else {
            return GameStatistics()
        }
        
        do {
            return try JSONDecoder().decode(GameStatistics.self, from: data)
        } catch {
            print(" Failed to load statistics: \(error)")
            return GameStatistics()
        }
    }
    
    // MARK: - Settings
    func saveSoundEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.soundEnabled)
    }
    
    func loadSoundEnabled() -> Bool {
        // Default to true if not set
        if defaults.object(forKey: Keys.soundEnabled) == nil {
            return true
        }
        return defaults.bool(forKey: Keys.soundEnabled)
    }
    
    // MARK: - Selected Category
    func saveSelectedCategory(_ categoryId: Int?) {
        if let id = categoryId {
            defaults.set(id, forKey: Keys.selectedCategory)
        } else {
            defaults.removeObject(forKey: Keys.selectedCategory)
        }
    }
    
    func loadSelectedCategory() -> Int? {
        if defaults.object(forKey: Keys.selectedCategory) != nil {
            return defaults.integer(forKey: Keys.selectedCategory)
        }
        return nil
    }
    
    // MARK: - Helper Methods
    func incrementGamesPlayed() {
        let current = defaults.integer(forKey: Keys.totalGamesPlayed)
        defaults.set(current + 1, forKey: Keys.totalGamesPlayed)
    }
    
    // MARK: - Clear All Data
    func clearAllData() {
        let keys = [Keys.savedGameSession, Keys.bestScore, Keys.statistics,
                    Keys.soundEnabled, Keys.selectedCategory, Keys.totalGamesPlayed]
        keys.forEach { defaults.removeObject(forKey: $0) }
        print(" All storage data cleared")
    }
    
    // MARK: - Debug Methods
#if DEBUG
    func printStorageState() {
        print("📱 Storage State:")
        print("  - Has saved session: \(loadGameSession() != nil)")
        print("  - Best score: \(loadBestScore())")
        print("  - Sound enabled: \(loadSoundEnabled())")
        print("  - Selected category: \(loadSelectedCategory() ?? -1)")
        let stats = loadStatistics()
        print("  - Games played: \(stats.totalGamesPlayed)")
        print("  - Games won: \(stats.gamesWon)")
        print("  - Average question reached: \(stats.averageQuestionReached)")
    }
#endif
}
