//
//  ScoreboardRow.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 24.07.2025.
//

import SwiftUI

struct ScoreboardRowView: View {
    let level: ScoreboardRow
    var isCompact: Bool = false
    @State private var isBlinking = false
    
    var body: some View {
        HStack {
            Text("\(level.number):")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(level.formattedAmount)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, isCompact ? 7 : 12)
        .background(
            Image(level.rowType.rawValue)
                .resizable()
        )
        .opacity(level.isCurrent ? (isBlinking ? 0.1 : 1.0) : 1.0)
        .frame(height: isCompact ? 34 : 44)
        .onAppear {
            if level.isCurrent {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isBlinking.toggle()
                }
            }
        }
        .onChange(of: level.isCurrent) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isBlinking = true
                }
            } else {
                isBlinking = false
            }
        }
    }
}

#Preview("Top") {
    ScoreboardRowView(
        level: .init(
            id: 15,
            number: 15,
            amount: 1000000,
            isCheckpoint: false,
            isCurrent: false,
            isTop: true
        )
    )
}

#Preview("Compact") {
    ScoreboardRowView(
        level: .init(
            id: 15,
            number: 15,
            amount: 1000000,
            isCheckpoint: false,
            isCurrent: false,
            isTop: true
        ),
        isCompact: true
        
    )
}
