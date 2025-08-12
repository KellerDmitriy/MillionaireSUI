//
//  HomeViewModel.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 25.07.25.
//

import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var viewMode: HomeViewMode = .firstStart
    @Published var bestScore: Int = 0
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Dependencies
    private var gameManager: GameManager
    private let navigationCoordinator: NavigationCoordinator
    
    // MARK: - Computed Properties
    var hasActiveGame: Bool {
        gameManager.currentSession?.isFinished == false
    }
    
    // MARK: - Init
    init(gameManager: GameManager,
         navigationCoordinator: NavigationCoordinator) {
        self.gameManager = gameManager
        self.navigationCoordinator = navigationCoordinator
        
        //        // Попытка восстановить сессию из стораджа, если в менеджере нет активной
        //        if gameManager.currentSession == nil,
        //           let savedSession = storage.loadGameSession(),
        //           savedSession.isFinished == false {
        //            gameManager.restoreSession(savedSession)
        //        }
        
        updateViewState()
        
        // Устанавливаем связь с координатором
        navigationCoordinator.setup(gameManager: gameManager, homeViewModel: self)
    }
    
    func onNavigationChange(_ path: [NavigationRoute]) {
        if path.isEmpty && navigationCoordinator.lastVisitedScreen != .categories {
            // Вернулись на главный экран
            updateViewState()
        }
    }
    
    func startNewGame() {
        Task {
            await startGame(type: .new)
        }
    }
    
    func startNewGameDirect() {
        Task {
            await startGameDirect()
        }
    }
    
    func continueGame() {
        Task {
            await startGame(type: .continued)
        }
    }
    
    func showSettings() {
        navigationCoordinator.showCategories()
    }
    
    // MARK: - Private Methods
    private func updateViewState() {
        let hasActive = gameManager.currentSession?.isFinished == false
        let hasScore = gameManager.bestScore > 0
        
        self.viewMode = HomeViewMode(
            hasActiveSession: hasActive,
            hasScore: hasScore
        )
        self.bestScore = gameManager.bestScore
        
        print("📊 HomeViewModel state updated:")
        print("   - View mode: \(viewMode)")
        print("   - Best score: \(bestScore)")
        print("   - Has active game: \(hasActive)")
    }
    
    private func startGame(type: GameType) async {
        switch type {
        case .new:
            await startNewGameFlow()
            
        case .continued:
            continueExistingGame()
        }
    }
    
    func startNewGameFlow() async {
        navigationCoordinator.showLoading()
        isLoading = true
        
        do {
            try await gameManager.startNewGame()
            try? await Task.sleep(nanoseconds: 500_000_000)
            navigationCoordinator.showGame()
        } catch {
            navigationCoordinator.popToRoot()
            errorMessage = "Failed to load questions. Please check your internet connection."
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Direct Game Start (from GameOver)
    private func startGameDirect() async {
        // Прямой переход без возврата на главный экран
        navigationCoordinator.showLoadingDirect()
        isLoading = true
        
        do {
            _ = try await gameManager.startNewGame()
            
            // Небольшая задержка для UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Прямая замена на игру
            navigationCoordinator.showGameDirect()
        } catch {
            // При ошибке возвращаемся на главный
            navigationCoordinator.popToRoot()
            errorMessage = "Failed to load questions. Please check your internet connection."
            showError = true
        }
        
        isLoading = false
    }
    
    private func continueExistingGame() {
        guard let session = gameManager.currentSession, !session.isFinished else {
            errorMessage = "No active game to continue"
            showError = true
            return
        }
        
        navigationCoordinator.showGame()
    }
    
    // MARK: - Public Methods for External Updates
    
    /// Вызывается после завершения игры для обновления UI
    func refreshAfterGameEnd() {
        updateViewState()
    }
    
    /// Вызывается при возврате из настроек
    func refreshAfterSettings() {
        updateViewState()
    }
    
}

// MARK: - Debug Extension
#if DEBUG
extension HomeViewModel {
    func debugPrintState() {
        print("🔍 HomeViewModel Debug State:")
        print("   - bestScore (local): \(bestScore)")
        print("   - bestScore (gameManager): \(gameManager.bestScore)")
        print("   - viewMode: \(viewMode)")
        print("   - hasActiveGame: \(hasActiveGame)")
        print("   - currentSession: \(gameManager.currentSession != nil ? "exists" : "nil")")
    }
}
#endif

extension HomeViewModel {
    
    // MARK: - Withdrawal
    func withdrawAndEndGame() {
        print("💰 HomeViewModel: Processing withdrawal")
        
        // Завершаем текущую сессию с текущим счетом
        if let session = gameManager.currentSession {
            let finalScore = session.score
            print("   Final score: $\(finalScore)")
            
            // Завершаем игру
            gameManager.endGame(withScore: finalScore)
            
            // Обновляем UI состояние
            updateViewState()
            
            // НЕ вызываем навигацию здесь!
            // Пусть NavigationCoordinator сам управляет переходом
        }
    }
}
