//
//  RulesView.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 22.07.25.
//

import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 49/255, green: 52/255, blue: 69/255)
                    .ignoresSafeArea()
                
                if let url = localizedRulesURL() {
                    WebView(url: url)
                        .padding(.horizontal, 8)
                } else {
                    Text("Rules not found.")
                        .foregroundStyle(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Rules")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private func localizedRulesURL() -> URL? {
        let lang = Locale.current.language.languageCode?.identifier
        let filename: String
        
        switch lang {
        case "ru":
            filename = "rules_ru"
        case "en":
            filename = "rules_en"
        default:
            filename = "rules_en"
        }

        return Bundle.main.url(forResource: filename, withExtension: "html")
    }
}
