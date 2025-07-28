//
//  HelpButton.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 22.07.2025.
//

import SwiftUI

// MARK: - Lifeline Types
extension Lifeline {
    var imageName: Image {
        switch self {
        case .fiftyFifty:
            return Image(.lifeline50)
        case .audience:
            return Image(.lifelineAudience)
        case .callToFriend:
            return Image(.lifelineCall)
        }
    }
}

// MARK: - Help Button View
struct HelpButton: View {
    let type: Lifeline
    let action: () -> Void
    
    @Environment(\.isEnabled) var isEnabled
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            type.imageName
                .resizable()
                .scaledToFit()
                .opacity(!isEnabled ? 0.3 : 1.0)
        }
    }
}

// MARK: - Preview
#Preview {
    HelpButton(type: .callToFriend, action: {})
}
