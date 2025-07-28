//
//  Lifeline.swift
//  Millionaire
//
//  Created by Effin Leffin on 23.07.2025.
//

import Foundation

/// Перечисление с подсказками
enum Lifeline: Codable, Hashable {
    // 50:50
    case fiftyFifty
    // Помощь зала
    case audience
    // Звонок другу
    case callToFriend
}
