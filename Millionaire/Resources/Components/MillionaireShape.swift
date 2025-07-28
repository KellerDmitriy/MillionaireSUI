//
//  CapsuleWithNotches.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 22.07.2025.
//

import SwiftUI

struct MillionaireShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 20

        var path = Path()

        path.move(to: CGPoint(x: inset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - inset, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height))
        path.addLine(to: CGPoint(x: inset, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.closeSubpath()

        return path
    }
}


struct MillionaireShapeView: View {
    
    var fillColor: Color
    var strokeColor: Color = .white
    private let lineWidth: CGFloat = 3
    
    var body: some View {
        MillionaireShape()
            .fill(fillColor)
            .overlay(
                MillionaireShape()
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
    }
}

#Preview {
    MillionaireShapeView(fillColor: .answerGradient2)
}
