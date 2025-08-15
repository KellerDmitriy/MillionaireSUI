//
//  TimerService.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 25.07.2025.
//

import Combine
import Foundation

protocol ITimerService {
    var displayPublisher: Published<TimerDisplayData>.Publisher { get }
    var totalSeconds: Int { get }
    var isRunning: Bool { get }
    func start30SecondTimer(completion: @escaping () -> Void)
    func pauseTimer()
    func resumeTimer()
    func stopTimer()
}

final class TimerService: ITimerService {
    static let shared = TimerService()
    
    @Published private(set) var displayData: TimerDisplayData = TimerDisplayData(formattedTime: "00:00", type: .normal)
    @Published private(set) var progress: Float = 1.0 // 100% в начале (30 сек)
    @Published private(set) var isPaused = false
    
    var displayPublisher: Published<TimerDisplayData>.Publisher { $displayData }
    
    
    private(set) var totalSeconds: Int = 0
    private var remaining: Int = 0
    private var onComplete: (() -> Void)?
    
    private var cancellable: AnyCancellable?
    
    var isRunning: Bool {
        !isPaused
    }
    
    private init(){}
    // MARK: - Public API
    func start30SecondTimer(completion: @escaping () -> Void) {
        startTimer(seconds: 30, completion: completion)
    }
    
    private func startTimer(seconds: Int, completion: @escaping () -> Void) {
        stopTimer()
        totalSeconds = seconds
        remaining = seconds
        updateDisplay()
        onComplete = completion
        startPublisher()
    }
    
    func pauseTimer() {
        cancellable?.cancel()
        cancellable = nil
        isPaused = true
        print("таймер на паузе, осталось\(remaining)cek")
    }
    
    func resumeTimer() {
        guard isPaused, remaining > 0 else { return }
        isPaused = false
        startPublisher()
        print("таймер продолжает работать, осталось\(remaining)cek")
    }
    
    func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
        remaining = 0
        totalSeconds = 0
        progress = 1.0
        updateDisplay()
        isPaused = false
    }
    
    // MARK: - Private
    private func startPublisher() {
        cancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                // Если на паузе, ничего не делаем
                if self.isPaused {
                    return
                }
                
                // Уменьшаем оставшееся время
                self.remaining -= 1
                
                // Обновляем прогресс и отображение
                self.progress = Float(self.remaining) / Float(self.totalSeconds)
                self.updateDisplay()
                
                // Если время вышло, останавливаем таймер и вызываем onComplete
                if self.remaining <= 0 {
                    self.stopTimer()
                    self.onComplete?()
                }
            }
    }
    
    private func updateDisplay() {
        let minutes = remaining / 60
        let seconds = remaining % 60
        let formatted = String(format: "%02d:%02d", minutes, seconds)
        let type = TimerType.getType(for: remaining)
        displayData = TimerDisplayData(formattedTime: formatted, type: type)
    }
}
