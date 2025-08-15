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
    
    private enum Drawing {
        // Screen
        static let compactScreenHeight: CGFloat = 650
        static let blurRadius: CGFloat = 5
        
        // Logo
        static let logoImageName = "ScoreboardScreenLogo"
        static let logoDefaultSize: CGFloat = 85
        static let logoCompactSize: CGFloat = 60
        static let logoDefaultOffsetY: CGFloat = 20
        static let logoCompactOffsetY: CGFloat = 10
        
        // Levels list
        static let levelsHorizontalPadding: CGFloat = 30
        static let logoOffsetY: CGFloat = -30
        
        // Overlay
        static let overlayOpacity: CGFloat = 0.5
        
        // Timing
        static let alertDismissDelay: UInt64 = 1_000_000_000
        static let lowPrizeThreshold: Int = 5000
        
        // Toolbar icons
        static let withdrawalIconName = "IconWithdrawal"
        static let withdrawalIconSize: CGFloat = 44
    }
    
    init(session: GameSession,
         audioService: IAudioService,
         mode: GameViewModel.ScoreboardMode = .intermediate,
         onAction: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.viewModel = ScoreboardViewModel(
            gameSession: session,
            audioService: audioService
        )
        self.mode = mode
        self.onAction = onAction
        self.onClose = onClose
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let isCompact = screenHeight < Drawing.compactScreenHeight
            
            ZStack {
                // Background
                AnimatedGradientBackgroundView()
                
                VStack(spacing: 0) {
                    // Логотип
                    logoView(isCompact)
                    // уровни
                    levelList(isCompact)
                    Spacer()
                }
                .offset(y: Drawing.logoOffsetY)
                .blur(radius: showWithdrawalAlert || showGameOverZeroAlert ? 5 : 0)
                
                // Alert Overlay
                if showWithdrawalAlert {
                    withdrawalAlert
                }
                
                if showGameOverZeroAlert {
                    gameOverZeroAlert
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        
        .navigationBarBackButtonHidden()
        .onAppear {
            viewModel.updateLevels(mode: mode)
        }
        .task {
            await handleAudioAndAutoClose()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                toolbarLeading
            }
        }
    }
    
    // MARK: Helpers Methods
    private func handleAudioAndAutoClose() async {
        viewModel.playSound(mode: mode)
        
        if mode == .gameOver && viewModel.currentPrize < Drawing.lowPrizeThreshold {
            try? await Task.sleep(for: .seconds(1))
            withAnimation {
                showGameOverZeroAlert = true
            }
        }
        
        try? await Task.sleep(for: .seconds(4))
        if !showGameOverZeroAlert && !showWithdrawalAlert && mode != .intermediate {
            viewModel.deinitAudioService()
            onClose()
        }
    }
}

// MARK: Extension ScoreboardView
private extension ScoreboardView {
    
    func logoView(_ isCompact: Bool) -> some View {
        Image(Drawing.logoImageName)
            .resizable()
            .scaledToFit()
            .frame(
                width: isCompact ? Drawing.logoCompactSize : Drawing.logoDefaultSize,
                height: isCompact ? Drawing.logoCompactSize : Drawing.logoDefaultSize
            )
            .offset(y: isCompact ? Drawing.logoCompactOffsetY : Drawing.logoDefaultOffsetY)
            .zIndex(1)
    }
    
    func levelList(_ isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            // Таблица уровней
            ForEach(viewModel.levels) { level in
                ScoreboardRowView(
                    level: level,
                    isCompact: isCompact
                )
            }
        }
        .padding(.horizontal, Drawing.levelsHorizontalPadding)
    }
    
    var withdrawalAlert: some View {
        ZStack {
            Color.black.opacity(Drawing.overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { showWithdrawalAlert = false }
            
            CustomAlertView(
                message: "Are you sure you want to claim a prize of $\(viewModel.gameSession.score)?",
                onDismiss: {
                    showWithdrawalAlert = false
                    Task {
                        try? await Task.sleep(nanoseconds: Drawing.alertDismissDelay)
                        viewModel.deinitAudioService()
                        onClose()
                    }
                },
                showSecondButton: true,
                secondButtonAction: {
                    Task {
                        try? await Task.sleep(nanoseconds: Drawing.alertDismissDelay)
                        showWithdrawalAlert = false
                        viewModel.deinitAudioService()
                        onAction()
                    }
                }
            )
            .zIndex(2)
        }
    }
    
    var gameOverZeroAlert: some View {
        ZStack {
            Color.black.opacity(Drawing.overlayOpacity).ignoresSafeArea()
            
            CustomAlertView(
                message: "You lost. Your prize is $0.",
                onDismiss: {
                    withAnimation {
                        showGameOverZeroAlert = false
                        viewModel.deinitAudioService()
                        onClose()
                    }
                },
                showSecondButton: false
            )
            .zIndex(3)
        }
    }
    
    var toolbarLeading: some View {
        Group {
            if mode == .roundWon && !viewModel.gameSession.isFinished {
                Button(
                    action: {
                        showWithdrawalAlert = true
                    },
                    label: {
                        Image(Drawing.withdrawalIconName)
                            .resizable()
                            .frame(
                                width: Drawing.withdrawalIconSize,
                                height: Drawing.withdrawalIconSize
                            )
                    }
                )
            } else if mode == .intermediate {
                BackBarButtonView(onBack: {
                    onClose()
                })
            }
        }
    }
}

#Preview("Intermediate") {
    let questions = (1...15).map { index in
        QuestionDTO(
            difficulty: .easy,
            category: "Общие знания",
            question: "Вопрос \(index)?",
            correctAnswer: "A",
            incorrectAnswers: ["B", "C", "D"]
        )
    }
    
    guard let session = GameSession(questions: questions) else {
        return Text("Invalid session")
    }
    
    return ScoreboardView(
        session: session,
        audioService: AudioService(),
        mode: .intermediate,
        onAction: { print("Withdrawal action") },
        onClose: { print("Close action") }
    )
}

#Preview("Game Over") {
    let questions = (1...15).map { index in
        QuestionDTO(
            difficulty: .easy,
            category: "Общие знания",
            question: "Вопрос \(index)?",
            correctAnswer: "A",
            incorrectAnswers: ["B", "C", "D"]
        )
    }
    guard let session = GameSession(questions: questions) else {
        return Text("Invalid session")
    }
    
    return ScoreboardView(
        session: session,
        audioService: AudioService(),
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
    let questions = (1...15).map { index in
        QuestionDTO(
            difficulty: .easy,
            category: "Общие знания",
            question: "Вопрос \(index)?",
            correctAnswer: "A",
            incorrectAnswers: ["B", "C", "D"]
        )
    }
    
    guard let session = GameSession(questions: questions) else {
        return AnyView(Text("Invalid session"))
    }
    
    return AnyView(
        NavigationView {
            ScoreboardView(
                session: session,
                audioService: AudioService(),
                mode: .roundWon,
                onAction: {
                    print("No action in game over")
                },
                onClose: {
                    print("Close action")
                }
            )
        }
    )
}
