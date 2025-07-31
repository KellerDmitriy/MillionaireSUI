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
    let onCategorySelectedID: (Int?) -> Void

    @State private var showAlert = false

    // MARK: - Initialization
    init(gameManager: GameManager,
         onClose: @escaping () -> Void,
         onCategorySelectedID: @escaping (Int?) -> Void) {
        self.viewModel = CategoriesViewModel(gameManager: gameManager)
        self.onClose = onClose
        self.onCategorySelectedID = onCategorySelectedID
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Loading State View
            if viewModel.isLoading {
                LoadingView()
            } else {
                // MARK: Main Content View
                AnimatedGradientBackgroundView()

                VStack(spacing: 0) {
                    // MARK: Logo
                    Image("ScoreboardScreenLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 85, height: 85)
                        .padding(.top, 8)

                    // MARK: Categories List ScrollView
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.categories.enumerated()), id: \.0) { index, category in
                                CategoryRowView(
                                    index: index,
                                    category: category,
                                    isSelected: viewModel.selectedCategoryID == category.id
                                )
                                .onTapGesture {
                                    viewModel.selectedCategoryID = category.id
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                        .padding(.bottom, 50)
                    }

                    // MARK: Select Category Button
                    gameButton(title: "Select category", variant: .primary) {
                        onCategorySelectedID(viewModel.selectedCategoryID)
                    }
                    .padding()
                }
                .blur(radius: showAlert ? 5 : 0)
            }

            // MARK: Alert Overlay
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

        // MARK: Subscriptions
        // Show alert when errorMessage changes
        .onChange(of: viewModel.errorMessage) { newValue in
            showAlert = !newValue.isEmpty
        }
        // Load categories when view appears
        .task {
            await viewModel.loadCategories()
            if !viewModel.categories.isEmpty {
                viewModel.isLoading = false
            }
        }
    }

    // MARK: - UI Components

    @ViewBuilder
    private func gameButton(title: String,
                            variant: ButtonVariant,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
        }
        .millionaireStyle(variant)
        .frame(maxWidth: .infinity)
    }
}
#Preview {
    CategoriesScreen(gameManager: GameManager()
                     , onClose: {}, onCategorySelectedID: {_ in })
}
