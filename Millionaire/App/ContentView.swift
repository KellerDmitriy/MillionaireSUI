//
//  ContentView.swift
//  Millionaire
//
//  Created by Effin Leffin on 21.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showHome = false
    
    var body: some View {
        ZStack {
            if !showHome {
                LaunchScreen()
                    .preferredColorScheme(.dark)
                    .transition(.opacity)
            } else {
                    HomeView(gameManager: gameManager)
                        .preferredColorScheme(.dark)
                        .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showHome)
        .task {
            await startAppLoading()
        }
    }
    
    private func startAppLoading() async {
        // Имитируем загрузку данных (2 секунды)
        try? await Task.sleep(nanoseconds: 2_300_000_000)
        await MainActor.run {
            showHome = true
        }
    }
}
