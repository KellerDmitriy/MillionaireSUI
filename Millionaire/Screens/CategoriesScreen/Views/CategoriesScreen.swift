//
//  CategoriesScreen.swift
//  Millionaire
//
//  Created by Келлер Дмитрий on 29.07.2025.
//
import SwiftUI

struct CategoriesScreen: View {
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @StateObject var viewModel: CategoriesViewModel
    @State private var showAlert = false
    
    // MARK: - Initialization
    init(gameManager: GameManager) {
        self._viewModel = StateObject(wrappedValue: CategoriesViewModel(gameManager: gameManager))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // MARK: Loading State View
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.categories.isEmpty && !viewModel.errorMessage.isEmpty {
                // Error if categories are not loaded
                errorView
            } else {
                // MARK: Main Content View
                contentView
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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackBarButtonView(onBack: {
                    navigation.popToRoot()
                })}
        }
        // MARK: Subscriptions
        // Show alert when errorMessage changes
        .onChange(of: viewModel.errorMessage) { newValue in
            showAlert = !newValue.isEmpty
        }
        // Load categories when view appears
        .task {
            await viewModel.loadCategories()
        }
    }
    
    private var errorView: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("Failed to load categories")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Retry") {
                    Task {
                        await viewModel.loadCategories()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    private var alertOverlay: some View {
        ZStack {
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
    
    private var contentView: some View {
        ZStack {
            AnimatedGradientBackgroundView()
            
            VStack(spacing: 0) {
                // MARK: Logo
                Image("ScoreboardScreenLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 85, height: 85)
                
                // MARK: Categories List ScrollView
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.categories.enumerated()), id: \.0) { index, category in
                            CategoryRowView(
                                index: index,
                                category: category,
                                isSelected: viewModel.selectedCategory == category
                            )
                            .onTapGesture {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 8)
                    .padding(.bottom, 50)
                }
            }
            .offset(y: -20)
            .blur(radius: showAlert ? 5 : 0)
        }
    }
}

#Preview {
    NavigationView {
        CategoriesScreen(
            gameManager: GameManager()
        )
    }
}
