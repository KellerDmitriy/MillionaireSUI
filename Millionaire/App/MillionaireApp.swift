//
//  MillionaireApp.swift
//  Millionaire
//
//  Created by Effin Leffin on 21.07.2025.
//

import SwiftUI

@main
struct MillionaireApp: App {
    @StateObject private var gameManager = GameManager()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var isLoading: Bool = true
    
    func finishLoading() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isLoading = false
        }
    }
}
