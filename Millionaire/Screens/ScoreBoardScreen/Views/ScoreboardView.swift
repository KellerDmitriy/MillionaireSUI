//
//  ScoreboardView.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 24.07.2025.
//

import SwiftUI

struct ScoreboardView: View {
    @ObservedObject var viewModel: ScoreboardViewModel
    let mode: GameViewModel.ScoreboardMode
    let onAction: () -> Void
    let onClose: () -> Void
    
    @State private var showWithdrawalAlert = false
    @State private var showGameOverZeroAlert = false
    
    
    init(session: GameSession,
         mode: GameViewModel.ScoreboardMode = .intermediate,
         onAction: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.viewModel = ScoreboardViewModel(gameSession: session)
        self.mode = mode
        self.onAction = onAction
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            // Background
            Image("Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                        // Логотип
                        Image("ScoreboardScreenLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 85, height: 85)
                            
                            .padding(.top, 40)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        // Таблица уровней
                        ForEach(viewModel.levels) { level in
                            ScoreboardRowView(level: level)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
                    .padding(.bottom, 50)
                    
                    Spacer()
                }
            }
            .blur(radius: showWithdrawalAlert ? 5 : 0)
            .blur(radius: showGameOverZeroAlert ? 5 : 0)
            // Alert Overlay
            if showWithdrawalAlert {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showWithdrawalAlert = false
                    }

                CustomAlertView(
                    message: "Are you sure you want to claim a prize of $\(viewModel.gameSession.score)?",
                    onDismiss: {
                       
                        showWithdrawalAlert = false
                    },
                    showSecondButton: true,
                    secondButtonAction: {
                        viewModel.takeMoney()
                        onAction()
                        showWithdrawalAlert = false
                    }
                )
                .frame(width: 300, height: 400)
                .cornerRadius(20)
                .zIndex(2)
            }
            if showGameOverZeroAlert {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()

                            CustomAlertView(
                                message: "You lost. Your prize is $0.",
                                onDismiss: {
                                    showGameOverZeroAlert = false
                                    viewModel.deinitAudioService()
                                    onClose()
                                },
                                showSecondButton: false
                            )
                            .frame(width: 280, height: 300)
                            .cornerRadius(20)
                            .zIndex(3)
                        }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .onAppear {
                    viewModel.playSound(mode: mode)
                    if mode == .gameOver && viewModel.currentPrize < 5000 {
                        Task {
                            try await Task.sleep(for: .seconds(1))
                            withAnimation {
                                showGameOverZeroAlert = true
                            }
                        }
                    }
                }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if mode == .intermediate && !viewModel.gameSession.isFinished {
                    Button(action: { showWithdrawalAlert = true }) {
                        Image("IconWithdrawal")
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.deinitAudioService()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview("Intermediate") {
    let questions = (1...15).map { i in
        Question(
            difficulty: .easy,
            category: "Общие знания",
            question: "Вопрос?",
            correctAnswer: "A",
            incorrectAnswers: ["B", "C", "D"]
        )
    }
    let session = GameSession(questions: questions, currentQuestionIndex: 10, score: 15000)!
    
    ScoreboardView(
        session: session,
        mode: .intermediate,
        onAction: {
            print("Withdrawal action")
        },
        onClose: {
            print("Close action")
        }
    )
}

#Preview("Game Over") {
    let questions = (1...15).map { i in
        Question(
            difficulty: .easy,
            category: "Общие знания",
            question: "Вопрос?",
            correctAnswer: "A",
            incorrectAnswers: ["B", "C", "D"]
        )
    }
    let session = GameSession(questions: questions, currentQuestionIndex: 5, score: 5000)!
    
    ScoreboardView(
        session: session,
        mode: .gameOver,
        onAction: {
            print("No action in game over")
        },
        onClose: {
            print("Close action")
        }
    )
}

#Preview("Victory") {
    NavigationView {
        let questions = (1...15).map { i in
            Question(
                difficulty: .easy,
                category: "Общие знания",
                question: "Вопрос?",
                correctAnswer: "A",
                incorrectAnswers: ["B", "C", "D"]
            )
        }
        let session = GameSession(questions: questions, currentQuestionIndex: 5, score: 5000)!
        
        ScoreboardView(
            session: session,
            mode: .victory,
            onAction: {
                print("No action in game over")
            },
            onClose: {
                print("Close action")
            }
        )
    }
}
