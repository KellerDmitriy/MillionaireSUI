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
    private let storage: IStorageService
    private var gameManager: GameManager
    private let navigationCoordinator: NavigationCoordinator
    
    // MARK: - Computed Properties
    var hasActiveGame: Bool {
        gameManager.currentSession?.isFinished == false
    }
    
    // MARK: - Init
    init(gameManager: GameManager,
         storage: IStorageService = StorageService.shared,
         navigationCoordinator: NavigationCoordinator) {
        self.gameManager = gameManager
        self.storage = storage
        self.navigationCoordinator = navigationCoordinator
        
        // Попытка восстановить сессию из стораджа, если в менеджере нет активной
        if gameManager.currentSession == nil,
           let savedSession = storage.loadGameSession(),
           savedSession.isFinished == false {
            gameManager.restoreSession(savedSession)
        }
        
        updateViewState()
        
        // Устанавливаем связь с координатором
        navigationCoordinator.setup(gameManager: gameManager, homeViewModel: self)
    }
    
    func onNavigationChange(_ path: [NavigationRoute]) {
        if path.isEmpty {
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
    
    // MARK: - Withdrawal
    func withdrawAndEndGame() {
        // Завершаем текущую сессию с текущим счетом
        if let session = gameManager.currentSession {
            gameManager.endGame(withScore: session.score)
            
            // Переходим к GameOver, а не на главный экран
            navigationCoordinator.showGameOverAfterWithdrawal(session)
        }
    
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
    }
    
    private func startGame(type: GameType) async {
        switch type {
        case .new:
            await startNewGameFlow()
            
        case .continued:
            continueExistingGame()
        }
    }
    
    private func startNewGameFlow() async {
        
        // Показываем загрузку
        navigationCoordinator.showLoading()
        isLoading = true
        
        do {
            let session = try await gameManager.startNewGame()
            
            // Небольшая задержка для UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Переходим к игре
            navigationCoordinator.showGame(session)
        } catch {
            // Обработка ошибки
            navigationCoordinator.popToRoot()
            errorMessage = "Не удалось загрузить вопросы. Проверьте интернет-соединение."
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
            let session = try await gameManager.startNewGame()
            
            // Небольшая задержка для UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Прямая замена на игру
            navigationCoordinator.showGameDirect(session)
        } catch {
            // При ошибке возвращаемся на главный
            navigationCoordinator.popToRoot()
            errorMessage = "Не удалось загрузить вопросы. Проверьте интернет-соединение."
            showError = true
        }
        
        isLoading = false
    }
    
    private func continueExistingGame() {
        guard let session = gameManager.currentSession, !session.isFinished else {
            errorMessage = "Нет активной игры для продолжения"
            showError = true
            return
        }
        
        navigationCoordinator.showGame(session)
    }
    
}
