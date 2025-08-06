//
//  ContentView.swift
//  Millionaire
//
//  Created by Effin Leffin on 21.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if appState.isLoading {
                LaunchScreen()
                    .transition(.opacity)
            } else {
                HomeView(gameManager: gameManager)
                    .preferredColorScheme(.dark)
                    .transition(.opacity)
            }
        }
        .task {
            await startAppLoading()
        }
    }
    
    private func startAppLoading() async {
        // Имитируем загрузку данных (2 секунды)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            appState.finishLoading()
        }
    }
}
