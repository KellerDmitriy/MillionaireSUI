//
//  Endpoint.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

struct Endpoint {
    private let baseURL: String
    private let path: String
    private let queriItems: [URLQueryItem]
    
    init(baseURL: String = "https://opentdb.com", path: String, queriItems: [URLQueryItem] = []) {
        self.baseURL = baseURL
        self.path = path
        self.queriItems = queriItems
    }
    
    var url: URL? {
        var components = URLComponents(string: baseURL)
        components?.path += path
        components?.queryItems = queriItems
        return components?.url
    }
}

enum QuestionAPIEndpoint {
    case categories
    case questions(amount: Int = 15, categoryID: Int? = nil, difficulty: QuestionDifficulty? = nil)
    
    func makeEndpoint() -> Endpoint {
        switch self {
            
        case .categories:
            return Endpoint(path: "/api_category.php")
        case .questions(amount: let amount, categoryID: let categoryID, difficulty: let difficulty):
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "amount", value: "\(amount)"),
                URLQueryItem(name: "type", value: "multiple")
            ]
            if let categoryID = categoryID {
                queryItems.append(URLQueryItem(name: "category", value: "\(categoryID)"))
            }
            
            if let difficulty = difficulty {
                queryItems.append(URLQueryItem(name: "difficulty", value: difficulty.rawValue))
            }
            return Endpoint(path: "/api.php", queriItems: queryItems)
        }
    }
}
