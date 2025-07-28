//
//  BackBarButtonView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 26.07.2025.
//

import SwiftUI

struct BackBarButtonView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    var foregroundStyle: Color = Color.white
    let onBack: (() -> Void)?
    
    init(foregroundStyle: Color = .white, onBack: (() -> Void)? = nil) {
        self.foregroundStyle = foregroundStyle
        self.onBack = onBack
    }
    
    // MARK: - Drawing Constants
    private struct Drawing {
        static let iconSize: CGFloat = 24
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            onBack?()  // Вызываем коллбек перед dismiss
            dismiss()
        }) {
            Image(systemName: "arrow.left")
                .resizable()
                .scaledToFit()
                .frame(width: Drawing.iconSize, height: Drawing.iconSize)
                .foregroundStyle(foregroundStyle)
        }
    }

}
