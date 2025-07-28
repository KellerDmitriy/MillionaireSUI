//
//  FontExtensions.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 23.07.25.
//

import Foundation
import SwiftUI

// MARK: - Font Extensions for Millionaire Game

extension Font {
    
    // MARK: - Answer Button Fonts
    
    /// Шрифт для буквы ответа (A:, B:, C:, D:)
    /// SF Compact Display, 18pt, Bold
    static let millionaireAnswerLetter = Font.custom("SF Compact Display", size: 18)
    
    /// Шрифт для текста ответа
    /// SF Compact Display, 18pt, Medium
    static let millionaireAnswerText = Font.custom("SF Compact Display", size: 18)
    
    // MARK: - Game Interface Fonts
    
    /// Основной заголовок игры
    /// SF Compact Display, 28pt, Bold
    static let millionaireTitle = Font.custom("SF Compact Display", size: 28)
    
    /// Текст вопроса
    /// SF Compact Display, 20pt, SemiBold
    static let millionaireQuestion = Font.custom("SF Compact Display", size: 20)
    
    /// Обычный текст интерфейса
    /// SF Compact Display, 18pt, Medium
    static let millionaireBody = Font.custom("SF Compact Display", size: 18)
    
    /// Мелкий текст (таймер, призовые суммы)
    /// SF Compact Display, 14pt, Medium
    static let millionaireCaption = Font.custom("SF Compact Display", size: 14)
    
    // MARK: - Menu Fonts
    
    /// Кнопки главного меню
    /// SF Compact Display, 24pt, Bold
    static let millionaireMenuButton = Font.custom("SF Compact Display", size: 24)
    
    /// Подзаголовки в меню
    /// SF Compact Display, 16pt, SemiBold
    static let millionaireMenuSubtitle = Font.custom("SF Compact Display", size: 16)
}

// MARK: - Text Extensions with Font Weights

extension Text {
    
    // MARK: - Answer Button Text Styles
    
    /// Применяет стиль для буквы ответа (желтый, жирный)
    func millionaireAnswerLetterStyle() -> some View {
        self
            .font(.millionaireAnswerLetter)
            .fontWeight(.semibold)
            .foregroundColor(.yellow)
    }
    
    /// Применяет стиль для текста ответа (белый, средний)
    func millionaireAnswerTextStyle() -> some View {
        self
            .font(.millionaireAnswerText)
            .fontWeight(.semibold)
            .foregroundColor(.white)
    }
    
    // MARK: - Game Interface Text Styles
    
    /// Стиль для заголовка игры
    func millionaireTitleStyle() -> some View {
        self
            .font(.millionaireTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    /// Стиль для текста вопроса
    func millionaireQuestionStyle() -> some View {
        self
            .font(.millionaireQuestion)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }
    
    /// Стиль для таймера
    func millionaireTimerStyle(type: TimerType) -> some View {
        self
            .font(.millionaireBody)
            .fontWeight(.bold)
            .foregroundColor(type.color)
    }
    
    /// Стиль для призовых сумм
    func millionairePrizeStyle(isActive: Bool = false) -> some View {
        self
            .font(.millionaireCaption)
            .fontWeight(isActive ? .bold : .medium)
            .foregroundColor(isActive ? .yellow : .white.opacity(0.8))
    }
    
    ///  Стиль тонкий для навбара игры
    func millionaireNavBarStyle(isActive: Bool = false) -> some View {
        self
            .font(.millionaireCaption)
    }
}
