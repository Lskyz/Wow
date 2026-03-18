//
//  HomeWebView.swift
//  Atwy
//

import SwiftUI
import WebKit
import YouTubeKit

struct HomeWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // 모바일 YouTube처럼 보이도록 유저에이전트 설정
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        injectCookies(into: webView) {
            var request = URLRequest(url: URL(string: "https://m.youtube.com")!)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func injectCookies(into webView: WKWebView, completion: @escaping () -> Void) {
        let cookieString = APIKeyModel.shared.googleCookies
        guard !cookieString.isEmpty else {
            completion()
            return
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let parts = cookieString.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }

        let group = DispatchGroup()
        for part in parts {
            let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2 else { continue }
            let name = kv[0].trimmingCharacters(in: .whitespaces)
            let value = kv[1].trimmingCharacters(in: .whitespaces)

            let props: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: ".youtube.com",
                .path: "/",
                .secure: "TRUE",
                .version: "1"
            ]
            if let cookie = HTTPCookie(properties: props) {
                group.enter()
                cookieStore.setCookie(cookie) { group.leave() }
            }
        }
        group.notify(queue: .main) { completion() }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url,
                  let host = url.host, host.contains("youtube.com"),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value else {
                decisionHandler(.allow)
                return
            }
            // 영상 클릭 시 앱 플레이어로 열기
            decisionHandler(.cancel)
            let video = YTVideo(videoId: videoId)
            DispatchQueue.main.async {
                VideoPlayerModel.shared.loadVideo(video: video.withData())
            }
        }
    }
}
