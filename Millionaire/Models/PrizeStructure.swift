//
//  PrizeData.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 24.07.25.
//

import Foundation

struct PrizeStructure {
    static let standard = PrizeStructure(
        prizes: [
            Prize(questionNumber: 1, amount: 500, isCheckpoint: false),
            Prize(questionNumber: 2, amount: 1_000, isCheckpoint: false),
            Prize(questionNumber: 3, amount: 2_000, isCheckpoint: false),
            Prize(questionNumber: 4, amount: 3_000, isCheckpoint: false),
            Prize(questionNumber: 5, amount: 5_000, isCheckpoint: true),
            Prize(questionNumber: 6, amount: 7_500, isCheckpoint: false),
            Prize(questionNumber: 7, amount: 10_000, isCheckpoint: false),
            Prize(questionNumber: 8, amount: 12_500, isCheckpoint: false),
            Prize(questionNumber: 9, amount: 15_000, isCheckpoint: false),
            Prize(questionNumber: 10, amount: 25_000, isCheckpoint: true),
            Prize(questionNumber: 11, amount: 50_000, isCheckpoint: false),
            Prize(questionNumber: 12, amount: 100_000, isCheckpoint: false),
            Prize(questionNumber: 13, amount: 250_000, isCheckpoint: false),
            Prize(questionNumber: 14, amount: 500_000, isCheckpoint: false),
            Prize(questionNumber: 15, amount: 1_000_000, isCheckpoint: false)
        ]
    )
    
    let prizes: [Prize]
    
    // Доступ по индексу (0-based, для internal логики)
    // для раоты внутри логики игры, шаги и массивы (индексация)
    func getPrize(for questionIndex: Int) -> Prize? {
        guard prizes.indices.contains(questionIndex) else { return nil }
        return prizes[questionIndex]
    }
    
    // Доступ по номеру вопроса (1-based, для UI и отображения)
    // Работа с UI, отображение лестницы, поиск по номеру
    func prizeForQuestion(number: Int) -> Prize? {
        return prizes.first(where: { $0.questionNumber == number })
    }
    
    func getCheckpointPrize(before questionIndex: Int) -> Prize? {
        return prizes
            .enumerated()
            .filter { $0.element.isCheckpoint && $0.offset < questionIndex }
            .last?
            .element
    }
    func getNextPrize(after questionIndex: Int) -> Prize? {
            let nextIndex = questionIndex + 1
            return getPrize(for: nextIndex)
        }
}
