// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEChatKit

@objcMembers
open class NENavigationView: UIView {
  /// 导航栏动作（返回 / 右侧按钮）的文案、图标、启用态或显隐发生变化。
  ///
  /// 需要跟随导航栏状态刷新外部容器的场景（例如折叠屏侧栏）可以监听；
  /// 名称字符串与 `NEAdaptiveUIKit` 中的同名常量保持一致，双方不新增编译依赖。
  public static let didChangeActionsNotification =
    Notification.Name("NENavigationViewDidChangeActions")

  public var bottomMargin: CGFloat = 12
  public var leftMargin: CGFloat = 20
  public var titleBarBottomLineHeightAnchor: NSLayoutConstraint?
  public var backButtonWidthAnchor: NSLayoutConstraint?
  public var moreButtonWidthAnchor: NSLayoutConstraint?

  public lazy var backButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(CommonUIConfig.shared.backArrowImage, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.setTitleColor(.ne_darkText, for: .normal)
    button.contentHorizontalAlignment = .left
    button.accessibilityIdentifier = "id.backArrow"
    return button
  }()

  public lazy var navTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.textAlignment = .center
    label.text = ""
    label.accessibilityIdentifier = "id.title"
    return label
  }()

  public lazy var moreButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(coreLoader.loadImage("three_point"), for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16)
    button.setTitleColor(UIColor.neUIKitDefaultPrimaryColor, for: .normal)
    button.contentHorizontalAlignment = .right
    button.accessibilityIdentifier = "id.threePoint"
    return button
  }()

  public lazy var titleBarView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(navTitle)
    view.addSubview(backButton)
    view.addSubview(moreButton)

    backButtonWidthAnchor = backButton.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 34)
    backButtonWidthAnchor?.isActive = true
    NSLayoutConstraint.activate([
      backButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: leftMargin),
      backButton.centerYAnchor.constraint(equalTo: navTitle.centerYAnchor),
      backButton.heightAnchor.constraint(equalToConstant: 32),
    ])

    moreButtonWidthAnchor = moreButton.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 60 : 34)
    moreButtonWidthAnchor?.isActive = true
    NSLayoutConstraint.activate([
      moreButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -leftMargin),
      moreButton.centerYAnchor.constraint(equalTo: navTitle.centerYAnchor),
      moreButton.heightAnchor.constraint(equalToConstant: 32),
    ])

    NSLayoutConstraint.activate([
      navTitle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomMargin),
      navTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      // Resolve the title width from this navigation view, not the physical
      // screen. Settings pages can be hosted in Duo's narrower detail column.
      navTitle.widthAnchor.constraint(
        lessThanOrEqualTo: view.widthAnchor,
        constant: -leftMargin * 4 - max(backButtonWidthAnchor?.constant ?? 34,
                                        moreButtonWidthAnchor?.constant ?? 34) * 2
      ),
    ])

    return view
  }()

  public lazy var titleBarBottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "#E9EFF5")
    view.isHidden = true
    return view
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    addSubview(titleBarView)
    addSubview(titleBarBottomLine)
    backgroundColor = .clear

    titleBarBottomLineHeightAnchor = titleBarBottomLine.heightAnchor.constraint(equalToConstant: 0.5)
    titleBarBottomLineHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleBarBottomLine.leftAnchor.constraint(equalTo: leftAnchor),
      titleBarBottomLine.rightAnchor.constraint(equalTo: rightAnchor),
      titleBarBottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    NSLayoutConstraint.activate([
      titleBarView.topAnchor.constraint(equalTo: topAnchor),
      titleBarView.leftAnchor.constraint(equalTo: leftAnchor),
      titleBarView.rightAnchor.constraint(equalTo: rightAnchor),
      titleBarView.bottomAnchor.constraint(equalTo: titleBarBottomLine.topAnchor),
    ])
  }

  /// 统一返回按钮样式：所有返回入口都使用皮肤统一的返回箭头，不再显示
  /// 「取消」「关闭」「返回」等文本。传入的标题只作为无障碍标签保留，
  /// 让读屏仍能读出原入口语义。
  open func setBackButtonTitle(_ title: String) {
    backButton.isHidden = false
    backButton.setTitle("", for: .normal)
    backButton.setImage(CommonUIConfig.shared.backArrowImage, for: .normal)
    backButton.accessibilityLabel = title
    notifyActionsChanged()
  }

  open func setBackButtonImage(_ image: UIImage?) {
    backButton.isHidden = false
    backButton.setTitle("", for: .normal)
    backButton.setImage(image, for: .normal)
    notifyActionsChanged()
  }

  /// 页面直接修改 `backButton` / `moreButton`（例如动态数量文案）后调用，
  /// 通知外部容器重新读取导航栏动作。
  open func notifyActionsChanged() {
    NotificationCenter.default.post(name: NENavigationView.didChangeActionsNotification, object: self)
  }

  open func setBackButtonWidth(_ width: CGFloat) {
    backButtonWidthAnchor?.constant = width
  }

  open func addBackButtonTarget(target: Any?, selector: Selector) {
    backButton.isHidden = false
    backButton.addTarget(target, action: selector, for: .touchUpInside)
  }

  open func setMoreButtonTitle(_ title: String, _ color: UIColor = .neUIKitDefaultPrimaryColor) {
    moreButton.isHidden = false
    moreButton.setTitle(title, for: .normal)
    moreButton.setImage(nil, for: .normal)
    moreButton.setTitleColor(color, for: .normal)
    notifyActionsChanged()
  }

  open func setMoreButtonImage(_ image: UIImage?) {
    moreButton.isHidden = false
    moreButton.setTitle("", for: .normal)
    moreButton.setImage(image, for: .normal)
    notifyActionsChanged()
  }

  open func setMoreButtonWidth(_ width: CGFloat) {
    moreButtonWidthAnchor?.constant = width
  }

  open func addMoreButtonTarget(target: Any?, selector: Selector) {
    moreButton.isHidden = false
    moreButton.addTarget(target, action: selector, for: .touchUpInside)
    notifyActionsChanged()
  }

  open func setTitleBarBottomLineHeight(_ height: CGFloat) {
    titleBarBottomLineHeightAnchor?.constant = height
  }

  open func setNavigationBackgroundColor(_ color: UIColor) {
    backgroundColor = color
    titleBarBottomLine.backgroundColor = color
  }
}
