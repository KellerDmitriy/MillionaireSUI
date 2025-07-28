//
//  GameOverView.swift
//  Millionaire
//
//  Created by Александр Пеньков on 22.07.2025.
//

import SwiftUI

/// Экран завершения игры (Game Over).
///
/// Классическая представительная вью без собственного состояния.
/// Отображает итоговые данные текущей игровой сессии:
/// - уровень, на котором завершилась игра
/// - финальный счёт в валюте
///
/// Особенности:
/// - Не содержит бизнес-логики
/// - Не изменяет своё состояние (только `let` свойства)
/// - Выполняет две простые навигационные команды: «Новая игра» и «На главный экран»

struct GameOverView: View {
    // MARK: - Properties
    
    /// Текущая игровая сессия — источник финальных данных
    let session: GameSession
    
    /// Доп режим отображения экрана (например, поражение, победа и пр.)
    let mode: GameViewModel.ScoreboardMode
    
    let onNewGame: () -> Void
    let onMainScreen: () -> Void
    
    var body: some View {
        ZStack {
            backgroundImage
            
            VStack(spacing: 0) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, -80)
                
                VStack(spacing: 8) {
                    Text("Game Over!")
                        .foregroundStyle(.white)
                        .font(Font.custom("SF Compact Display", size: 32))
                        .fontWeight(.semibold)
                    
                    Text("level \(session.currentQuestionIndex + 1)")
                        .foregroundStyle(.white.opacity(0.6))
                        .font(Font.custom("SF Compact Display", size: 16))
                        .fontWeight(.regular)
                    HStack() {
                        Text("$\(session.score.formatted())")
                            .foregroundStyle(.white)
                            .font(Font.custom("SF Compact Display", size: 24))
                            .fontWeight(.semibold)
                        Image(.coin)
                    }
                }
                .padding(.top, -100)
                
                Spacer()
                
                VStack(spacing: 46) {
                    Button.millionaire("New game", variant: .primary) {
                        onNewGame()
                    }
                    .padding(.top, 40)
                    Button("Main screen") {
                        onMainScreen()
                    }
                    .millionaireStyle(.regular)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    @ViewBuilder
    private var backgroundImage: some View {
        Image("Background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .ignoresSafeArea(.all)
    }
}

#Preview {
    GameOverView(
        session: GameSession(
            questions: Array(repeating: Question(
                difficulty: .easy,
                category: "Test",
                question: "Test?",
                correctAnswer: "A",
                incorrectAnswers: ["B", "C", "D"]
            ), count: 15),
            currentQuestionIndex: 7,
            score: 15000
        )!,
        mode: .gameOver,
        onNewGame: { print("New game") },
        onMainScreen: { print("Main screen") }
    )
}
