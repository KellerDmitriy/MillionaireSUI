//
//  GameSession.swift
//  Millionaire
//
//  Created by Effin Leffin on 22.07.2025.
//

import Foundation

/// enum с результатом ответа "правильно", "неправильно"
enum AnswerResult {
    case correct
    case incorrect
}

/// Результат подсказки 50:50
struct FiftyFiftyLifelineResult {
    /// Ответы, которые должны быть убраны
    let disabledAnswers: Set<String>
}

/// Результат подсказки помощь зала
struct AudienceLifelineResult {
    /// Выбор большинства в зале
    let answer: String
}

struct CallToFriendLifelineResult {
    /// Ответ друга
    let answer: String
}

/// Модель игры с полной логикой обновления её состояния
struct GameSession: Hashable, Codable {
    /// Массив вопросов
    let questions: [Question]
    
    /// Флаг, указывающий, завершена игра или нет
    ///  Игра завершена если:
    // 1. Дали неправильный ответ
    // 2. Ответили на все 15 вопросов
    // 3. Время вышло
    private(set) var isFinished: Bool
    
    /// Индекс текущего вопроса
    private(set) var currentQuestionIndex: Int
    /// Заработанный счет
    private(set) var score: Int
    /// Доступные подсказки
    private(set) var lifelines: Set<Lifeline>
    
    /// Tекущий вопрос
    var currentQuestion: Question {
        // Получаем текущий вопрос по индексу
        questions[currentQuestionIndex]
    }
    /// Флаг для подсказки друга(право на ошибку)
    private(set) var hasUsedCallToFriend = false
    
    init?(
        questions: [Question],
        isFinished: Bool = false,
        currentQuestionIndex: Int = 0,
        score: Int = 0,
        lifelines: Set<Lifeline> = [.fiftyFifty, .callToFriend, .audience]
    ) {
        // Проверяем корректное количество вопросов в массиве questions
        // Проверяем, входит ли индекс текущего вопроса в диапазон
        // Если нет, инициализации не произойдет, игровая сессия не создастся
        guard
            questions.count == 15,
            0..<15 ~= currentQuestionIndex
        else {
            return nil
        }
        
        // Если все правильно, инициализируем
        self.questions = questions
        self.isFinished = isFinished
        self.currentQuestionIndex = currentQuestionIndex
        self.score = score
        self.lifelines = lifelines
    }
    
    
    mutating func addScore(_ amount: Int) {
        score += amount
    }

    mutating func setScore(_ amount: Int) {
        score = amount
    }
    
    /// Функция, возвращающая результат, был ответ верный или нет, и переходящая к следующему вопросу, если таковой есть
    mutating func answer(answer: String) -> AnswerResult? {
        // Проверяем, что игра не закончена
        guard !isFinished else { return nil }
        
        if answer == currentQuestion.correctAnswer {
            // Ничего не начисляем — пусть это делает GameManager
            // Просто переходим к следующему вопросу
            
            // есть ли следующий вопрос
            if currentQuestionIndex + 1 < questions.count {
                currentQuestionIndex += 1
            } else { // иначе заканчиваем игру
                isFinished = true
            }
            return .correct
        } else {
            // Отметим, что игра завершена. Какую сумму дать - решает GameManager.
            if hasUsedCallToFriend {
                print("Использовано право на ошибку. Игра продолжается.")
                hasUsedCallToFriend = false
                if currentQuestionIndex + 1 < questions.count {
                    currentQuestionIndex += 1
                } else {
                    isFinished = true
                }
                return .correct
               
            }
            isFinished = true
            return .incorrect
        }
    }
    
    /// Пытается воспользоваться подсказкой 50:50, если она доступна, и сообщает наружу о результате
    mutating func useFiftyFiftyLifeline() -> FiftyFiftyLifelineResult? {
        guard canUse(lifeline: .fiftyFifty) else {
            return nil
        }

        lifelines.remove(.fiftyFifty)

        // Выбираем один случайный неправильный ответ
        guard let randomIncorrect = currentQuestion.incorrectAnswers.randomElement() else {
            return nil
        }

        // Все ответы, кроме правильного и одного неправильного, отключаем
        let allAnswers = Set(currentQuestion.incorrectAnswers)
        let enabledAnswers: Set<String> = [currentQuestion.correctAnswer, randomIncorrect]
        let disabledAnswers = allAnswers.subtracting(enabledAnswers)

        return FiftyFiftyLifelineResult(disabledAnswers: disabledAnswers)
    }
    
    mutating func useAudienceLifeline() -> AudienceLifelineResult? {
        guard canUse(lifeline: .audience) else {
            return nil
        }
        
        lifelines.remove(.audience)
        
        // Зал должен ответить на вопрос правильно с вероятностью 70%
        let isGuessCorrect = Int.random(in: 0..<100) < 70
        
        return AudienceLifelineResult(
            answer: isGuessCorrect ? currentQuestion.correctAnswer : currentQuestion.incorrectAnswers.randomElement()!
        )
    }
    
    ///  метод для подсказки "звонок другу"
    mutating func useLifeline(_ lifeline: Lifeline) {
        lifelines.remove(lifeline)
        if lifeline == .callToFriend {
            print("Подсказка 'Право на ошибку' активирована")
            hasUsedCallToFriend = true
        }
    }
    
//    mutating func useCallToFriendLifeline() -> CallToFriendLifelineResult? {
//        guard canUse(lifeline: .callToFriend) else {
//            return nil
//        }
//        
//        lifelines.remove(.callToFriend)
//        
//        // Звонок другу с вероятностью 80% даст правильный ответ.
//        let isGuessCorrect = Int.random(in: 0..<100) < 80
//        
//        return CallToFriendLifelineResult(
//            answer: isGuessCorrect ? currentQuestion.correctAnswer : currentQuestion.incorrectAnswers.randomElement()!
//        )
//    }
    
    private func canUse(lifeline: Lifeline) -> Bool {
        guard !isFinished else {
            return false
        }
        
        guard lifelines.contains(lifeline) else {
            return false
        }
        
        return true
    }
}
