// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objcMembers
open class NENavigationView: UIView {
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
    button.setTitleColor(UIColor.ne_normalTheme, for: .normal)
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
      navTitle.widthAnchor.constraint(lessThanOrEqualToConstant: NEConstant.screenWidth - leftMargin * 4 - max(backButtonWidthAnchor?.constant ?? 34, moreButtonWidthAnchor?.constant ?? 34) * 2),
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

  open func setBackButtonTitle(_ title: String) {
    backButton.isHidden = false
    backButton.setTitle(title, for: .normal)
    backButton.setImage(nil, for: .normal)
  }

  open func setBackButtonImage(_ image: UIImage?) {
    backButton.isHidden = false
    backButton.setTitle("", for: .normal)
    backButton.setImage(image, for: .normal)
  }

  open func setBackButtonWidth(_ width: CGFloat) {
    backButtonWidthAnchor?.constant = width
  }

  open func addBackButtonTarget(target: Any?, selector: Selector) {
    backButton.isHidden = false
    backButton.addTarget(target, action: selector, for: .touchUpInside)
  }

  open func setMoreButtonTitle(_ title: String) {
    moreButton.isHidden = false
    moreButton.setTitle(title, for: .normal)
    moreButton.setImage(nil, for: .normal)
  }

  open func setMoreButtonImage(_ image: UIImage?) {
    moreButton.isHidden = false
    moreButton.setTitle("", for: .normal)
    moreButton.setImage(image, for: .normal)
  }

  open func setMoreButtonWidth(_ width: CGFloat) {
    moreButtonWidthAnchor?.constant = width
  }

  open func addMoreButtonTarget(target: Any?, selector: Selector) {
    moreButton.isHidden = false
    moreButton.addTarget(target, action: selector, for: .touchUpInside)
  }

  open func setTitleBarBottomLineHeight(_ height: CGFloat) {
    titleBarBottomLineHeightAnchor?.constant = height
  }

  open func setNavigationBackgroundColor(_ color: UIColor) {
    backgroundColor = color
    titleBarBottomLine.backgroundColor = color
  }
}
