//
//  WebViewLoginView.swift
//  NGA
//
//  Created by William Chen on 3/12/26.
//
//  Flow: load login page, inject JS to auto-click 密码登录, poll cookies + intercept success alert.
//

import SwiftUI
import WebKit
import Logging

/// WebView 登录：加载 NGA 登录入口，自动点击「密码登录」进入表单，用户完成验证码后提取 cookie 完成登录。
struct WebViewLoginView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var isReadyToShow = false
    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                WebViewLoginRepresentable(
                    url: URL(string: "\(Constants.API.nukeURL)?__lib=login&__act=account&login")!,
                    onReadyToShow: { isReadyToShow = true },
                    onLoginSuccess: {
                        onLoginSuccess()
                        dismiss()
                    },
                    authService: authService
                )
                .opacity(isReadyToShow ? 1 : 0)
                if !isReadyToShow {
                    ProgressView()
                }
            }
            .ignoresSafeArea()
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct WebViewLoginRepresentable: UIViewRepresentable {
    let url: URL
    let onReadyToShow: () -> Void
    let onLoginSuccess: () -> Void
    @ObservedObject var authService: AuthService

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        config.websiteDataStore = .nonPersistent()  // 每次打开登录页从空 cookies 开始，不共享 default 的残留
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebViewLoginRepresentable
        private let authService: AuthService
        private let log = Logger.for(.auth)
        private var hasCompleted = false
        private var pollTask: Task<Void, Never>?

        init(_ parent: WebViewLoginRepresentable) {
            self.parent = parent
            self.authService = parent.authService
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            log.debug("[webview] didStartProvisionalNavigation url=\(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            log.debug("[webview] didFinish url=\(webView.url?.absoluteString ?? "nil")")
            if isLoginPage(webView) {
                runInitScripts(webView: webView)
            } else {
                DispatchQueue.main.async { self.parent.onReadyToShow() }
            }
            checkCookiesAndComplete(webView: webView)
            startCookiePolling(webView: webView)
        }

        private func isLoginPage(_ webView: WKWebView) -> Bool {
            webView.url?.absoluteString.contains("__lib=login") == true
        }

        private func startCookiePolling(webView: WKWebView) {
            pollTask?.cancel()
            pollTask = Task { @MainActor in
                for i in 0..<300 {
                    guard !Task.isCancelled, !hasCompleted else { return }
                    try? await Task.sleep(for: .seconds(1))
                    if i > 0, i % 10 == 0 { log.debug("[webview] cookie poll attempt \(i)") }
                    checkCookiesAndComplete(webView: webView)
                }
            }
        }

        private func runInitScripts(webView: WKWebView) {
            let viewportScript = """
            var v = document.querySelector('meta[name="viewport"]');
            if (v) v.setAttribute('content','width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no');
            else { var m = document.createElement('meta'); m.name='viewport'; m.content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'; document.head.appendChild(m); }
            if (document.body) document.body.style.backgroundColor = 'rgb(255, 246, 223)';
            """
            webView.evaluateJavaScript(viewportScript, completionHandler: nil)

            let clickPasswordAndHideScript = """
            (function() {
              var iff = document.getElementById('iff');
              if (!iff || !iff.contentDocument) return false;
              var doc = iff.contentDocument;
              function byXpath(p) { return document.evaluate(p, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; }
              var link = byXpath('//*[@id="main"]/div/div[3]/a[2]');
              if (link) link.click();
              ['//*[@id="main"]/div/a[2]', '//*[@id="main"]/div/div[last()]'].forEach(function(p) {
                var el = byXpath(p);
                if (el) el.style.display = 'none';
              });
              return true;
            })();
            """
            var attempt = 0
            func tryInject() {
                attempt += 1
                webView.evaluateJavaScript(clickPasswordAndHideScript) { [weak self] result, _ in
                    let ok = (result as? Bool) == true
                    let done = ok || attempt >= 30
                    self?.log.debug("[webview] clickPasswordAndHide attempt=\(attempt) ok=\(ok)")
                    if done {
                        DispatchQueue.main.async { self?.parent.onReadyToShow() }
                        return
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { tryInject() }
                }
            }
            log.debug("[webview] runInitScripts, will tryInject in 0.3s")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tryInject() }
        }

        private func cookieStore(for webView: WKWebView) -> WKHTTPCookieStore {
            webView.configuration.websiteDataStore.httpCookieStore
        }

        private func checkCookiesAndComplete(webView: WKWebView) {
            cookieStore(for: webView).getAllCookies { [weak self] cookies in
                guard let self = self, !self.hasCompleted else { return }
                let ngaUid = cookies.first { $0.name == "ngaPassportUid" }
                let ngaCid = cookies.first { $0.name == "ngaPassportCid" }
                if let uidCookie = ngaUid, let cidCookie = ngaCid,
                   let uid = Int(uidCookie.value), uid > 0, !cidCookie.value.isEmpty {
                    self.hasCompleted = true
                    self.pollTask?.cancel()
                    self.log.info("[webview] login success via cookies uid=\(uid)")
                    let authService = self.authService
                    let onSuccess = self.parent.onLoginSuccess
                    Task { @MainActor in
                        await authService.completeLoginFromWebView(uid: uid, cid: cidCookie.value)
                        onSuccess()
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            log.debug("[webview] JS alert: \(message.prefix(200))")
            // On success, NGA shows an alert; cookies are already set. Check cookies and swallow alert if login ok.
            cookieStore(for: webView).getAllCookies { [weak self] cookies in
                guard let self = self else { 
                    DispatchQueue.main.async { completionHandler() }
                    return 
                }
                let ngaUid = cookies.first { $0.name == "ngaPassportUid" }
                let ngaCid = cookies.first { $0.name == "ngaPassportCid" }
                if let uidCookie = ngaUid, let cidCookie = ngaCid,
                   let uid = Int(uidCookie.value), uid > 0, !cidCookie.value.isEmpty, !self.hasCompleted {
                    self.hasCompleted = true
                    self.pollTask?.cancel()
                    self.log.info("[webview] login success via alert, uid=\(uid), swallowing alert")
                    let authService = self.authService
                    let onSuccess = self.parent.onLoginSuccess
                    DispatchQueue.main.async {
                        Task { @MainActor in
                            await authService.completeLoginFromWebView(uid: uid, cid: cidCookie.value)
                            onSuccess()
                        }
                        completionHandler()
                    }
                    return
                }
                // Error or other alert: show it to the user.
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "NGA", message: message, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "确定", style: .default) { _ in 
                        completionHandler() 
                    })
                    
                    // Find the topmost view controller to present the alert
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                          let rootVC = window.rootViewController else {
                        // Fallback: just call completion handler if we can't present
                        completionHandler()
                        return
                    }
                    
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }
                    
                    topVC.present(ac, animated: true)
                }
            }
        }
    }
}

#Preview {
    WebViewLoginView(authService: AuthService.shared) {}
}
