//
//  NetworkManager.swift
//  Millionaire
//
//  Created by Наташа Спиридонова on 22.07.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case dataLoadingFailed
    case decodingFailed
}

final class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func fetchQuestions(from url: URL?) async throws -> [Question] {
        guard let url else {
            throw NetworkError.invalidURL
        }
        
        let (data, responce) = try await URLSession.shared.data(from: url)
        
        guard let httpResponce = responce as? HTTPURLResponse,
              (200..<300).contains(httpResponce.statusCode) else {
            throw NetworkError.dataLoadingFailed
        }
        
         let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let questionResponse = try decoder.decode(QuestionsResponse.self, from: data)
            return questionResponse.results
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
