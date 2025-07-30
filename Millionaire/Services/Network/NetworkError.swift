//
//  NetworkError.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case dataLoadingFailed
    case decodingFailed
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .dataLoadingFailed:
            return "Failed to load data from the server."
        case .decodingFailed:
            return "Failed to decode the data."
        case .serverError(let code):
            return "Server returned an error: \(code)"
        }
    }
}
