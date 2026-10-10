//
//  SUWebViewController.swift
//  anyway
//
//  Created by Antigravity on 2026/10/10.
//

import UIKit
import WebKit
import SnapKit

/// 应用内统一 Web 浏览器视图控制器 —— 用于展示隐私政策、健康免责声明与服务协议等公网 HTML 文档
final class SUWebViewController: SUBaseViewController, WKNavigationDelegate {

    private let targetURL: URL?
    private let pageTitle: String
    private let fallbackResourceName: String
    private let languageCode: String
    private var hasLoadedFallback = false

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let wv = WKWebView(frame: .zero, configuration: configuration)
        wv.navigationDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        wv.backgroundColor = .systemBackground
        wv.scrollView.contentInsetAdjustmentBehavior = .automatic
        return wv
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = .systemBlue
        pv.trackTintColor = .clear
        return pv
    }()

    private var progressObservation: NSKeyValueObservation?

    init(url: URL?, pageTitle: String, fallbackResourceName: String = "privacy", languageCode: String? = nil) {
        self.targetURL = url
        self.pageTitle = pageTitle
        self.fallbackResourceName = fallbackResourceName
        self.languageCode = languageCode ?? SULocalizationManager.shared.currentLanguage.rawValue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.targetURL = nil
        self.pageTitle = ""
        self.fallbackResourceName = "privacy"
        self.languageCode = "zh-Hans"
        super.init(coder: coder)
    }

    deinit {
        progressObservation?.invalidate()
        webView.stopLoading()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = pageTitle
        setupNavItems()
        loadContent()
    }

    private func setupNavItems() {
        let reloadItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(handleReload)
        )

        let safariItem = UIBarButtonItem(
            image: UIImage(systemName: "safari"),
            style: .plain,
            target: self,
            action: #selector(handleOpenInSafari)
        )

        navigationItem.rightBarButtonItems = [reloadItem, safariItem]
    }

    override func setupSubviews() {
        super.setupSubviews()
        view.addSubview(webView)
        view.addSubview(progressView)

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.progressView.setProgress(Float(newValue), animated: true)
            if newValue >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseOut, animations: {
                    self.progressView.alpha = 0
                }) { _ in
                    self.progressView.progress = 0
                }
            } else {
                self.progressView.alpha = 1.0
            }
        }
    }

    override func setupConstraints() {
        super.setupConstraints()

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(2.5)
        }

        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadContent() {
        if let url = targetURL {
            let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10.0)
            webView.load(request)
        } else {
            loadLocalFallback()
        }
    }

    private func loadLocalFallback() {
        guard !hasLoadedFallback else { return }
        hasLoadedFallback = true

        let localURL = Bundle.main.url(forResource: fallbackResourceName, withExtension: "html") 
            ?? Bundle.main.bundleURL.appendingPathComponent("\(fallbackResourceName).html")

        if var htmlString = try? String(contentsOf: localURL, encoding: .utf8) {
            htmlString = htmlString.replacingOccurrences(
                of: "var DEFAULT_LANG = 'zh-Hans';",
                with: "var DEFAULT_LANG = '\(languageCode)';"
            )
            webView.loadHTMLString(htmlString, baseURL: Bundle.main.bundleURL)
        } else if FileManager.default.fileExists(atPath: localURL.path) {
            webView.loadFileURL(localURL, allowingReadAccessTo: Bundle.main.bundleURL)
        }
    }

    @objc private func handleReload() {
        hasLoadedFallback = false
        loadContent()
    }

    @objc private func handleOpenInSafari() {
        guard let url = targetURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            decisionHandler(.cancel)
            DispatchQueue.main.async { [weak self] in
                self?.loadLocalFallback()
            }
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.alpha = 1.0
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.alpha = 0
        let script = "if (typeof applyLanguage === 'function') { applyLanguage('\(languageCode)'); }"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.loadLocalFallback()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.loadLocalFallback()
        }
    }
}
