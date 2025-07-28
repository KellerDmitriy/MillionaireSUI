//
//  TimerService.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 25.07.2025.
//

import Foundation
import Combine

// MARK: - Protocol

protocol ITimerService {
    var progressPublisher: Published<Float>.Publisher { get }
    func start30SecondTimer(completion: @escaping () -> Void)
    func pauseTimer()
    func stopTimer()
    func resumeTimer()
}

// MARK: - Implementation

final class TimerService: ITimerService {
    
    @Published var progress: Float = 0.0
    var progressPublisher: Published<Float>.Publisher { $progress }
    
    private var timer: Timer?
    private var elapsed: Int = 0
    private var total: Int = 0
    private var onComplete: (() -> Void)?
    
    // MARK: - Deinit
    deinit {
        // ВАЖНО! Обязательно останавливаем таймер
        timer?.invalidate()
        timer = nil
        
        //Если при возврате назад нет этих сообщений - есть утечка!
#if DEBUG
        print("TimerService деинициализирован")
#endif
    }
    
    // MARK: - Public API
    func start30SecondTimer(completion: @escaping () -> Void) {
        configureTimer(totalSeconds: 30, updateProgress: true, completion: completion)
    }
    
    
    func pauseTimer() {
        guard timer != nil else { return }
        
        timer?.invalidate()
        timer = nil
    }
    
    func resumeTimer() {
        // Возобновляем с текущего места
        guard timer == nil, total > 0, elapsed < total else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed += 1
            self.progress = Float(self.elapsed) / Float(self.total)
            
            if self.elapsed >= self.total {
                self.stopTimer()
                self.onComplete?()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        progress = 0.0
        elapsed = 0
        total = 0
    }
    
    // MARK: - Private
    private func configureTimer(totalSeconds: Int, updateProgress: Bool, completion: @escaping () -> Void) {
        stopTimer()
        self.elapsed = 0
        self.total = totalSeconds
        self.onComplete = completion
        
        if updateProgress {
            self.progress = 0
        }
        
        // Timer держит RunLoop
        // он добавляется в главный RunLoop
        // RunLoop держит сильную ссылку на Timer ->
        // Timer может пережить этот TimerService сервис!
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsed += 1
            
            if updateProgress {
                self.progress = Float(self.elapsed) / Float(self.total)
            }
            
            if self.elapsed >= self.total {
                self.stopTimer()
                self.onComplete?()
            }
        }
    }
}
