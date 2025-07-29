//
//  CategoriesScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//

import SwiftUI

struct CategoriesScreen: View {
    @ObservedObject var viewModel: CategoriesViewModel
    
    let onClose: () -> Void
    let onCategorySelectedID: (Int) -> Void
    
    @State private var showAlert = false
    @State private var selectedCategoryID: Int? = nil
    
    init(gameManager: GameManager,
         onClose: @escaping () -> Void,
         onCategorySelectedID: @escaping (Int) -> Void) {
        self.viewModel = CategoriesViewModel(gameManager: gameManager)
        self.onClose = onClose
        self.onCategorySelectedID = onCategorySelectedID
    }
    
    var body: some View {
        ZStack {
            // Background
            AnimatedGradientBackgroundView()
            
            VStack(spacing: 0) {
                // Логотип
                Image("ScoreboardScreenLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 85, height: 85)
                
                    .padding(.top, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        // Таблица категорий
                        ForEach(Array(viewModel.categories.enumerated()), id: \.1.id) { index, category in
                            CategoryRowView(
                                index: index,
                                category: category,
                                isSelected: selectedCategoryID == category.id
                            )
                            .onTapGesture {
                                Task {
                                    try await Task.sleep(for: .seconds(3))
                                    selectedCategoryID = category.id
                                    onCategorySelectedID(category.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
                    .padding(.bottom, 50)
                }
            }
            .blur(radius: showAlert ? 5 : 0)
            
            // Alert Overlay
            if showAlert {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showAlert = false
                    }
                
                CustomAlertView(
                    message: viewModel.errorMessage,
                    onDismiss: {
                        showAlert = false
                    },
                    showSecondButton: false
                )
                .frame(width: 300, height: 400)
                .cornerRadius(20)
                .zIndex(2)
            }
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.loadCategories()
        }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Categories")
                    .millionaireTitleStyle()
            }
            
            
        }
    }
}

#Preview {
    CategoriesScreen(gameManager: GameManager()
                     , onClose: {}, onCategorySelectedID: {_ in })
}
