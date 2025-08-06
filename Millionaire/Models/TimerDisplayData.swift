//
//  TimerDisplayData.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 06.08.2025.
//

import SwiftUI

struct TimerDisplayData {
    let formattedTime: String
    let type: TimerType
}

enum TimerType {
    case normal, warning, critical
    
    var color: Color {
        switch self {
        case .normal: return .white
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    static func getType(for secondsLeft: Int) -> TimerType {
           switch secondsLeft {
           case 16...30: return .normal      // 30 до 16 сек
           case 6...15: return .warning      // 15 до 6 сек
           default: return .critical         // 5 сек и меньше
           }
       }
}
