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
    func start30SecondTimer(completion: @escaping () -> Void)
    func setOnExpire(_ onExpire: @escaping () -> Void)
    var remainingSeconds: Int { get }
    func setTotalTime(_ remaining: Int) 
    func pauseTimer()
    func resumeTimer()
    func stopTimer()
}

final class TimerService: ITimerService {
    
    @Published private(set) var displayData: TimerDisplayData = TimerDisplayData(formattedTime: "00:00", type: .normal)

    @Published private(set) var isPaused = false
    
    var displayPublisher: Published<TimerDisplayData>.Publisher { $displayData }
    
    private(set) var totalSeconds: Int = 0
    private var remaining: Int = 0
    private var onComplete: (() -> Void)?
    private var onExpire: (() -> Void)?
    private var cancellable: AnyCancellable?
    
    // MARK: - Public API
    var remainingSeconds: Int { remaining }
    
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
        guard remaining > 0 else { return }
        
        // Если был на паузе → снимаем паузу
        if isPaused {
            isPaused = false
            startPublisher()
            print("▶️ Таймер продолжает с паузы, осталось \(remaining) сек")
            return
        }
        
        // Если publisher уже не живой (например, после рестарта) → запускаем заново
        if cancellable == nil {

            updateDisplay()
            startPublisher()
            print("▶️ Таймер восстановлен, осталось \(remaining) сек")
        }
    }
    
    func setOnExpire(_ onExpire: @escaping () -> Void) {
        self.onExpire = onExpire
    }
    
    func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
        remaining = 0
        totalSeconds = 0
        updateDisplay()
        isPaused = false
    }
    
    func setTotalTime(_ remaining: Int) {
        self.remaining = remaining
        totalSeconds = remaining
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
                self.updateDisplay()
                
                // Если время вышло, останавливаем таймер и вызываем onComplete
                if self.remaining <= 0 {
                    self.stopTimer()
                    self.onComplete?()
                    self.onExpire?()
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
