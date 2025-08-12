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
    
    // хранение активного ViewModel
    private var activeGameViewModel: GameViewModel?
    
    // MARK: - Setup
    func setup(gameManager: GameManager, homeViewModel: HomeViewModel) {
        self.gameManager = gameManager
        self.homeViewModel = homeViewModel
    }
    
    // MARK: - Game ViewModel Management
    
    private func cleanupGameViewModel() {
        print("🧹 Cleaning up GameViewModel")
        activeGameViewModel?.stopGame()  // Останавливаем таймер и аудио
        activeGameViewModel = nil
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
        activeGameViewModel = nil
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
        
        // При показе scoreboard приостанавливаем игру
        activeGameViewModel?.pauseGame()
        
        lastVisitedScreen = .scoreboard(actualSession, mode)
        path.append(.scoreboard(actualSession, mode))
    }
    
    func showGameOver(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        if case .gameOver = path.last {
            print("DEBUG: skip duplicate gameOver push")
            return
        }
        
        print("🎮 Showing GameOver, cleaning up game resources")
        
        // Останавливаем игровые ресурсы перед переходом
        cleanupGameViewModel()
        
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
        cleanupGameViewModel()  // Очищаем при возврате на главный
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
            activeGameViewModel?.resumeGame()  // Возобновляем игру
            
        case .roundWon:
            popLast()
            print("   Продолжаем игру после правильного ответа...")
            activeGameViewModel?.continueAfterScoreboard()
            
        case .gameOver, .victoryMillionare:
            // При окончании игры - переходим к GameOverView
            showGameOver(actualSession, mode: mode)
        }
    }
    
    // MARK: - Withdrawal Flow
    
    func handleWithdrawal() {
        print("💰 Withdrawal initiated")
        isWithdrawalInProgress = true
        
        // Останавливаем игровые ресурсы сразу
        activeGameViewModel?.pauseGame() // Сразу останавливаем таймер
        
        // Завершаем игру через HomeViewModel
        homeViewModel?.withdrawAndEndGame()
    }
    
    func showGameOverAfterWithdrawal(_ session: GameSession) {
        print("💰 Showing GameOver after withdrawal")
        isWithdrawalInProgress = true
        
        // Останавливаем игру полностью
        cleanupGameViewModel()
        
        // Убираем scoreboard из стека и показываем GameOver
        path.removeAll { route in
            if case .scoreboard = route { return true }
            return false
        }
        
        // Показываем GameOver с режимом intermediate (забрали деньги)
        path.append(.gameOver(session, .intermediate))
    }
    
    // MARK: - GameOver Actions
    
    func startNewGameFromGameOver() {
        // 1. Удаляем старый GameViewModel, чтобы создать новый
        cleanupGameViewModel()
        
        // 2. Стартуем новую игру через HomeViewModel
        homeViewModel?.startNewGameDirect()
    }
    
    func returnToMainScreenFromGameOver() {
        cleanupGameViewModel()
        // Просто возвращаемся на главный экран
        popToRoot()
    }
    
    /// Прямая замена текущего пути на LoadingView (без анимации через главный экран)
    func showLoadingDirect() {
        path = [.loading]
    }
    
    /// Прямая замена на игру (используется после прямой загрузки)
    func showGameDirect() {
        cleanupGameViewModel()
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
            gameScreenView()
            
        case .scoreboard(let session, let mode):
            ScoreboardView(
                session: session,
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
    
    @ViewBuilder
    private func gameScreenView() -> some View {
        if let existingViewModel = activeGameViewModel {
            GameScreen(viewModel: existingViewModel)
        } else {
            // Создаем ViewModel и сохраняем его
            GameScreen(viewModel: getOrCreateGameViewModel())
        }
    }
    
    // для создания и сохранения ViewModel
    private func getOrCreateGameViewModel() -> GameViewModel {
        if let existing = activeGameViewModel {
            return existing
        }
        
        let viewModel = createGameViewModel()
        activeGameViewModel = viewModel  // Присваивание вне ViewBuilder
        return viewModel
    }
    
    // MARK: - ViewModels Factory
    private func createGameViewModel() -> GameViewModel {
        guard let gameManager = gameManager else {
            preconditionFailure("GameManager is required for GameViewModel")
        }
        
        // Проверяем что есть активная сессия
        guard gameManager.currentSession != nil else {
            preconditionFailure("No active session in GameManager")
        }
        
        return GameViewModel(
            gameManager: gameManager,
            // GameViewModel не управляет навигацией
            // Вместо этого уведомляет родительский компонент
            onNavigateToScoreboard: { [weak self] session, mode in
                // Добавляем скорборд в навигацию
                self?.showScoreboard(session, mode: mode)
            },
        )
    }
    
}
