//
//  AudienceLifelineGenerator.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 31.07.2025.
//

import Foundation

struct AudienceLifelineGenerator {
    
    // MARK: - Public Interface

    /// Генерирует проценты голосов зала для каждого варианта ответа.
    /// - Parameters:
    ///   - correctAnswerIndex: Индекс правильного ответа (0...3).
    ///   - difficulty: Уровень сложности вопроса.
    /// - Returns: Массив из 4 элементов с процентами голосов (сумма = 100).
    static func generate(for correctAnswerIndex: Int, difficulty: QuestionDifficulty) -> [Int] {
        
        // MARK: - Correct Answer Range

        // Задаём диапазон вероятности, с которой зал угадывает правильный ответ
        let correctRange: ClosedRange<Int> = {
            switch difficulty {
            case .easy: return 65...70    // Высокий шанс, что зал угадает
            case .medium: return 55...65
            case .hard: return 45...50    // Низкий шанс
            }
        }()

        // MARK: - Initial Percentages Setup

        let correctPercent = Int.random(in: correctRange)      // Сколько процентов проголосует за правильный вариант
        let remainingPercent = 100 - correctPercent            // Остальные проценты распределяются между неправильными вариантами

        var percentages = Array(repeating: 0, count: 4)        // Массив с процентами для всех 4 вариантов
        percentages[correctAnswerIndex] = correctPercent       // Задаём процент для правильного ответа

        // MARK: - Distribute Remaining Votes

        var remaining = remainingPercent
        let indices = [0, 1, 2, 3]
            .filter { $0 != correctAnswerIndex }
            .shuffled()                                        // Перемешиваем индексы неправильных ответов

        for (i, index) in indices.enumerated() {
            let isLast = i == indices.count - 1
            let maxAllowed = max(1, remaining - (indices.count - i - 1)) // Минимум 1%, чтобы не получить 0

            let percent = isLast
                ? remaining                                     // Последнему варианту отдаём остаток
                : Int.random(in: 1...maxAllowed)               // Остальным — случайное число в допустимом диапазоне

            percentages[index] = percent
            remaining -= percent
        }

        return percentages
    }
}
