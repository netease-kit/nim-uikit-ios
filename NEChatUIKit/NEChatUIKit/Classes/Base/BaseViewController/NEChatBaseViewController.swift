
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreKit
import UIKit

@objcMembers
open class NEChatBaseViewController: UIViewController, UIGestureRecognizerDelegate {
  public var topConstant: CGFloat = 0 {
    didSet {
      navigationViewHeightAnchor?.constant = topConstant
    }
  }

  // 自定义导航栏高度布局约束
  public var navigationViewHeightAnchor: NSLayoutConstraint?

  // 自定义导航栏
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

  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // 配置项：会话界面是否展示标题栏
    if !NEKitChatConfig.shared.ui.messageProperties.showTitleBar {
      navigationController?.isNavigationBarHidden = true
      navigationView.removeFromSuperview()
      return
    }

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      navigationController?.isNavigationBarHidden = false
      navigationView.removeFromSuperview()
      setupBackUI()
    } else {
      navigationController?.isNavigationBarHidden = true
    }
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NEKitChatConfig.shared.ui.messageProperties.chatViewBackground ?? .white

    if let useSystemNav = NEConfigManager.instance.getParameter(key: useSystemNav) as? Bool, useSystemNav {
      topConstant = NEConstant.navigationAndStatusHeight
    } else {
      topConstant = NEConstant.navigationAndStatusHeight
      navigationView.translatesAutoresizingMaskIntoConstraints = false
      navigationView.addBackButtonTarget(target: self, selector: #selector(backEvent))
      navigationView.addMoreButtonTarget(target: self, selector: #selector(toSetting))

      view.addSubview(navigationView)
      navigationViewHeightAnchor = navigationView.heightAnchor.constraint(equalToConstant: topConstant)
      navigationViewHeightAnchor?.isActive = true
      NSLayoutConstraint.activate([
        navigationView.leftAnchor.constraint(equalTo: view.leftAnchor),
        navigationView.rightAnchor.constraint(equalTo: view.rightAnchor),
        navigationView.topAnchor.constraint(equalTo: view.topAnchor),
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
