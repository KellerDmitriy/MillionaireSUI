//
//  LaunchScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 06.08.2025.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    var body: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            Image(.homeScreenLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 250)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 2
                        opacity = 1.0
                    }
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchScreen()
}
