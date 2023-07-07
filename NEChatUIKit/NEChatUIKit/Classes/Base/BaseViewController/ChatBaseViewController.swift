
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreKit
import NECommonUIKit

@objcMembers
open class ChatBaseViewController: UIViewController, UIGestureRecognizerDelegate {
  var topConstant: CGFloat = 0
  public let customNavigationView = NENavigationView()

  override open var title: String? {
    get {
      super.title
    }

    set {
      super.title = newValue
      customNavigationView.navTitle.text = newValue
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    view.backgroundColor = NEKitChatConfig.shared.ui.chatViewBackground ?? .white

    if !NEKitChatConfig.shared.ui.showTitleBar {
      navigationController?.isNavigationBarHidden = true
      return
    }

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
      setupBackUI()
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      customNavigationView.translatesAutoresizingMaskIntoConstraints = false
      customNavigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
      customNavigationView.addMoreButtonTarget(target: self, selector: #selector(toSetting))
      view.addSubview(customNavigationView)
      NSLayoutConstraint.activate([
        customNavigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        customNavigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        customNavigationView.topAnchor.constraint(equalTo: view.topAnchor),
        customNavigationView.heightAnchor.constraint(equalToConstant: topConstant),
      ])
    }
  }

  private func setupBackUI() {
    let image = UIImage.ne_imageNamed(name: "backArrow")?.withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: image,
      style: .plain,
      target: self,
      action: #selector(backEvent)
    )
    navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem()
    navigationController?.navigationBar.topItem?.backBarButtonItem?.tintColor = .ne_darkText
  }

  func backEvent() {
    navigationController?.popViewController(animated: true)
  }

  func toSetting() {}
}
