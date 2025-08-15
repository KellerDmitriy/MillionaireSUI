//
//  GameScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 22.07.2025.
//

import SwiftUI

struct GameScreen: View {
    @StateObject var viewModel: GameViewModel
    
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showCustomAlert = false
    @State private var alertMessage = ""
    
    @State private var showAudienceHelpView = false
    
    // MARK: Init
    init(gameManager: GameManager, audioService: IAudioService, timerService: ITimerService) {
        self._viewModel = StateObject(wrappedValue: GameViewModel(
            gameManager: gameManager,
            audioService: audioService,
            timerService: timerService
        )
        )
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            
            VStack(spacing: 0) {
                timerView()
                    .padding(.top, 4)
                Spacer()
                questionTextView()
                    .padding(.bottom, 4)
                Spacer()
                answerButtons()
                    .padding(.vertical, 20)
                helpButtons()
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .allowsHitTesting(viewModel.selectedAnswer == nil)
        }
        .blur(radius: showCustomAlert || showAudienceHelpView ? 5 : 0)
        
        .onAppear {
            viewModel.setNavigation(navigation)
        }
        .task {
            await viewModel.handleGameStateOnAppear()
        }
        
        .onDisappear {
            showCustomAlert = false
            showAudienceHelpView = false
        }
        
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .overlay(
            Group {
                if showCustomAlert {
                    CustomAlertView(message: alertMessage ) {
                        withAnimation(.easeInOut) {
                            showCustomAlert = false
                        }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    .zIndex(2)
                }
            }
        )
        
        .overlay(
            Group {
                if showAudienceHelpView, let votes = viewModel.audienceVotes {
                    AudienceHelpView(votesPerAnswer: votes) {
                        withAnimation { showAudienceHelpView = false }
                    }
                    .frame(width: 320, height: 450)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    .zIndex(2)
                }
            }
        )
        .overlay(
            Group {
                if viewModel.showError {
                    CustomAlertView(message: viewModel.errorMessage ) {
                        withAnimation(.easeInOut) {
                            viewModel.showError = false
                        }
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    .zIndex(2)
                }
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackBarButtonView(
                    onBack: {
                        // Дополнительная логика перед возвратом
                        viewModel.pauseGame()
                        navigation.popToRoot()
                    }
                )
            }
            
            ToolbarItem(placement: .principal) {
                navTitle()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.routeToScoreboardWithIntermediate()
                }, label: {
                    Image(ImageResource.iconLevels)
                })
            }
        }
    }
    
    // MARK: - NavTitle
    private func navTitle() -> some View {
        HStack {
            VStack {
                Text("QUESTION #\(viewModel.numberQuestion)")
                    .fontWeight(.ultraLight)
                
                Text("$\(viewModel.priceQuestion)")
                    .millionaireTitleStyle()
            }
        }
    }
    
    // MARK: - Timer View
    private func timerView() -> some View {
        TimerView(
            timerType: viewModel.timerType,
            duration: viewModel.duration
        )
        .frame(width: 150, height: 80)
    }
    
    // MARK: - Question View
    private func questionTextView() -> some View {
        VStack {
            Text(viewModel.question.question)
                .millionaireQuestionStyle()
                .lineLimit(5)
                .allowsTightening(true)
        }
    }
    
    // MARK: - Answer Buttons
    private func answerButtons() -> some View {
        VStack(spacing: 20) {
            ForEach(Array(zip(AnswerLetter.allCases, viewModel.answers)), id: \.0) { letter, answer in
                Button.millionaireAnswer(
                    letter: letter.rawValue,
                    text: answer,
                    state: buttonState(for: answer)
                ) {
                    viewModel.onAnswer(answer)
                }
                .disabled(
                    viewModel.selectedAnswer == answer ||
                    viewModel.disabledAnswers.contains(answer)
                )
            }
        }
    }
    
    // MARK: - Help Buttons
    private func helpButtons() -> some View {
        HStack(spacing: 20) {
            HelpButton(
                type: .fiftyFifty,
                action: viewModel.fiftyFiftyButtonTap
            )
            .disabled(!viewModel.lifelines.contains(.fiftyFifty))
            
            HelpButton(
                type: .audience,
                action: {
                    viewModel.audienceButtonTap()
                    withAnimation {
                        showAudienceHelpView = true
                    }
                }
            )
            .disabled(!viewModel.lifelines.contains(.audience))
            
            HelpButton(
                type: .secondChance,
                action: {
                    viewModel.secondChanceButtonTap()
                    alertMessage = "You have the right to make one mistake."
                    withAnimation {
                        showCustomAlert = true
                    }
                }
            )
            .disabled(!viewModel.lifelines.contains(.secondChance))
        }
    }
    
    private func buttonState(for answer: String) -> MillionaireAnswerButtonStyle.AnswerState {
        guard let selected = viewModel.selectedAnswer else {
            return .regular
        }
        
        // Если выбранный ответ был неправильным, но подсказка активирована
        if selected == answer {
            
            switch viewModel.answerResultState {
            case .correct:
                return .correct
            case .incorrect:
                return .wrong
            case .none:
                return .regular
            }
        }
        
        if viewModel.answerResultState == .incorrect,
           answer == viewModel.correctAnswer {
            return .correct
        }
        
        return .regular
    }
    
}

// Создаем расширение для удобства
extension GameSession {
    static func makeForPreview(
        atQuestion: Int = 0,
        withScore: Int = 0,
        lifelines: Set<Lifeline> = [.fiftyFifty, .audience, .secondChance]
    ) -> GameSession? {
        let questions = (0..<15).map { index in
            QuestionDTO(
                difficulty: index < 5 ? .easy : index < 10 ? .medium : .hard,
                category: "Preview Category",
                question: "Question \(index + 1): What is the answer?",
                correctAnswer: "Correct",
                incorrectAnswers: ["Wrong A", "Wrong B", "Wrong C"]
            )
        }
        
        guard var session = GameSession(questions: questions) else { return nil }
        
        // Продвигаемся до нужного вопроса
        for _ in 0..<atQuestion {
            _ = session.answer(answer: session.currentQuestion.correctAnswer)
        }
        
        session.setScore(withScore)
        
        //        // Настраиваем подсказки
        //        let allLifelines: Set<Lifeline> = [.fiftyFifty, .audience, .secondChance]
        //        for used in allLifelines.subtracting(lifelines) {
        //            session.useLifeline(used)
        //        }
        
        return session
    }
}

// Тогда Preview становится проще:
#Preview("Game - Mid Game") {
    if let session = GameSession.makeForPreview(
        atQuestion: 7 ,
        withScore: 10000,
        lifelines: [.audience]
    ) {
        let gameManager = GameManager(bestScore: 50000, lastSession: session)
        
        NavigationStack {
            GameScreen(gameManager: gameManager, audioService: AudioService(), timerService: TimerService())
        }
    } else {
        Text("Preview failed")
    }
}
