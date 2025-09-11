
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import WebKit

@objcMembers
public class NEWKWebViewController: NEBaseViewController {
  private var loadUrl: String = ""

  lazy var webview: WKWebView = {
    let webview = WKWebView()
    webview.translatesAutoresizingMaskIntoConstraints = false
    webview.navigationDelegate = self
    return webview
  }()

  override public func viewDidLoad() {
    super.viewDidLoad()
    setUpSubViews()
  }

  public init(url: String, title: String) {
    super.init(nibName: nil, bundle: nil)
    loadUrl = url
    self.title = title
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setUpSubViews() {
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true
    navigationController?.navigationBar.backgroundColor = .white

    guard let requestUrl = URL(string: loadUrl) else {
      return
    }

    let request = URLRequest(url: requestUrl)
    webview.load(request)
    view.addSubview(webview)

    NSLayoutConstraint.activate([
      webview.leftAnchor.constraint(equalTo: view.leftAnchor),
      webview.rightAnchor.constraint(equalTo: view.rightAnchor),
      webview.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      webview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension NEWKWebViewController: WKNavigationDelegate {
  // 处理页面加载失败
  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    handleWebViewError(error)
  }

  // 处理导航失败
  public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    handleWebViewError(error)
  }

  private func handleWebViewError(_ error: Error) {
    let nsError = error as NSError
    let errorCode = nsError.code

    // 常见错误类型处理
    switch errorCode {
    case NSURLErrorNotConnectedToInternet:
      showErrorAlert(message: commonLocalizable("network_error"))
    case NSURLErrorTimedOut:
      showErrorAlert(message: commonLocalizable("request_timed_out"))
    case NSURLErrorCannotFindHost, NSURLErrorBadURL:
      showErrorAlert(message: commonLocalizable("invalid_URL"))
    default:
      showErrorAlert(message: String(format: commonLocalizable("failed_to_load"), errorCode))
    }

    // 加载本地错误页面
    loadLocalErrorPage()
  }

  private func showErrorAlert(message: String) {
    DispatchQueue.main.async { [weak self] in
      self?.showSingleAlert(message: message) {
        self?.navigationController?.popViewController(animated: true)
      }
    }
  }

  private func loadLocalErrorPage() {
    let htmlContent = """
    <html>
    <body style="font-family: -apple-system; padding: 20px;">
        <h2 style="color: #FF3B30;">Page Failed to Load</h2>
        <p>Please check your internet connection or verify the URL.</p>
    </body>
    </html>
    """
    webview.loadHTMLString(htmlContent, baseURL: nil)
  }
}
