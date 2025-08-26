//
//  GameRuntimeState.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 26.08.2025.
//
import Foundation

struct GameRuntimeState: Codable {
    let session: GameSession
    let remainingTime: Int
    let audioState: AudioState
}

struct AudioState: Codable {
    let resource: String?
    let currentTime: TimeInterval
    let isPlaying: Bool
}
