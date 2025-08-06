//
//  QuestionCleaner.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

struct QuestionCleaner {
    static func clean(_ htmlString: String) -> String {
        guard let data = htmlString.data(using: .utf8) else { return htmlString }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return htmlString
    }
}
