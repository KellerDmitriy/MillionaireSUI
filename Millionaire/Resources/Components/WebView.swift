//
//  WebView.swift
//  Millionaire
//
//  Created by Aleksandr Meshchenko on 22.07.25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        // Устанавливаем фон сразу — до загрузки
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 49/255, green: 52/255, blue: 69/255, alpha: 1.0)
        webView.scrollView.backgroundColor = webView.backgroundColor

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
