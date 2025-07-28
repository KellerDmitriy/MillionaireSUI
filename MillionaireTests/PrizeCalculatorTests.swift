//
//  PrizeCalculatorTests.swift
//  MillionaireTests
//
//  Created by Aleksandr Meshchenko on 24.07.25.
//

import XCTest

@testable import Millionaire

/// Тесты бизнес-логики расчета призов
final class PrizeCalculatorTests: XCTestCase {

    /// Система расчета призов, инициализированная с дефолтной структурой
    private let calculator = PrizeCalculator()

    /// Проверка корректности сумм на начальном и финальном вопросах
    ///
    /// - Вопрос 1 должен давать 100 (₽)
    /// - Вопрос 15 должен давать 1_000_000 (₽)
    func testPrizeAmounts() {
        XCTAssertEqual(calculator.getPrizeAmount(for: 0), 500)
        XCTAssertEqual(calculator.getPrizeAmount(for: 14), 1_000_000)
    }

    /// Проверка логики определения последнего checkpoint-приза (несгораемой суммы)
    ///
    /// - До 5-го вопроса не должно быть checkpoint
    /// - До 7-го должен быть checkpoint на 5-м (1_000 ₽)
    /// - До 12-го должен быть checkpoint на 10-м (32_000 ₽)
    func testCheckpointCalculation() {
        XCTAssertNil(calculator.prizeStructure.getCheckpointPrize(before: 3)) // < 5
        XCTAssertEqual(calculator.prizeStructure.getCheckpointPrize(before: 7)?.amount, 5_000)
        XCTAssertEqual(calculator.prizeStructure.getCheckpointPrize(before: 12)?.amount, 25_000)
    }
    
    /// Проверка получения приза по номеру вопроса (1-based)
    ///
    /// - Вопрос с номером 5 должен вернуть 1_000 ₽
    /// - Запрос по номеру 20 (вне диапазона) должен вернуть nil
    func testPrizeForQuestionNumber() {
        XCTAssertEqual(calculator.prizeStructure.prizeForQuestion(number: 5)?.amount, 5_000)
        XCTAssertNil(calculator.prizeStructure.prizeForQuestion(number: 20)) // вне диапазона
    }
    
    // getNextPrize(after:)
    // Этот метод может вернуть:
    // - Prize со следующим индексом
    // - nil, если следующего нет
    func testNextPrize() {
        // Вопрос 13 → следующий — 14
        let next = calculator.getNextPrize(after: 12)
        XCTAssertEqual(next?.amount, 500_000)
        
        // После последнего вопроса призов больше нет
        let none = calculator.getNextPrize(after: 14)
        XCTAssertNil(none)
    }

    // isCheckpoint(questionIndex:)
    // Проверить, что true и false возвращаются корректно:
    func testIsCheckpoint() {
        XCTAssertTrue(calculator.isCheckpoint(questionIndex: 4))  // Вопрос 5 (index 4)
        XCTAssertTrue(calculator.isCheckpoint(questionIndex: 9))  // Вопрос 10 (index 9)
        XCTAssertFalse(calculator.isCheckpoint(questionIndex: 0)) // Вопрос 1
    }
    
    // getAllPrizes()
    // Этот метод сейчас возвращает просто массив PrizeStructure.prizes, но его полезно протестировать:
    func testAllPrizesCountAndOrder() {
        let all = calculator.getAllPrizes()
        XCTAssertEqual(all.count, 15)
        XCTAssertEqual(all.first?.amount, 500)
        XCTAssertEqual(all.last?.amount, 1_000_000)
    }

}
