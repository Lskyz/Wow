//
//  HomeWebView.swift
//  Atwy
//

import SwiftUI
import WebKit
import YouTubeKit

struct HomeWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        // WebView 로드와 동시에 visitorData 백그라운드 pre-fetch
        if YTM.visitorData.isEmpty {
            Task.detached {
                await YTM.getVisitorData()
            }
        }
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // JS로 클릭 인터셉트 - YouTube SPA는 pushState로 이동하므로
        // navigationDelegate의 decidePolicyFor가 호출되지 않음
        let scriptSource = """
        (function() {
            // 상단 헤더 숨기기
            var style = document.createElement('style');
            style.textContent = `
                ytm-mobile-topbar-renderer,
                #header,
                .mobile-topbar-header,
                ytm-topbar-logo-renderer,
                header.yt-mobile-topbar-header {
                    display: none !important;
                }
                ytm-app, #app {
                    padding-top: 0 !important;
                }
                ytm-section-list-renderer,
                ytm-rich-grid-renderer,
                ytm-browse {
                    padding-top: 0 !important;
                    margin-top: 0 !important;
                }
                ytm-feed-filter-chip-bar-renderer {
                    margin-top: 0 !important;
                    padding-top: 0 !important;
                }
                ytm-rich-grid-renderer > .rich-grid-renderer-style {
                    padding-top: 0 !important;
                }
                ytm-promoted-sparkles-web-renderer,
                ytm-promoted-video-renderer,
                ytm-ad-slot-renderer,
                ytm-display-ad-renderer,
                ytm-companion-slot,
                ytm-promoted-sparkles-text-search-renderer,
                ytm-banner-promo-renderer,
                ytm-statement-banner-renderer,
                ytm-carousel-ad-renderer,
                ytm-shopping-ad-renderer,
                ytm-in-feed-ad-layout-renderer,
                #player-ads,
                .ytm-promoted-ad,
                [data-style="PROMOTED"],
                [aria-label*="광고"],
                [aria-label*="Sponsored"],
                [aria-label*="Ad "] {
                    display: none !important;
                }
            `;
            document.head.appendChild(style);

            // 영상 클릭 인터셉트
            document.addEventListener('click', function(e) {
                var el = e.target;
                for (var i = 0; i < 8 && el; i++, el = el.parentElement) {
                    if (el.tagName === 'A' && el.href) {
                        // 숏츠 URL: /shorts/VIDEO_ID
                        var shortsMatch = el.href.match(new RegExp('/shorts/([a-zA-Z0-9_-]{11})'));
                        if (shortsMatch) {
                            e.preventDefault();
                            e.stopPropagation();
                            window.webkit.messageHandlers.shortsHandler.postMessage(shortsMatch[1]);
                            return;
                        }
                        // 일반 영상 URL: ?v=VIDEO_ID
                        var match = el.href.match(/[?&]v=([a-zA-Z0-9_-]{11})/);
                        if (match) {
                            e.preventDefault();
                            e.stopPropagation();
                            window.webkit.messageHandlers.videoHandler.postMessage(match[1]);
                            return;
                        }
                    }
                }
            }, true);
        })();
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        // retain cycle 방지: weak wrapper 사용
        config.userContentController.add(WeakMessageHandler(context.coordinator), name: "videoHandler")
        config.userContentController.add(WeakMessageHandler(context.coordinator), name: "shortsHandler")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // 당겨서 새로고침
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        context.coordinator.webView = webView

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

    // WKUserContentController의 strong retain 방지용 weak wrapper
    class WeakMessageHandler: NSObject, WKScriptMessageHandler {
        weak var target: WKScriptMessageHandler?
        init(_ target: WKScriptMessageHandler) { self.target = target }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            target?.userContentController(controller, didReceive: message)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?

        @objc func handleRefresh(_ sender: UIRefreshControl) {
            var request = URLRequest(url: URL(string: "https://m.youtube.com")!)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            webView?.load(request)
            sender.endRefreshing()
        }

        // JS 클릭 인터셉터에서 호출됨
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let videoId = message.body as? String else { return }
            DispatchQueue.main.async {
                if message.name == "shortsHandler" {
                    ShortsLaunchModel.shared.present(videoId: videoId)
                } else if message.name == "videoHandler" {
                    SheetsModel.shared.showSheet(.watchVideo)
                    VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: videoId).withData())
                }
            }
        }

        // fullpage 로드로 watch 페이지가 열리는 경우 대비
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.host?.contains("youtube.com") == true,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value,
               navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                DispatchQueue.main.async {
                    SheetsModel.shared.showSheet(.watchVideo)
                    VideoPlayerModel.shared.loadVideo(video: YTVideo(videoId: videoId).withData())
                }
                return
            }
            decisionHandler(.allow)
        }
    }
}
