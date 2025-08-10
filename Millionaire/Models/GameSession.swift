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
    /// проценты проголосовавших
    let votesPerAnswer: [Int]
}

/// Результат подсказки второй шанс
struct SecondChanceLifelineResult {
    /// Флаг, активирована ли подсказка
    let isActive: Bool
}

/// Модель игры с полной логикой обновления её состояния
struct GameSession: Hashable, Codable {
    
    /// Выбранная категория
    private(set) var selectedCategory: QuestionCategory?
    
    /// Массив вопросов
    private(set) var questions: [GameQuestion]
    
    // Флаг, указывающий, завершена игра или нет
    // Игра завершена если:
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
    var currentQuestion: GameQuestion {
        // Получаем текущий вопрос по индексу
        questions[currentQuestionIndex]
    }
    /// Флаг, активирована ли подсказка второй шанс
    private var secondChanceActive: Bool = false
    
    init?(questions: [QuestionDTO]) {
        
        guard !questions.isEmpty else { return nil }
        let cleanedQuestions: [GameQuestion] = questions.map { $0.cleaned() }
        
        self.questions = cleanedQuestions
        self.isFinished = false
        self.currentQuestionIndex = 0
        self.score = 0
        self.lifelines = [.fiftyFifty, .secondChance, .audience]
    }
    
    mutating func appendQuestions(_ newQuestions: [QuestionDTO]) {
        let cleanedQuestions = newQuestions.map { $0.cleaned() }
        guard !cleanedQuestions.isEmpty else {
            print("Ошибка: догруженные вопросы пустые!")
            return
        }
        questions.append(contentsOf: cleanedQuestions)
        print("✅ Догрузка завершена. Всего вопросов: \(self.questions.count)")
    }
    
    mutating func addScore(_ amount: Int) {
        score += amount
    }
    
    func getCurrentCategory() -> QuestionCategory? {
        selectedCategory
    }
    
    func getQuestionCount() -> Int {
        questions.count
    }
    
    mutating func updateSelectedCategory(_ category: QuestionCategory?) {
        selectedCategory = category
    }
    
    mutating func setScore(_ amount: Int) {
        score = amount
    }
    
    mutating func finish() {
        isFinished = true
    }
    
    /// Функция, возвращающая результат, был ответ верный или нет, и переходящая к следующему вопросу, если таковой есть
    mutating func answer(answer: String) -> AnswerResult? {
        // Проверяем, что игра не закончена
        guard !isFinished else { return nil }
        
        if answer == currentQuestion.correctAnswer {
            // Ничего не начисляем — пусть это делает GameManager
            // Просто переходим к следующему вопросу
            
            nextQuestionOrFinish()
            return .correct
        } else {
            // Отметим, что игра завершена. Какую сумму дать - решает GameManager.
            if secondChanceActive {
                print("Использовано право на ошибку. Игра продолжается.")
                secondChanceActive = false
                nextQuestionOrFinish()
                return .incorrect
                
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
    
    mutating func useAudienceLifeline(allAnswers: [String]) -> AudienceLifelineResult? {
        guard canUse(lifeline: .audience) else {
            return nil
        }
        
        lifelines.remove(.audience)
        
        guard let correctIndex = allAnswers.firstIndex(of: currentQuestion.correctAnswer) else {
            assertionFailure("Correct answer not found!")
            return nil
        }
        
        let difficulty = currentQuestion.difficulty
        print(correctIndex, difficulty)
        let percentages = AudienceLifelineGenerator.generate(for: correctIndex, difficulty: difficulty)
        return AudienceLifelineResult(votesPerAnswer: percentages)
    }
    
    ///  метод для подсказки "Право на ошибку"
    mutating func useSecondChanceLifeline() -> SecondChanceLifelineResult? {
        guard canUse(lifeline: .secondChance) else {
            return nil
        }
        
        lifelines.remove(.secondChance)
        secondChanceActive = true
        print("Подсказка 'Право на ошибку' активирована")
        return SecondChanceLifelineResult(isActive: true)
    }
    
    
    private mutating func nextQuestionOrFinish() {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
        } else {
            print("Закончились вопросы")
            isFinished = true
        }
    }
    
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
