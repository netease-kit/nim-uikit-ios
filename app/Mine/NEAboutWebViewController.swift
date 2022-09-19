
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import WebKit
import NEKitCommonUI

class NEAboutWebViewController: NEBaseViewController {
  private var loadUrl: String = ""

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpSubViews()
  }

  init(url: String) {
    super.init(nibName: nil, bundle: nil)
    loadUrl = url
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setUpSubViews() {
    title = NSLocalizedString("product_intro", comment: "")
    guard let requestUrl = URL(string: loadUrl) else {
      return
    }

    let webview = WKWebView()
    webview.translatesAutoresizingMaskIntoConstraints = false
    let request = URLRequest(url: requestUrl)
    webview.load(request)
    view.addSubview(webview)

    NSLayoutConstraint.activate([
      webview.leftAnchor.constraint(equalTo: view.leftAnchor),
      webview.rightAnchor.constraint(equalTo: view.rightAnchor),
      webview.topAnchor.constraint(equalTo: view.topAnchor),
      webview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}
