//
//  YouTubeView.swift
//  StrokeSense
//
//  Created by Sohail Guller on 12/26/24.
//

import SwiftUI
import WebKit

struct YouTubeView: UIViewRepresentable {
    let videoID: String

    // YouTube rejects embeds that don't identify the embedding app (error 152/153),
    // so the player page is loaded with an https origin derived from the bundle ID.
    private static let origin = "https://\((Bundle.main.bundleIdentifier ?? "com.StrokeSense").lowercased())"

    class Coordinator {
        var loadedVideoID: String?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only reload when the video changes; SwiftUI calls this on every view update.
        guard context.coordinator.loadedVideoID != videoID else { return }
        context.coordinator.loadedVideoID = videoID
        uiView.loadHTMLString(embedHTML, baseURL: URL(string: Self.origin))
    }

    private var embedHTML: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
          html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
          iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
        <iframe
          src="https://www.youtube.com/embed/\(videoID)?playsinline=1&rel=0&origin=\(Self.origin)"
          referrerpolicy="strict-origin-when-cross-origin"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          allowfullscreen>
        </iframe>
        </body>
        </html>
        """
    }
}


#Preview {
    YouTubeView(videoID: "OSTMKBLDoLg")
}
