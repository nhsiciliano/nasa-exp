import SwiftUI
import UIKit
import WebKit

/// Inline YouTube/Vimeo player: an iframe inside a `WKWebView`. Links that leave the player open in the browser.
struct APODVideoPlayer: UIViewRepresentable {
    let embedURL: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        load(embedURL, in: webView, coordinator: context.coordinator)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedEmbedURL != embedURL {
            load(embedURL, in: webView, coordinator: context.coordinator)
        }
    }

    private func load(_ embedURL: URL, in webView: WKWebView, coordinator: Coordinator) {
        coordinator.loadedEmbedURL = embedURL
        // YouTube rejects embeds without a Referer, so the page gets an https origin that identifies the app.
        webView.loadHTMLString(Self.html(embedding: embedURL), baseURL: Coordinator.pageOrigin)
    }

    private static func html(embedding embedURL: URL) -> String {
        let source = embedURL.absoluteString
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        return """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>html, body { margin: 0; height: 100%; background: #000; } iframe { border: 0; width: 100%; height: 100%; }</style>
        </head>
        <body>
        <iframe src="\(source)" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>
        </body>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        static let pageOrigin = URL(string: "https://\(Bundle.main.bundleIdentifier ?? "nasa-exp.app")")

        var loadedEmbedURL: URL?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url,
                  navigationAction.targetFrame?.isMainFrame == true,
                  url.scheme != "about",
                  url.host != Self.pageOrigin?.host else {
                return .allow
            }

            // "Watch on YouTube" and similar links replace the top frame; send them to the browser instead.
            _ = await UIApplication.shared.open(url)
            return .cancel
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            return nil
        }
    }
}
