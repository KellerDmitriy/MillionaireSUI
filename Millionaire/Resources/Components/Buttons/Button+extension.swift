//
//  Button+extension.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 07.08.25.
//

import SwiftUI

// MARK: - Convenience Extensions

extension Button {
    
    /// Применяет стиль кнопки миллионера с изображениями
    func millionaireStyle(_ variant: MillionaireButtonStyle.Variant = .primary) -> some View {
        self.buttonStyle(MillionaireButtonStyle(variant: variant))
    }
    
    /// Применяет стиль кнопки ответа
    /// - Parameters:
    ///   - state: Состояние ответа (обычный/правильный/неправильный)
    func millionaireAnswerStyle(_ state: MillionaireAnswerButtonStyle.AnswerState = .regular
    ) -> some View {
        self.buttonStyle(MillionaireAnswerButtonStyle(state: state))
    }
}

// MARK: - Factory Methods

extension Button where Label == Text {
    /// Создает обычную кнопку миллионера с текстом
    static func millionaire(
        _ title: String,
        variant: MillionaireButtonStyle.Variant = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .millionaireStyle(variant)
    }
}

extension Button where Label == MillionaireAnswerLabel {
    /// Создает кнопку ответа для игры
    static func millionaireAnswer(
        letter: String,
        text: String,
        state: MillionaireAnswerButtonStyle.AnswerState = .regular,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            MillionaireAnswerLabel(letter: letter, text: text)
        }
        .millionaireAnswerStyle(state)
    }
}
