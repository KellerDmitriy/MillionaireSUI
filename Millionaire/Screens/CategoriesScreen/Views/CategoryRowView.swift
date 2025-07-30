//
//  ScoreboardRowView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import SwiftUI

struct CategoryRowView: View {
    let index: Int
    let category: QuestionCategory
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text("\(index):")
                .millionaireCategoryTitleStyle()
                .padding(.horizontal, 25)
            Text(category.displayName)
                .millionaireCategoryTitleStyle()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 4)
            Spacer()
        }
        .frame(height: 44)
        .padding(.vertical, 0)
        .background(
            Image(isSelected ? "Current" : "Regular")
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
    }
}

#Preview {
    CategoryRowView(index: 1, category: .init(id: 1, name: "films"), isSelected: false)
}
