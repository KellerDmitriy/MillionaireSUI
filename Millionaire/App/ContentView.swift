//
//  ContentView.swift
//  Millionaire
//
//  Created by Effin Leffin on 21.07.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    var body: some View {
        HomeView(gameManager: gameManager)
            .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
}
