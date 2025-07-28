//
//  Prize.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 24.07.25.
//

import Foundation

struct Prize: Equatable {
    let questionNumber: Int
    let amount: Int
    let isCheckpoint: Bool
    
    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current  // Автоматически подтянет рубль/евро/доллар и формат

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
