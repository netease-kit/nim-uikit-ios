
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import WebKit

@objcMembers
public class NEWKWebViewController: NEBaseViewController {
  private var loadUrl: String = ""

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
