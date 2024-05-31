// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import UIKit

/// 会话模块 ViewController 基类
@objcMembers
open class NEConversationBaseViewController: UIViewController, UIGestureRecognizerDelegate {
  var topConstant: CGFloat = 0
  public let navigationView = NENavigationView()

  override public var title: String? {
    get {
      super.title
    }

    set {
      super.title = newValue
      navigationView.navTitle.text = newValue
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    setupBackUI()

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      navigationView.translatesAutoresizingMaskIntoConstraints = false
      navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
      navigationView.moreButton.isHidden = true
      view.addSubview(navigationView)
      NSLayoutConstraint.activate([
        navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        navigationView.topAnchor.constraint(equalTo: view.topAnchor),
        navigationView.heightAnchor.constraint(equalToConstant: topConstant),
      ])
    }
  }

  open func setupBackUI() {
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"

    navigationItem.leftBarButtonItem = backItem
  }

  open func backEvent() {
    navigationController?.popViewController(animated: true)
  }
}
