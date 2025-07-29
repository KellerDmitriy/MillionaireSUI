//
//  ScoreboardRowView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import SwiftUI

struct CategoryRowView: View {
    let index: Int
    let category: CategoryRowModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text("\(index):")
                .font(.millionaireMenuSubtitle)
                .foregroundStyle(.answerGradient3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(category.name)
                .font(.millionaireMenuSubtitle)
                .foregroundStyle(.answerGradient3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Image(category.categoryType.rawValue)
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
    }
}

#Preview {
    CategoryRowView(index: 1, category: .init(id: 1, name: "films", isCheckpoint: .random()), isSelected: true)
}
