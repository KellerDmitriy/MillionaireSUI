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
        ZStack {
            Image(.background)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.clear)
                )
                .basicShadow()
            
            VStack(spacing: 24) {
                Text(message)
                    .millionaireTitleStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                buttonSection
            }
            .padding(24)
        }
        .frame(width: 300, height: 450)
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white, lineWidth: 3)
        )
        .padding()
    }

    @ViewBuilder
    private var buttonSection: some View {
        VStack(spacing: 16) {
            if showSecondButton {
                primaryButton(title: "Collect your winnings", action: secondButtonAction)
                    .padding(.vertical)
                secondaryButton(title: "Cancel", action: onDismiss)
            } else {
                primaryButton(title: "Ok", action: onDismiss)
            }
        }
        .padding(.bottom)
    }

    private func primaryButton(title: String, action: (() -> Void)?) -> some View {
        Button(title) {
            action?()
        }
        .millionaireStyle(.primary)
        .frame(height: 44)
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title) {
            action()
        }
        .millionaireStyle(.regular)
        .frame(height: 44)
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
