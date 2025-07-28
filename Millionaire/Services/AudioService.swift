//
//  IAudioService.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 25.07.2025.
//


import AVFoundation

protocol IAudioService {
    func playGameSfx()
    func playWrongAnswerSfx()
    func playCorrectAnswerSfx()
    func playAnswerLockedSfx()
    func stop()
    func pause()
    func resume()
}

final class AudioService: IAudioService {
    static let shared = AudioService()
    
    enum ResourceSfx: String {
        case gameSfx
        case wrongAnswerSfx
        case correctAnswerSfx
        case answerLockedSfx
    }
    
    private var player: AVAudioPlayer?
    
   private init() {
        // Настройка аудио сессии для игры
        configureAudioSession()
    }
    
    deinit {
        // Нужен для
        // немедленной остановки звука (не ждем ARC) - четкое завершения воспроизведения и
        // освобождение аудиоресурсов
        player?.stop()
        player = nil
        
#if DEBUG
        print("AudioService деинициализирован")
#endif
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func play(resource: ResourceSfx) {
        guard let url = Bundle.main.url(forResource: resource.rawValue, withExtension: "mp3") else {
            print("Audio resource not found: \(resource.rawValue)")
            return
        }

        do {
            // Останавливаем предыдущий звук перед воспроизведением нового
            player?.stop()
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay() // Предзагрузка для уменьшения задержки
            player?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Methods
    func playGameSfx() {
        play(resource: .gameSfx)
    }
    
    func playWrongAnswerSfx() {
        play(resource: .wrongAnswerSfx)
    }
    
    func playCorrectAnswerSfx() {
        play(resource: .correctAnswerSfx)
    }
    
    func playAnswerLockedSfx() {
        play(resource: .answerLockedSfx)
    }
    
    func pause() {
         player?.pause()
     }
     
     func resume() {
         player?.play()
     }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0 // Сброс позиции воспроизведения
        player = nil
    }
}
