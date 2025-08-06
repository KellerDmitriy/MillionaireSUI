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
    
    func start30SecondTimer(completion: @escaping () -> Void)
    func pauseTimer()
    func resumeTimer()
    func stopTimer()
}

final class TimerService: ITimerService {
    
    @Published private(set) var displayData: TimerDisplayData = TimerDisplayData(formattedTime: "00:00", type: .normal)
    @Published private(set) var progress: Float = 1.0 // 100% в начале (30 сек)
    
    var displayPublisher: Published<TimerDisplayData>.Publisher { $displayData }
  
    private(set) var totalSeconds: Int = 0
    private var remaining: Int = 0
    private var onComplete: (() -> Void)?
    
    private var cancellable: AnyCancellable?
    private var isPaused = false
    
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
    }
    
    func resumeTimer() {
        guard isPaused, remaining > 0 else { return }
        startPublisher()
        isPaused = false
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
                
                remaining -= 1
                progress = Float(remaining) / Float(totalSeconds)
                updateDisplay()
                
                if remaining <= 0 {
                    stopTimer()
                    onComplete?()
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
