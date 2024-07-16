
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import UIKit
import WebKit

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
    super.init(coder: coder)
  }

  func setUpSubViews() {
    title = NSLocalizedString("product_intro", comment: "")
    navigationView.backgroundColor = .white
    navigationView.moreButton.isHidden = true
    navigationController?.navigationBar.backgroundColor = .white

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
      webview.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      webview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}
