
//
//  ScoreboardRow.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 24.07.2025.
//


import SwiftUI

struct ScoreboardRowView: View {
    let level: ScoreboardRow

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
        .padding(.vertical, 8)
        .background(
            Image(level.rowType.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .clipShape(MillionaireShape())
        .overlay(
            MillionaireShape()
                .stroke(Color.white, lineWidth: 3)
        )
        .padding(.vertical, 2)
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
