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
    
    func continueGame() {
        gameManager?.checkGameState(.resumeGame)
        lastVisitedScreen = .game
        path = [.game]
    }
    
    func showScoreboard(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        // ✅ Всегда используем актуальную сессию из GameManager
        guard let actualSession = gameManager?.currentSession else {
            print("⚠️ No current session in GameManager!")
            return
        }
        print("🗺️ Navigation: showScoreboard")
        print("   Актуально из GM: \(actualSession.questions.count) вопросов, индекс: \(actualSession.currentQuestionIndex)")

        lastVisitedScreen = .scoreboard(actualSession, mode)
        path.append(.scoreboard(actualSession, mode))
    }
    
    func showGameOver(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        if case .gameOver = path.last {
            print("DEBUG: skip duplicate gameOver push")
            return
        }
        lastVisitedScreen = .gameOver(session, mode)
        path.append(.gameOver(session, mode))
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func popLast() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func handleScoreboardClose(mode: GameViewModel.ScoreboardMode, session: GameSession) {
        print("🗺️ Navigation: handleScoreboardClose, mode: \(mode)")
        print("🗺️ Path before: \(path.count) элементов")
        
        switch mode {
        case .intermediate:
            gameManager?.checkGameState(.resumeGame)
            popLast()
        case .roundWon:
            gameManager?.checkGameState(.nextRound)
            popLast()
        case .gameOver, .victoryMillionare:
            gameManager?.checkGameState(.stopGame)
            // При окончании игры - переходим к GameOverView
            // Удаляем экран игры из стека
            path.removeAll(where: { $0 == .game })
            // Всегда берем актуальную сессию
            guard let actualSession = gameManager?.currentSession else {
                print("⚠️ No current session, using provided")
                showGameOver(session, mode: mode)
                return
            }
            showGameOver(actualSession, mode: mode)
        }
    }
    
    // MARK: - GameOver Actions
    
    func startNewGameFromGameOver() {
        // Стартуем новую игру через HomeViewModel
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
            
        case .game:
            if let gameManager {
                GameScreen(gameManager: gameManager)
            }
            
        case .scoreboard(let session, let mode):
            ScoreboardView(
                session: session,
                mode: mode,
                onAction: { [weak self] in
                    // Логика withdrawal - забрать деньги и завершить игру
                    self?.homeViewModel?.withdrawAndEndGame()
                },
                onClose: { [weak self] in
                    //                    Логика переходов от ScoreboardView:
                    //                    .intermediate → возврат к игре
                    //                    .gameOver/.victory → переход к GameOverView
                    
                    // Возвращаемся назад - убираем скорборд из навигации
                    self?.handleScoreboardClose(mode: mode, session: session)
                }
            )
            
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
    
    func showGameOverAfterWithdrawal(_ session: GameSession) {
        //  Останавливаем игру
        gameManager?.checkGameState(.stopGame)
        
        //  Удаляем экран игры
        path.removeAll(where: { $0 == .game })
        // убираем .scoreboard
      
        //  Показываем GameOver
        path.append(.gameOver(session, .intermediate))
    }
}

// MARK: - Helper Extensions
private extension NavigationRoute {
    var isScoreboard: Bool {
        if case .scoreboard = self { return true }
        return false
    }
}
