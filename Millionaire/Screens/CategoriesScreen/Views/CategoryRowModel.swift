//
//  File.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//
import Foundation

enum CategoryRowType: String {
    case checkpoint = "Current"
    case none = "Top"
}

struct CategoryRowModel: Identifiable, Codable {
    let id: Int
    let name: String
    let isCheckpoint: Bool

    var categoryType: CategoryRowType {
        switch true {
        case isCheckpoint: return .checkpoint
        default: return .none
        }
    }
}
