//
//  CustomAlertView.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 26.07.2025.
//
import SwiftUI

struct CustomAlertView: View {
    
    let message: String
    let onDismiss: () -> Void
    var showSecondButton: Bool = false
    var secondButtonAction: (() -> Void)?
    
    var body: some View {
        ShadowedCardView(cornerRadius: 30) {
            VStack(spacing: 20) {
                Text(message)
                    .millionaireTitleStyle()
                    .multilineTextAlignment(.center)
                    .padding(.top, 50)
                
                Spacer()
                
                VStack(spacing: 16) {
                    if showSecondButton {
                        // Кнопка подтверждения
                        Button("Collect your winnings") {
                            secondButtonAction?()
                        }
                        .millionaireStyle(.primary)
                        .frame(width: 200, height: 50)
                        
                        // Кнопка отмены
                        Button("Cancel") {
                            onDismiss()
                        }
                        .millionaireStyle(.regular)
                        .frame(width: 200, height: 50)
                    } else {
                        // Обычная кнопка "Ok"
                        Button("Ok") { onDismiss() }
                            .millionaireStyle(.primary)
                            .frame(width: 200, height: 50)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview("Single Button") {
    CustomAlertView(message: "This is a regular notification.", onDismiss: {})
}

#Preview("Two Buttons") {
    CustomAlertView(
        message: "Are you sure you want to claim a prize of 15,000 $?",
        onDismiss: {},
        showSecondButton: true,
        secondButtonAction: {}
    )
}

struct ShadowedCardView<Content: View>: View {
    // MARK: - Properties
    let content: Content
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    
    // MARK: - Initialization
    init(
        cornerRadius: CGFloat = 30,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.answerGradient3)
                .basicShadow()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            
            content
                .padding()
        }
    }
}

struct BasicShadowModifier: ViewModifier {
    enum Drawing {
        static let shadowRadius: CGFloat = 15
        static let shadowOffsetX: CGFloat = 4
        static let shadowOffsetY: CGFloat = 4
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color(
                    red: 0.6,
                    green: 0.62,
                    blue: 0.76
                )
                .opacity(0.3),
                radius: Drawing.shadowRadius,
                x: Drawing.shadowOffsetX,
                y: Drawing.shadowOffsetY
            )
    }
}

extension View {
    func basicShadow() -> some View {
        self.modifier(BasicShadowModifier())
    }
}
