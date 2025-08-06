//
//  AudienceHelpView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 31.07.2025.
//

import SwiftUI

struct AudienceHelpView: View {
    let votesPerAnswer: [Int]
    @State private var animateGraphs = false
    
    private let letters = AnswerLetter.allCases
    
    var action: () -> Void
    
    var maxAnswerIndex: Int {
        votesPerAnswer.enumerated()
            .max(by: { $0.element < $1.element })?
            .offset ?? 0
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("The audience has voted!")
                .millionaireCategoryTitleStyle()
            Spacer()
            HStack(alignment: .bottom, spacing: 20) {
                ForEach(votesPerAnswer.indices, id: \.self) { index in
                    BarView(
                        letter: letters[index].rawValue,
                        percentage: votesPerAnswer[index],
                        index: index,
                        animated: animateGraphs,
                        isMax: index == maxAnswerIndex
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            gameButton(title: "Ok", variant: .primary) {
                action()
            }
            .frame(height: 34)
            .padding()
        }
        .padding()
        .background(Image(.background))
        .cornerRadius(30)
        .basicShadow()
        .onAppear {
            animateGraphs = true
        }
    }
    
    // MARK: - UI Components
    @ViewBuilder
    private func gameButton(title: String,
                            variant: ButtonVariant,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
        }
        .millionaireStyle(variant)
        .frame(maxWidth: .infinity)
    }
}

private struct BarView: View {
    let letter: String
    let percentage: Int
    let index: Int
    let animated: Bool
    let isMax: Bool
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isMax ? .wrongAnswer2 : .wrongAnswer1)
                .frame(
                    width: 40,
                    height: animated ? CGFloat(percentage * 2) : 0
                )
                .animation(
                    .spring(duration: 0.7, bounce: 0.3)
                        .delay(0.02 * Double(index)),
                    value: animated
                )
            
            Text(letter)
                .millionaireCategoryTitleStyle()
            
            Text("\(percentage)%")
                .millionaireCategoryTitleStyle()
        }
    }
}

#Preview {
    AudienceHelpView(votesPerAnswer: [80, 70, 10, 5], action: {})
        .padding()
}
