
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit
import NECommonKit

@objcMembers
open class PopListItem: NSObject {
  public typealias PopListClick = () -> Void
  public var image: UIImage?
  public var showName: String?
  public var showNameColor: UIColor = NEConstant.hexRGB(0x333333)
  public var completion: PopListClick?

  override public init() {}
}

@objcMembers
open class NEBasePopListViewController: UIViewController {
  public var itemDatas = [PopListItem]()
  public let shadowView = UIView()
  public var buttonHeight: CGFloat = 32.0
  let popView = UIView()
  public var popViewWidth: CGFloat = 122.0
  public var popViewRadius: CGFloat = 8.0

  override public func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    removeSelf()
  }

  func setupUI() {
    view.backgroundColor = .clear

    shadowView.translatesAutoresizingMaskIntoConstraints = false
    shadowView.backgroundColor = .clear
    view.addSubview(shadowView)
    shadowView.clipsToBounds = false
    shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
    shadowView.layer.shadowColor = NEConstant.hexRGB(0x85888C).cgColor
    shadowView.layer.shadowOpacity = 0.25
    shadowView.layer.shadowRadius = 7

    shadowView.addSubview(popView)
    popView.clipsToBounds = true
    popView.layer.cornerRadius = popViewRadius
    popView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      popView.topAnchor.constraint(equalTo: shadowView.topAnchor),
      popView.rightAnchor.constraint(equalTo: shadowView.rightAnchor),
      popView.leftAnchor.constraint(equalTo: shadowView.leftAnchor),
      popView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
    ])

    let offset: CGFloat = 8
    for index in 0 ..< itemDatas.count {
      let item = itemDatas[index]
      let itemBtn = UIButton()
      itemBtn.tag = index
      itemBtn.translatesAutoresizingMaskIntoConstraints = false
      if let image = item.image {
        itemBtn.setImage(image, for: .normal)
        itemBtn.layoutButtonImage(style: .left, space: 6)
      }
      itemBtn.setTitle(item.showName, for: .normal)
      itemBtn.setTitleColor(item.showNameColor, for: .normal)
      itemBtn.titleLabel?.font = NEConstant.defaultTextFont(14.0)
      itemBtn.layoutButtonImage(style: .left, space: 6)
      itemBtn.addTarget(self, action: #selector(itemClick(_:)), for: .touchUpInside)
      itemBtn.contentHorizontalAlignment = .left

      popView.addSubview(itemBtn)
      NSLayoutConstraint.activate([
        itemBtn.topAnchor.constraint(
          equalTo: popView.topAnchor,
          constant: offset + CGFloat(index * 32)
        ),
        itemBtn.leftAnchor.constraint(equalTo: popView.leftAnchor, constant: 15),
        itemBtn.rightAnchor.constraint(equalTo: popView.rightAnchor, constant: -4),
        itemBtn.heightAnchor.constraint(equalToConstant: 32),
      ])
    }
  }

  func itemClick(_ sender: UIButton) {
    print("item click")
    let index = sender.tag
    let item = itemDatas[index]
    if let block = item.completion {
      block()
    }
    removeSelf()
  }

  public func removeSelf() {
    view.removeFromSuperview()
  }

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    print("pop list view touchesBegan")
    removeSelf()
  }
}
