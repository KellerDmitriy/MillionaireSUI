//
//  LoadingView.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 26.07.25.
//
import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Getting ready...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .navigationBarBackButtonHidden(true) // Скрываем кнопку назад
    }
}
