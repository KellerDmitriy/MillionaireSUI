//
//  ScoreboardRowType.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 25.07.2025.
//

import Foundation

enum ScoreboardRowType: String {
    case current = "Current"
    case top = "Top"
    case checkpoint = "Safe"
    case regular = "Regular"
}

struct ScoreboardRow: Identifiable {
    let id: Int
    let number: Int
    let amount: Int
    let isCheckpoint: Bool
    let isCurrent: Bool
    let isTop: Bool
    
    var formattedAmount: String {
        "$\(amount.formatted(.number.grouping(.automatic)))"
    }
    
    var rowType: ScoreboardRowType {
        switch true {
        case isCurrent: return .current
        case isTop: return .top
        case isCheckpoint: return .checkpoint
        default: return .regular
        }
    }
}
