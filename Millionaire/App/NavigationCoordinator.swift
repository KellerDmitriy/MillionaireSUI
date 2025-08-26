//
//  NavigationCoordinator.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 26.07.25.
//

import SwiftUI

//
// Поток навигации:
//
// HomeView
//    ├── LoadingView
//    ├── GameScreen
//    │   └── ScoreboardView (через toolbar button)
//    │       ├── [intermediate] → назад к GameScreen
//    │       └── [gameOver/victory] → GameOverView
//    └── GameOverView
//        ├── New Game → HomeView → LoadingView → GameScreen
//        └── Main Screen → HomeView

// MARK: - Navigation Routes
enum NavigationRoute: Hashable {
    case loading
    case categories
    case game
    case scoreboard(GameSession, GameViewModel.ScoreboardMode)
    case gameOver(GameSession, GameViewModel.ScoreboardMode)
}

// MARK: - Navigation Coordinator
@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path: [NavigationRoute] = []
    private(set) var lastVisitedScreen: NavigationRoute?
    
    // Dependencies
    private weak var gameManager: GameManager?
    private weak var homeViewModel: HomeViewModel?
    // Флаг для отслеживания withdrawal
    private var isWithdrawalInProgress = false
    
    // MARK: - Setup
    func setup(gameManager: GameManager, homeViewModel: HomeViewModel) {
        self.gameManager = gameManager
        self.homeViewModel = homeViewModel
    }
    
    // MARK: - Navigation Methods
    
    func showLoading() {
        path = [.loading]
    }
    
    func showCategories() {
        lastVisitedScreen = .categories
        path.append(.categories)
    }
    
    func showGame() {
        gameManager?.checkGameState(.startGame)
        lastVisitedScreen = .game
        path = [.game]
    }
    
    func nextRoundGame() {
        gameManager?.checkGameState(.nextRound)
        lastVisitedScreen = .game
        path = [.game]
    }
    
    func continueGame() {
        gameManager?.checkGameState(.resumeGame)
        lastVisitedScreen = .game
        path = [.game]
    }
    
    func showScoreboard(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        // Всегда используем актуальную сессию из GameManager
        guard let actualSession = gameManager?.currentSession else {
            print("⚠️ No current session in GameManager!")
            return
        }
        print("🗺️ Navigation: showScoreboard")
        
        path.removeAll(where: { $0 == .game })
        lastVisitedScreen = .scoreboard(actualSession, mode)
        path.append(.scoreboard(actualSession, mode))
    }
    
    func showGameOver(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        if case .gameOver = path.last {
            print("DEBUG: skip duplicate gameOver push")
            return
        }
        
        print("🎮 Showing GameOver, cleaning up game resources")
        
        // Удаляем ScoreboardView из стека если она там есть
        path.removeAll { route in
            if case .scoreboard = route { return true }
            return false
        }
        
        lastVisitedScreen = .gameOver(session, mode)
        path.append(.gameOver(session, mode))
        print("🎮 Showing GameOver, path count: \(path.count)")
    }
    
    func popToRoot() {
        path.removeAll()
        isWithdrawalInProgress = false
    }
    
    func popLast() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func handleScoreboardClose(mode: GameViewModel.ScoreboardMode, session: GameSession) {
        print("🗺️ Navigation: handleScoreboardClose, mode: \(mode)")
        print("   isWithdrawalInProgress: \(isWithdrawalInProgress)")
        
        // Получаем актуальную сессию
        let actualSession = gameManager?.currentSession ?? session
        print("   actualSession.isFinished: \(actualSession.isFinished)")
        
        // Если был withdrawal, игра уже завершена - переходим к GameOver
        if isWithdrawalInProgress || actualSession.isFinished {
            isWithdrawalInProgress = false
            // Получаем актуальную сессию с финальным счетом
            showGameOver(actualSession, mode: isWithdrawalInProgress ? .intermediate : mode)
            return
        }
        
        switch mode {
        case .intermediate:
            popLast()
            continueGame()
        case .roundWon:
            print("   Продолжаем игру после правильного ответа...")
            nextRoundGame()
        case .gameOver, .victoryMillionare:
            // При окончании игры - переходим к GameOverView
            showGameOver(actualSession, mode: mode)
        }
    }
    
    // MARK: - Withdrawal Flow
    
    func handleWithdrawal() {
        print("💰 Withdrawal initiated")
        isWithdrawalInProgress = true
        // Завершаем игру через HomeViewModel
        homeViewModel?.withdrawAndEndGame()
    }
    
    
    // MARK: - GameOver Actions
    
    func startNewGameFromGameOver() {
        //  Стартуем новую игру через HomeViewModel
        homeViewModel?.startNewGameDirect()
    }
    
    func returnToMainScreenFromGameOver() {
        // Просто возвращаемся на главный экран
        popToRoot()
    }
    
    /// Прямая замена текущего пути на LoadingView (без анимации через главный экран)
    func showLoadingDirect() {
        path = [.loading]
    }
    
    /// Прямая замена на игру (используется после прямой загрузки)
    func showGameDirect() {
        path = [.game]
    }
    
    // MARK: - View Factory
    @ViewBuilder
    func destinationView(for route: NavigationRoute) -> some View {
        
        switch route {
        case .loading:
            LoadingView()
                .navigationBarBackButtonHidden(true)
            
        case .categories:
            if let gameManager {
                CategoriesScreen(gameManager: gameManager)
            }
            
        case .game: // session больше не используется
            if let gameManager {
                GameScreen(
                    gameManager:
                            gameManager,
                    audioService: gameManager.audio,
                    timerService: gameManager.timer
                )
            }
            
        case .scoreboard(let session, let mode):
            if let gameManager {
                ScoreboardView(
                    session: session,
                    audioService: gameManager.audio,
                    mode: mode,
                    onAction: { [weak self] in
                        // Логика withdrawal - забрать деньги и завершить игру
                        self?.handleWithdrawal()
                    },
                    onClose: { [weak self] in
                        //                    Логика переходов от ScoreboardView:
                        //                    .intermediate → возврат к игре
                        //                    .gameOver/.victory → переход к GameOverView
                        
                        // Возвращаемся назад - убираем скорборд из навигации
                        self?.handleScoreboardClose(mode: mode, session: session)
                    }
                )
            }
        case .gameOver(let session, let mode):
            //            Обработка действий из GameOverView:
            //            "New Game" → очистка навигации и запуск новой игры
            //            "Main Screen" → очистка навигации и возврат на главный
            GameOverView(
                session: session,
                mode: mode,
                onNewGame: { [weak self] in
                    // Очищаем навигацию и начинаем новую игру
                    self?.startNewGameFromGameOver()
                },
                onMainScreen: { [weak self] in
                    // Возвращаемся на главный экран
                    self?.returnToMainScreenFromGameOver()
                }
            )
            
        }
    }
}
