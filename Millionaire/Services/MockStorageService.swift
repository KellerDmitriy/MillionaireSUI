//
//  MockStorageService.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 12.08.25.
//

// MARK: - Mock Storage for Testing
#if DEBUG
class MockStorageService: IStorageService {

    
    private var sessionData: GameRuntimeState?
    
    private var bestScore: Int = 0
    private var statistics = GameStatistics()
    private var soundEnabled = true
    private var selectedCategory: Int?
    
    
    func saveGameRuntimeState(_ state: GameRuntimeState) {
        sessionData = state
    }
    func loadGameSession() -> GameRuntimeState? {
        return sessionData
    }
    
    func clearSavedSession() {
        sessionData = nil
    }
    
    func saveBestScore(_ score: Int) {
        if score > bestScore {
            bestScore = score
        }
    }
    
    func loadBestScore() -> Int {
        return bestScore
    }
    
    func saveStatistics(_ stats: GameStatistics) {
        statistics = stats
    }
    
    func loadStatistics() -> GameStatistics {
        return statistics
    }
    
    func saveSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }
    
    func loadSoundEnabled() -> Bool {
        return soundEnabled
    }
    
    func saveSelectedCategory(_ categoryId: Int?) {
        selectedCategory = categoryId
    }
    
    func loadSelectedCategory() -> Int? {
        return selectedCategory
    }
    
    func clearAllData() {
        sessionData = nil
        bestScore = 0
        statistics = GameStatistics()
        soundEnabled = true
        selectedCategory = nil
    }
}
#endif
