
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

@objcMembers
open class FunPopListView: NEBasePopListView {
  public var triangleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funConversationPopViewBg
    view.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
    return view
  }()

  override func setupUI() {
    super.setupUI()
    NSLayoutConstraint.activate([
      shadowView.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
      shadowView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8),
    ])

    popView.backgroundColor = UIColor.funConversationPopViewBg

    insertSubview(triangleView, aboveSubview: shadowView)
    NSLayoutConstraint.activate([
      triangleView.widthAnchor.constraint(equalToConstant: 11),
      triangleView.heightAnchor.constraint(equalToConstant: 11),
      triangleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -25),
      triangleView.topAnchor.constraint(equalTo: popView.topAnchor, constant: -5),
    ])
  }
}
