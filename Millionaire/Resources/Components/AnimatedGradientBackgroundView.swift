//
//  AnimatedGradientBackgroundView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 25.07.2025.
//


import SwiftUI

struct AnimatedGradientBackgroundView: View {
    @State private var animate = false

    private let gradientSet1 = [
        Color(.answerGradient1),
        Color(.backgroundGradientTop),
        Color(.wrongAnswer1),
        Color(.answerGradient1)
    ]
    
    private let gradientSet2 = [
        Color(.answerGradient2),
        Color(.buttonGradientColorLight),
        Color(.current3),
        Color(.answerGradient4)
    ]
    
    var body: some View {
        LinearGradient(
            colors: animate ? gradientSet1 : gradientSet2,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 6.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
