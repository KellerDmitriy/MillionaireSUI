//
//  CategoriesViewModel.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

final class CategoriesViewModel: ObservableObject {
    private let gameManager: GameManager
    
    @Published var selectedCategoryID: Int?
    @Published var categories: [QuestionCategory] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Initialization
    init(gameManager: GameManager) {
        self.gameManager = gameManager
    }
    
    // MARK: - Load Categories
    /// Asynchronously load categories from API and prepend "All Categories" option.
    func loadCategories() async {
        do {
            await MainActor.run { self.isLoading = true }
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Fetch categories from the API
            let fetchedCategories = try await gameManager.getCategories()
            
            // Create a default "All Categories" item with nil id
            let allCategories = QuestionCategory(id: 0, name: "All Categories")
            
            // Combine "All Categories" with fetched categories
            let all = [allCategories] + fetchedCategories
            
            // Update published categories on the main thread (UI)
            await MainActor.run {
                self.categories = all
            }
        } catch {
            // Handle errors and propagate error message on main thread
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
