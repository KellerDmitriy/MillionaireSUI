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
    case game(GameSession)
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
    
    func showGame(_ session: GameSession) {
        lastVisitedScreen = .game(session)
        path = [.game(session)]
    }
    
    func showScoreboard(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
        // ✅ Всегда используем актуальную сессию из GameManager
        guard let actualSession = gameManager?.currentSession else {
            print("⚠️ No current session in GameManager!")
            return
        }
        print("🗺️ Navigation: showScoreboard")
        print("   Переданная session устарела, игнорируем её")
        print("   Актуально из GM: \(actualSession.questions.count) вопросов, индекс: \(actualSession.currentQuestionIndex)")

        lastVisitedScreen = .scoreboard(actualSession, mode)
        path.append(.scoreboard(actualSession, mode))
        
        print("🗺️ Navigation path: \(path.map { "\($0)" }.joined(separator: " → "))")

    }
    
    func showGameOver(_ session: GameSession, mode: GameViewModel.ScoreboardMode) {
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
        case .intermediate, .roundWon
            :
            // Получаем актуальную сессию из GameManager
            // Не просто popLast, а обновляем route
            if let currentSession = gameManager?.currentSession {
                // Удаляем скорборд
                path.removeLast()
            print("🗺️ Path after: \(path.count) элементов")
                // Проблема: При замене route .game(currentSession) SwiftUI пересоздает View и ViewModel!
                // Заменяем game route на актуальный
//                if !path.isEmpty {
//                    path[path.count - 1] = .game(currentSession)
//                }
            }
            
        case .gameOver, .victoryMillionare:
            // При окончании игры - переходим к GameOverView
            showGameOver(session, mode: mode)
        }
    }
    
    // MARK: - GameOver Actions
    
    func startNewGameFromGameOver() {
        // Специальный метод для прямого перехода к новой игре
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
    func showGameDirect(_ session: GameSession) {
        path = [.game(session)]
    }
    
    // хранение активного ViewModel
    private var activeGameViewModel: GameViewModel?
    
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
            
        case .game(let session):
            GameScreen(
                viewModel: createGameViewModel(for: session)
            )
            
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
    
    // MARK: - ViewModels Factory
    private func createGameViewModel(for session: GameSession) -> GameViewModel {
        guard let gameManager = gameManager else {
                preconditionFailure("GameManager is required for GameViewModel")
            }
        
        return GameViewModel(
            initialSession: session,
            gameManager: gameManager,
            onGameFinished: { [weak self] in
                // Возвращаемся на главный экран
                self?.popToRoot()
            },
            // GameViewModel не управляет навигацией
            // Вместо этого уведомляет родительский компонент
            onNavigateToScoreboard: { [weak self] session, mode in
                // Добавляем скорборд в навигацию
                self?.showScoreboard(session, mode: mode)
            },
        )
    }
    
    func showGameOverAfterWithdrawal(_ session: GameSession) {
        // Показываем GameOver с режимом intermediate (забрали деньги)
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
