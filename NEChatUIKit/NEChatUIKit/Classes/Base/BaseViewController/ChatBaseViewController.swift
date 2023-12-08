
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class ChatBaseViewController: UIViewController, UIGestureRecognizerDelegate {
  var topConstant: CGFloat = 0
  public let navigationView = NENavigationView()

  override open var title: String? {
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
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    view.backgroundColor = NEKitChatConfig.shared.ui.messageProperties.chatViewBackground ?? .white

    if !NEKitChatConfig.shared.ui.messageProperties.showTitleBar {
      navigationController?.isNavigationBarHidden = true
      return
    }

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
      setupBackUI()
      topConstant = NEConstant.navigationAndStatusHeight
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      navigationView.translatesAutoresizingMaskIntoConstraints = false
      navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
      navigationView.addMoreButtonTarget(target: self, selector: #selector(toSetting))
      view.addSubview(navigationView)
      NSLayoutConstraint.activate([
        navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        navigationView.topAnchor.constraint(equalTo: view.topAnchor),
        navigationView.heightAnchor.constraint(equalToConstant: topConstant),
      ])
    }
  }

  private func setupBackUI() {
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    let backItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    backItem.accessibilityIdentifier = "id.backArrow"
    navigationItem.leftBarButtonItem = backItem
    navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem()
    navigationController?.navigationBar.topItem?.backBarButtonItem?.tintColor = .ne_darkText
  }

  func backEvent() {
    navigationController?.popViewController(animated: true)
  }

  func toSetting() {}
}
