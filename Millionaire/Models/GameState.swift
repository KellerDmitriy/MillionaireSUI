//
//  GameState.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 15.08.2025.
//

import SwiftUI

enum GameState: Hashable, Equatable {
    /// Первый вход на экран игры (новая сессия)
    case startGame
    /// Возврат в игру после паузы (из скорборда или из другой вкладки)
    case resumeGame
    /// Продолжение игры автоматически (новый вопрос после завершения предыдущего)
    case nextRound
    /// Пауза (при уходе с экрана)
    case pause
    case stopGame
}
