//
//  HistoryWebView.swift
//  StockApp
//
//  Created by Haoyu Liu on 5/1/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
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
        var parent: WebView

        init(_ parent: WebView) {
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
//import SwiftUI
//import WebKit
//
//struct WebView: UIViewRepresentable {
//    var htmlFilename: String
//    var javascript: String
//
//    func makeUIView(context: Context) -> WKWebView {
//        // Create user content controller that allows for interception of console messages
//        let contentController = WKUserContentController()
//        
//        // JavaScript that replaces the console.log function to send its messages to Swift
//        let scriptSource = """
//        var originalLog = console.log;
//        console.log = function(message) {
//            window.webkit.messageHandlers.logHandler.postMessage(message);
//            originalLog.apply(console, arguments);
//        };
//        """
//        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
//        contentController.addUserScript(userScript)
//        
//        // Add the message handler that will catch log messages
//        contentController.add(context.coordinator, name: "logHandler")
//        
//        // Configure the WKWebView with the user content controller
//        let configuration = WKWebViewConfiguration()
//        configuration.userContentController = contentController
//        
//        let webView = WKWebView(frame: .zero, configuration: configuration)
//        webView.navigationDelegate = context.coordinator
//        return webView
//    }
//
//    func updateUIView(_ uiView: WKWebView, context: Context) {
//        // Load the local HTML file into the WebView
//        if let filePath = Bundle.main.path(forResource: htmlFilename, ofType: "html") {
//            let fileURL = URL(fileURLWithPath: filePath)
//            uiView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
//    // Coordinator class to manage navigation and message handling
//    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
//        var parent: WebView
//
//        init(_ parent: WebView) {
//            self.parent = parent
//        }
//
//        // Handle navigation events
//        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//            // Execute any initial JavaScript when the page loads
//            webView.evaluateJavaScript(parent.javascript) { result, error in
//                if let error = error {
//                    print("JavaScript Error: \(error.localizedDescription)")
//                } else if let result = result {
//                    print("JavaScript Result: \(result)")
//                }
//            }
//        }
//
//        // Handle messages from the web content
//        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//            if message.name == "logHandler", let messageBody = message.body as? String {
//                print("JS log: \(messageBody)")
//            }
//        }
//    }
//}
