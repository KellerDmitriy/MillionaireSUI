//
//  GameScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 22.07.2025.
//

import SwiftUI

struct GameScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showCustomAlert = false
    @State private var alertMessage = ""
    
    //    MARK: Init
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            
            VStack {
                timerView()
                    .padding(.top, 20)
                
                questionTextView()
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                
                answerButtons()
                    .padding(.vertical, 20)
                helpButtons()
            }
            .allowsHitTesting(viewModel.selectedAnswer == nil)
            .padding(20)
        }
        .blur(radius: showCustomAlert ? 5 : 0)
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.resumeGame()
            case .inactive, .background:
                viewModel.pauseGame()
            @unknown default:
                break
            }
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
                    .frame(width: 350, height: 500)
                    .cornerRadius(20)
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
                    }
                )
            }
            
            ToolbarItem(placement: .principal) {
                navTitle()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    //viewModel.navigationPath.append(.scoreboard(session: viewModel.currentSession,
                    //                                            mode: .gameOver))
                    viewModel.testScoreboard()
                }) {
                    Image(ImageResource.iconLevels)
                }
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
                .font(.headline)
                .foregroundStyle(.white)
                .bold()
            Spacer()
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
                    alertMessage = "Аудитория выбрала:\n\(viewModel.answersForAudienceLifeline ?? "")"
                    withAnimation {
                        showCustomAlert = true
                    }
                }
            )
            .disabled(!viewModel.lifelines.contains(.audience))
            
            HelpButton(
                type: .callToFriend,
                action: {
                    viewModel.callYourFriendButtonTap()
                    alertMessage = "You have the right to make one mistake."
                    withAnimation {
                        showCustomAlert = true
                    }
                }
            )
            .disabled(!viewModel.lifelines.contains(.callToFriend))
        }
    }
    
    private func buttonState(for answer: String) -> MillionaireAnswerButtonStyle.AnswerState {
        guard let selected = viewModel.selectedAnswer else {
            return .regular
        }
        
        // Если выбранный ответ был неправильным, но подсказка активирована
        if selected == answer {
            if viewModel.mistakeAllowedUsed {
                return .wrong // Показываем, что он неправильный, но игра продолжается
            }

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

// MARK: - Preview
#Preview {
    NavigationStack {
        GameScreen(
            viewModel: GameViewModel(
                initialSession: GameSession(
                    questions: Array(
                        repeating: Question(difficulty: .easy, category: "aaa", question: "Как дела?", correctAnswer: "Хорошо", incorrectAnswers: Array(repeating: "Плохо", count: 3)),
                        count: 15
                    )
                )!
            )
        )
    }
}
