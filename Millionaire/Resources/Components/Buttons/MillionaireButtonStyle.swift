//
//  MillionaireButtonStyle.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 22.07.25.
//
import SwiftUI

// MARK: - Answer Letters (A, B, C, D)
enum AnswerLetter: String, CaseIterable {
    case a = "A", b = "B", c = "C", d = "D"
}
// MARK: - Millionaire Button Style (Image-Based Only)

/// Кастомный стиль кнопки для игры "Кто хочет стать миллионером?"
/// Использует только изображения как основу с дополнительными эффектами
struct MillionaireButtonStyle: ButtonStyle {
    
    // MARK: - Properties
    
    let variant: Variant
    @Environment(\.isEnabled) private var isEnabled
    
    // MARK: - Initialization
    
    init(variant: Variant = .primary) {
        self.variant = variant
    }
    
    // MARK: - ButtonStyle Implementation
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Фон на основе изображения
            Image(variant.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 60)
                .overlay(shineEffect(for: configuration))
            
            // Контент кнопки
                configuration.label
                    .font(.millionaireMenuButton) // Используем кастомный шрифт
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .opacity(isEnabled ? 1.0 : 0.6)
        .shadow(
            color: shadowColor.opacity(shadowOpacity(for: configuration)),
            radius: shadowRadius(for: configuration),
            x: 0,
            y: shadowOffset(for: configuration)
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private func shineEffect(for configuration: Configuration) -> some View {
        LinearGradient(
            colors: configuration.isPressed ? [] : [
                Color.white.opacity(0.0),
                Color.white.opacity(0.1),
                Color.white.opacity(0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var textColor: Color {
        return isEnabled ? .white : Color.white.opacity(0.5)
    }
    
    private var shadowColor: Color {
        switch variant {
        case .primary:
            return .yellow
        case .regular:
            return .blue
        }
    }
    
    private func shadowOpacity(for configuration: Configuration) -> Double {
        if !isEnabled { return 0.2 }
        return configuration.isPressed ? 0.8 : 0.6
    }
    
    private func shadowRadius(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 4 }
        return configuration.isPressed ? 12 : 8
    }
    
    private func shadowOffset(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 2 }
        return configuration.isPressed ? 6 : 4
    }
}

// MARK: - Button Variant

extension MillionaireButtonStyle {
    enum Variant {
        case primary  // Основная кнопка (золотистая)
        case regular  // Обычная кнопка (синяя)
        
        var imageName: String {
            switch self {
            case .primary:
                return "PrimaryButton"
            case .regular:
                return "RegularButton"
            }
        }
    }
}

// MARK: - Answer Button Style

/// Специализированный стиль для кнопок ответов
/// Всегда показывает букву и текст ответа
struct MillionaireAnswerButtonStyle: ButtonStyle {
    
    // MARK: - Properties
    
    let state: AnswerState
    @Environment(\.isEnabled) private var isEnabled
    
    // MARK: - Initialization
    
    init(state: AnswerState = .regular) {
        self.state = state
    }
    
    // MARK: - ButtonStyle Implementation
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Фон на основе изображения
            Image(state.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 60)
                .overlay(shineEffect(for: configuration))
            
            // Контент кнопки ответа
            // Ожидаем, что label будет MillionaireAnswerLabel
            configuration.label
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .opacity(isEnabled ? 1.0 : 0.6)
        .shadow(
            color: shadowColor.opacity(shadowOpacity(for: configuration)),
            radius: shadowRadius(for: configuration),
            x: 0,
            y: shadowOffset(for: configuration)
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    // MARK: - Private Methods
    
    @ViewBuilder
    private func shineEffect(for configuration: Configuration) -> some View {
        LinearGradient(
            colors: configuration.isPressed ? [] : [
                Color.white.opacity(0.0),
                Color.white.opacity(0.1),
                Color.white.opacity(0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var shadowColor: Color {
        switch state {
        case .regular:
            return Color(red: 0.2, green: 0.4, blue: 0.8)
        case .correct:
            return .green
        case .wrong:
            return .red
        }
    }
    
    private func shadowOpacity(for configuration: Configuration) -> Double {
        if !isEnabled { return 0.2 }
        return configuration.isPressed ? 0.8 : 0.6
    }
    
    private func shadowRadius(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 4 }
        return configuration.isPressed ? 12 : 8
    }
    
    private func shadowOffset(for configuration: Configuration) -> CGFloat {
        if !isEnabled { return 2 }
        return configuration.isPressed ? 6 : 4
    }
}

// MARK: - Answer State

extension MillionaireAnswerButtonStyle {
    enum AnswerState {
        case regular  // Обычный ответ (не выбран)
        case correct  // Правильный ответ (зеленый)
        case wrong    // Неправильный ответ (красный)
        
        var imageName: String {
            switch self {
            case .regular:
                return "AnswerRegular"
            case .correct:
                return "AnswerCorrect"
            case .wrong:
                return "AnswerWrong"
            }
        }
    }
}

// MARK: - Answer Label View

/// Контент для кнопки ответа
struct MillionaireAnswerLabel: View {
    let letter: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Желтая буква (A, B, C, D)
            Text(letter)
                .millionaireAnswerLetterStyle()
                .frame(minWidth: 30, alignment: .trailing)
            
            // Белый текст ответа
            Text(text)
                .millionaireAnswerTextStyle()
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
    }
}

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

// MARK: - Preview

#Preview("MillionaireButtonStyle") {
    VStack(spacing: 20) {
        
        // Заголовок
        Text("Обычные кнопки")
            .millionaireTitleStyle()
        
        // Обычные кнопки
        VStack(spacing: 24) {
            Text("Menu Buttons:")
                .millionaireQuestionStyle()
            
            // Фабричный метод
            Button.millionaire("Начать игру", variant: .primary) {
                print("Start game")
            }
            
            // Традиционный способ
            Button("Настройки") {
                print("Settings")
            }
            .millionaireStyle(.regular)
            
            // С кастомным контентом
            Button {
                print("Custom content")
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("Настройки")
                }
            }
            .millionaireStyle(.regular)
            
            // Отключенная кнопка
            Button("Выход") {
                print("Exit")
            }
            .millionaireStyle(.primary)
            .disabled(true)

        }
        
        Divider()
            .background(Color.white.opacity(0.3))
        
        // Демонстрация переиспользования AnswerLabel
        VStack(alignment: .leading, spacing: 8) {
            Text("Answer preview (not a button):")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            MillionaireAnswerLabel(
                letter: "E:",
                text: "Можно использовать отдельно"
            )
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        
        Spacer()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.063, green: 0.055, blue: 0.086),
                Color(red: 0.216, green: 0.298, blue: 0.58)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}

#Preview("MillionaireAnswerButtonStyle") {
    VStack(spacing: 20) {
        
        // Заголовок
        Text("Кнопки ответов")
            .millionaireTitleStyle()
        
        // Кнопки ответов
        VStack(spacing: 10) {
            Text("Answer Buttons:")
                .millionaireQuestionStyle()
            
            // Фабричный метод (рекомендуется)
            Button.millionaireAnswer(
                letter: "A:",
                text: "Правильный ответ на вопрос"
            ) {
                print("Answer A")
            }
            
            // Явное использование label
            Button {
                print("Answer B")
            } label: {
                MillionaireAnswerLabel(
                    letter: "B:",
                    text: "Это правильный ответ"
                )
            }
            .millionaireAnswerStyle(.correct)
            
            // Неправильный ответ
            Button.millionaireAnswer(
                letter: "C:",
                text: "Неправильный вариант",
                state: .wrong
            ) {
                print("Answer C")
            }
            
            // Отключенный ответ
            Button.millionaireAnswer(
                letter: "D:",
                text: "Еще один вариант ответа"
            ) {
                print("Answer D")
            }
            .disabled(true)
        }
        
        Divider()
            .background(Color.white.opacity(0.3))
        
        // Демонстрация переиспользования AnswerLabel
        VStack(alignment: .leading, spacing: 8) {
            Text("Answer preview (not a button):")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            MillionaireAnswerLabel(
                letter: "E:",
                text: "Можно использовать отдельно"
            )
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
        Spacer()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [
                Color(red: 0.063, green: 0.055, blue: 0.086),
                Color(red: 0.216, green: 0.298, blue: 0.58)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}

#Preview("Type Safety Demo") {
    VStack(spacing: 20) {
        
        // комбинации  невозможны на уровне типов:
        
        // Нельзя использовать answerStyle с обычным текстом
        // Button("Test") { }
        //     .millionaireAnswerStyle()
        
        // Нельзя использовать обычный стиль с AnswerLabel
        // Button { } label: {
        //     MillionaireAnswerLabel(letter: "A:", text: "Test")
        // }
        // .millionaireStyle(.primary)
        
        // Правильные комбинации:
        Button("Menu Button") { }
            .millionaireStyle(.primary)
        
        Button { } label: {
            MillionaireAnswerLabel(letter: "A:", text: "Answer")
        }
        .millionaireAnswerStyle(.regular)
    }
    .padding()
}
