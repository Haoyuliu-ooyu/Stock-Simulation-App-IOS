//
//  WebView.swift
//  StockApp
//
//  Created by Haoyu Liu on 4/29/24.
//

import SwiftUI
import WebKit

struct HourlyWebView: UIViewRepresentable {
    var htmlFilename: String
    var javascript: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let filePath = Bundle.main.path(forResource: htmlFilename, ofType: "html") {
            let fileURL = URL(fileURLWithPath: filePath)
            uiView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HourlyWebView

        init(_ parent: HourlyWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript(parent.javascript) { result, error in
                if let error = error {
                    print("JavaScript Error: \(error.localizedDescription)")
                } else {
                    print("JavaScript Result: \(String(describing: result))")
                }
            }
        }
    }
}
