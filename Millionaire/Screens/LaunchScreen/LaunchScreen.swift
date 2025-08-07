//
//  LaunchScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 06.08.2025.
//

import SwiftUI

struct LaunchScreen: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            Image(.homeScreenLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 350)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        scale = 1.5
                        opacity = 1
                    }
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LaunchScreen()
}



