
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
    NSLayoutConstraint.activate([
      shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant - 10),
      shadowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
    ])

    popView.backgroundColor = NEConstant.hexRGB(0xFFFFFF)
  }
}
