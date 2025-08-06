//
//  TimerView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 26.07.2025.
//

import SwiftUI

struct TimerView: View {
    
    let timerType: TimerType
    let duration: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(.timer)
                .font(.system(size: 20, weight: .semibold))
            
            Text(duration)
                .millionaireTimerStyle(type: timerType)
        }
        .foregroundColor(timerType.color)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            timerType.color.opacity(0.2)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    TimerView(timerType: TimerType.normal, duration: "0:0")
}
