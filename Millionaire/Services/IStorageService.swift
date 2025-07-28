//
//  StorageManagerProtocol.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 27.07.2025.
//

import Foundation

// MARK: - StorageManagerProtocol
protocol IStorageService {
    func saveGameSession(_ session: GameSession)
    func loadGameSession() -> GameSession?
    func clearSavedSession()
}

// MARK: - StorageManager
final class StorageService: IStorageService {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard
    private let sessionKey = "SavedGameSession"

    func saveGameSession(_ session: GameSession) {
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: sessionKey)
        } catch {
            print("Failed to save session: \(error)")
        }
    }

    func loadGameSession() -> GameSession? {
        guard let data = defaults.data(forKey: sessionKey) else {
            return nil
        }

        do {
            let session = try JSONDecoder().decode(GameSession.self, from: data)
            return session
        } catch {
            print("Failed to load session: \(error)")
            return nil
        }
    }

    func clearSavedSession() {
        defaults.removeObject(forKey: sessionKey)
    }
}
