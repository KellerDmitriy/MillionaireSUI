//
//  CategoriesViewModel.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import Foundation

@MainActor
final class CategoriesViewModel: ObservableObject {
    private let gameManager: GameManager
    
    @Published var selectedCategoryID: Int?
    @Published var categories: [QuestionCategory] = []
    
    @Published var isLoading: Bool = true
    @Published var errorMessage: String = ""
    
    // MARK: - Initialization
    init(gameManager: GameManager) {
        self.gameManager = gameManager
        self.selectedCategoryID = gameManager.selectedCategoryID
    }
    
    func selectCategory(_ id: Int?) {
        selectedCategoryID = id  //  Обновляем локальное (триггерит UI)
        gameManager.selectCategory(id)  //  Обновляем глобальное
    }
    
    // MARK: - Load Categories
    /// Asynchronously load categories from API and prepend "All Categories" option.
    func loadCategories() async {
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }
        
        do {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Fetch categories from the API
            let fetchedCategories = try await gameManager.getCategories()
            print("CategoriesViewModel: Fetched \(fetchedCategories.count) categories")
            
            // Create a default "All Categories" item
            let allCategories = QuestionCategory(id: 0, name: "All Categories")
            
            // Combine "All Categories" with fetched categories
            let all = [allCategories] + fetchedCategories
            
            // Update published categories on the main thread (UI)
            await MainActor.run {
                print("CategoriesViewModel: Updating UI with \(all.count) categories")
                self.categories = all
                self.isLoading = false
            }
            
            // Если ничего не выбрано, выбираем "All Categories"
            if selectedCategoryID == nil {
                selectedCategoryID = 0
                gameManager.selectCategory(0)
            }
        } catch {
            print("CategoriesViewModel: Error loading categories: \(error)")
            
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                
                // Add default category even on error
                if self.categories.isEmpty {
                    self.categories = [QuestionCategory(id: 0, name: "All Categories")]
                }
                print("CategoriesViewModel: Error handled, isLoading set to false")
            }
        }
        
    }
}
