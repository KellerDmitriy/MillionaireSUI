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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
        }
    }
}
