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
    func playVictorySfx()
    func currentState() -> AudioState
    func restoreState(_ state: AudioState) 
    func stop()
    func pause()
    func resume()
}

final class AudioService: IAudioService {
    
    enum ResourceSfx: String, Codable {
        case gameSfx
        case wrongAnswerSfx
        case correctAnswerSfx
        case answerLockedSfx
        case milionaireSfx
    }
    
    private var player: AVAudioPlayer?
    
   init() {
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
    
    func playVictorySfx() {
        play(resource: .milionaireSfx)
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
// MARK: - Public Methods для работы с сохранением и возобновлением игры с актуальным музсопровождением
extension AudioService {
    func currentState() -> AudioState {
        return AudioState(
            resource: (player?.url?.deletingPathExtension().lastPathComponent),
            currentTime: player?.currentTime ?? 0,
            isPlaying: player?.isPlaying ?? false
        )
    }
    
    func restoreState(_ state: AudioState) {
        guard let resourceName = state.resource,
              let resource = ResourceSfx(rawValue: resourceName) else { return }
        
        play(resource: resource)  
        player?.currentTime = state.currentTime
        if !state.isPlaying {
            player?.pause()
        }
    }
}

class MockAudioService: IAudioService {
    func restoreState(_ state: AudioState) { print("🔊 Resumed Audio State")}
    
    func currentState() -> AudioState {
        AudioState(resource: "gameSfx", currentTime: 0.24, isPlaying: true)
    }
    
    func playGameSfx() { print("🔊 Game music") }
    func playAnswerLockedSfx() { print("🔊 Answer locked") }
    func playCorrectAnswerSfx() { print("🔊 Correct!") }
    func playWrongAnswerSfx() { print("🔊 Wrong!") }
    func playVictorySfx() { print("🔊 Victory!") }
    func pause() { print("⏸️ Paused") }
    func resume() { print("▶️ Resumed") }
    func stop() { print("⏹️ Stopped") }
}
