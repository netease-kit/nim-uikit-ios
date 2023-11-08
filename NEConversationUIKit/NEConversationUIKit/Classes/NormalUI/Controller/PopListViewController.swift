
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import UIKit

@objcMembers
open class PopListViewController: NEBasePopListViewController {
  override func setupUI() {
    super.setupUI()
    let popViewHeight = CGFloat(itemDatas.count) * 32 + 16
    NSLayoutConstraint.activate([
      shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      shadowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
      shadowView.widthAnchor.constraint(equalToConstant: popViewWidth),
      shadowView.heightAnchor.constraint(equalToConstant: popViewHeight),
    ])

    popView.backgroundColor = NEConstant.hexRGB(0xFFFFFF)
  }
}
