
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

@objcMembers
open class FunPopListViewController: NEBasePopListViewController {
  public var shadowViewTopAnchor: NSLayoutConstraint?

  public var triangleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funConversationPopViewBg
    view.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
    return view
  }()

  override func setupUI() {
    super.setupUI()

    let popViewHeight = CGFloat(itemDatas.count) * 32 + 16

    NSLayoutConstraint.activate([
      shadowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
      shadowView.widthAnchor.constraint(equalToConstant: popViewWidth),
      shadowView.heightAnchor.constraint(equalToConstant: popViewHeight),
    ])
    shadowViewTopAnchor = shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: NEConstant.navigationAndStatusHeight)
    shadowViewTopAnchor?.isActive = true

    view.insertSubview(triangleView, aboveSubview: shadowView)
    NSLayoutConstraint.activate([
      triangleView.widthAnchor.constraint(equalToConstant: 11),
      triangleView.heightAnchor.constraint(equalToConstant: 11),
      triangleView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25),
      triangleView.topAnchor.constraint(equalTo: popView.topAnchor, constant: -5),

    ])
  }
}
