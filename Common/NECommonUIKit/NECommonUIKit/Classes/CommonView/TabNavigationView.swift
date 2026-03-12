
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objc
public protocol TabNavigationViewDelegate: AnyObject {
  func didClickAddBtn()
  func searchAction()
}

@objcMembers
open class TabNavigationView: UIView {
  public weak var delegate: TabNavigationViewDelegate?
  public var titleBarBottomLineHeight = 0.5

  public lazy var brandBtn: UIButton = {
    let button = UIButton()
    button.accessibilityIdentifier = "id.titleBarTitle"
    button.setTitle(commonLocalizable("appName"), for: .normal)
    button.setImage(coreLoader.loadImage("brand_yunxin"), for: .normal)
    button.layoutButtonImage(style: .left, space: 12)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitleColor(UIColor.black, for: .normal)
    button.titleLabel?.font = NEConstant.textFont("PingFangSC-Medium", 20)
    return button
  }()

  public lazy var navigationTitle: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.isHidden = true
    label.accessibilityIdentifier = "id.titleBarTitle"
    return label
  }()

  public lazy var searchBtn: UIButton = {
    let button = UIButton()
    button.accessibilityIdentifier = "id.titleBarSearchImg"
    button.setImage(coreLoader.loadImage("nav_search"), for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(searchBtnClick), for: .touchUpInside)
    return button
  }()

  public lazy var addBtn: ExpandButton = {
    let button = ExpandButton()
    button.accessibilityIdentifier = "id.titleBarMoreImg"
    button.setImage(coreLoader.loadImage("nav_add"), for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(addBtnClick), for: .touchUpInside)
    return button
  }()

  public lazy var titleBarView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.addSubview(brandBtn)
    view.addSubview(navigationTitle)
    view.addSubview(searchBtn)
    view.addSubview(addBtn)

    NSLayoutConstraint.activate([
      brandBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
      brandBtn.leftAnchor.constraint(
        equalTo: view.leftAnchor,
        constant: NEConstant.screenInterval
      ),
    ])

    NSLayoutConstraint.activate([
      navigationTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      navigationTitle.centerYAnchor.constraint(equalTo: brandBtn.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      addBtn.centerYAnchor.constraint(equalTo: brandBtn.centerYAnchor),
      addBtn.rightAnchor.constraint(
        equalTo: view.rightAnchor,
        constant: -NEConstant.screenInterval
      ),
      addBtn.widthAnchor.constraint(equalToConstant: 20),
      addBtn.heightAnchor.constraint(equalToConstant: 20),
    ])

    NSLayoutConstraint.activate([
      searchBtn.centerYAnchor.constraint(equalTo: brandBtn.centerYAnchor),
      searchBtn.rightAnchor.constraint(
        equalTo: addBtn.leftAnchor,
        constant: -NEConstant.screenInterval
      ),
      searchBtn.widthAnchor.constraint(equalToConstant: 20),
      searchBtn.heightAnchor.constraint(equalToConstant: 20),
    ])

    return view
  }()

  public lazy var titleBarBottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor(hexString: "0xDBE0E8")
    return view
  }()

  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
    backgroundColor = .clear
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupSubviews() {
    addSubview(titleBarView)
    addSubview(titleBarBottomLine)

    NSLayoutConstraint.activate([
      titleBarView.topAnchor.constraint(equalTo: topAnchor),
      titleBarView.leftAnchor.constraint(equalTo: leftAnchor),
      titleBarView.rightAnchor.constraint(equalTo: rightAnchor),
      titleBarView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -titleBarBottomLineHeight),
    ])

    NSLayoutConstraint.activate([
      titleBarBottomLine.leftAnchor.constraint(equalTo: leftAnchor),
      titleBarBottomLine.rightAnchor.constraint(equalTo: rightAnchor),
      titleBarBottomLine.bottomAnchor.constraint(equalTo: bottomAnchor),
      titleBarBottomLine.heightAnchor.constraint(equalToConstant: titleBarBottomLineHeight),
    ])
  }
}

extension TabNavigationView {
  @objc open func searchBtnClick(sender: UIButton) {
    delegate?.searchAction()
  }

  @objc open func addBtnClick(sender: UIButton) {
    delegate?.didClickAddBtn()
  }
}
