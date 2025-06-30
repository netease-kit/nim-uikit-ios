//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseValidationPageController: NEContactBaseViewController {
  /// 内容controller集合
  public var contentControllers = [NEContactBaseViewController]()
  var pagingViewController: NEPagingViewController?
  var pagingViewControllerTopAnchor: NSLayoutConstraint?

  public init() {
    super.init(nibName: nil, bundle: nil)
    getContentControllers()
    pagingViewController = NEPagingViewController(viewControllers: contentControllers)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()

    title = localizable("validation_message")
    initNav()
    setupPageContent()
  }

  override open func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    contentControllers.forEach { $0.viewWillDisappear(animated) }
  }

  /// 返回上一级页面
  override open func backEvent() {
    super.backEvent()
    contentControllers.forEach { $0.backEvent() }
  }

  /// 进入后台，清空未读
  override open func appEnterBackground() {
    contentControllers.forEach { $0.appEnterBackground() }
  }

  /// 获取page view 内容，在子类中实现
  open func getContentControllers() {}

  /// UI 初始化
  open func setupPageContent() {
    guard let pagingViewController = pagingViewController else {
      return
    }

    addChild(pagingViewController)
    view.addSubview(pagingViewController.view)
    pagingViewController.view.backgroundColor = .white
    pagingViewControllerTopAnchor = pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant)
    pagingViewControllerTopAnchor?.isActive = true
    pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      pagingViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
      pagingViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
      pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    pagingViewController.indicatorOptions = NEPagingIndicatorOptions.visible(
      height: 2,
      zIndex: Int.max,
      spacing: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    )
    pagingViewController.borderOptions = NEPagingBorderOptions.visible(height: 1, zIndex: Int.max, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))

    pagingViewController.didMove(toParent: self)

    if !IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth {
      pagingViewController.menuItemSize = NEPagingMenuItemSize.fixed(width: 0, height: 0)
    }
  }

  open func initNav() {
    let clearItem = UIBarButtonItem(
      title: localizable("clear"),
      style: .done,
      target: self,
      action: #selector(toSetting)
    )
    clearItem.tintColor = UIColor(hexString: "666666")
    var textAttributes = [NSAttributedString.Key: Any]()
    textAttributes[.font] = UIFont.systemFont(ofSize: 14, weight: .regular)

    clearItem.setTitleTextAttributes(textAttributes, for: .normal)
    navigationItem.rightBarButtonItem = clearItem

    navigationView.setMoreButtonTitle(localizable("clear"))
    navigationView.moreButton.setTitleColor(.ne_darkText, for: .normal)
    navigationView.titleBarBottomLine.isHidden = false
  }

  /// 清空申请，当前展示好友则清空好友申请，当前展示群聊则清空入群申请
  override open func toSetting() {
    contentControllers.forEach { $0.toSetting() }
  }
}
