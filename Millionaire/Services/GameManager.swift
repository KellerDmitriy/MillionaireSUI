//
//  GameManager.swift
//  Millionaire
//
//  Created by Effin Leffin on 24.07.2025.
//

import Foundation

/// Менеджер, хранящий  глобальное состояние (сессия, bestScore)

@MainActor
final class GameManager: ObservableObject {  // Управляет сессиями
    private let networkService: NetworkService
    
    /// Лучший результат, если он есть
    private(set) var bestScore: Int
    
    /// Модель последней игры, если она есть
    @Published private(set) var currentSession: GameSession?
    
    func updateSession(_ session: GameSession) {
        self.currentSession = session
    }
    
    init(
        networkService: NetworkService = .shared,
        bestScore: Int = 0,
        lastSession: GameSession? = nil
    ) {
        self.networkService = networkService
        
        // TODO: Добавить чтение начальных значений из UserDefaults?
        self.bestScore = bestScore
        self.currentSession = lastSession
    }
    
    /// Начинает новую игру
    func startNewGame() async throws -> GameSession {
        let questions = try await networkService.fetchQuestions(from: QuestionsAPI.baseURL)
        
        guard let initialSession = GameSession(questions: questions) else {
            throw StartGameFailure.invalidQuestions
        }
        
        self.currentSession = initialSession
        
        return initialSession
    }
    
    /// Восстанавливает сохранённую сессию
    func restoreSession(_ session: GameSession) {
        Task {
            await MainActor.run { [weak self] in
                self?.currentSession = session
            }
        }
    }
    
    /// Актуализирует лучший результат при изменении сессии
    private func updateBestScoreIfNeeded() {
        // Результат применяем только для завершенной игры
        guard let currentSession, currentSession.isFinished else {
            return
        }
        
        // Сохраним результат, если он оказался больше ранее сохраненного
        bestScore = max(bestScore, currentSession.score)
    }
}

private extension GameManager {
    enum StartGameFailure: Error {
        case invalidQuestions
    }
}

extension GameManager {
    func endGame(withScore score: Int) {
        // Завершаем текущую сессию
        //currentSession?.isFinished = true
        
        // Обновляем лучший результат если нужно
        if score > bestScore {
            bestScore = score
            // Сохраняем в UserDefaults
            // UserDefaults.standard.set(bestScore, forKey: "bestScore")
        }
        
        // Очищаем текущую сессию
        currentSession = nil
    }
}
