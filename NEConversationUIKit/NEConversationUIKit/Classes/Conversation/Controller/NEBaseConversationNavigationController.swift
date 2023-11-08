// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreKit
import UIKit

@objcMembers
open class NEBaseConversationNavigationController: UIViewController, UIGestureRecognizerDelegate {
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
    view.backgroundColor = .white
    navigationController?.interactivePopGestureRecognizer?.delegate = self
    setupBackUI()

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
    } else {
      navigationController?.isNavigationBarHidden = true
      topConstant = NEConstant.navigationAndStatusHeight
      customNavigationView.translatesAutoresizingMaskIntoConstraints = false
      customNavigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
      customNavigationView.moreButton.isHidden = true
      view.addSubview(customNavigationView)
      NSLayoutConstraint.activate([
        customNavigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        customNavigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        customNavigationView.topAnchor.constraint(equalTo: view.topAnchor),
        customNavigationView.heightAnchor.constraint(equalToConstant: topConstant),
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
