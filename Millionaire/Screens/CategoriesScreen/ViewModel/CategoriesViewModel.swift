//
//  CategoriesViewModel.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

final class CategoriesViewModel: ObservableObject {
    private let gameManager: GameManager
    
    @Published var categories: [CategoryRowModel] = []
    @Published var errorMessage: String = ""
    
    init(gameManager: GameManager) {
        self.gameManager = gameManager
    }
    
    
    func loadCategories() async {
        do {
            let categoriesDTO = try await gameManager.getCategories()
            await MainActor.run { [weak self] in
                self?.categories = makeCategoryRows(from: categoriesDTO)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("ошибка загрузки категорий")
        }
    }
    
    func makeCategoryRows(from categories: [QuestionCategory]) -> [CategoryRowModel] {
        categories.map { category in
            CategoryRowModel(
                id: category.id,
                name: category.name,
                isCheckpoint: false
            )
        }
    }
    
}
