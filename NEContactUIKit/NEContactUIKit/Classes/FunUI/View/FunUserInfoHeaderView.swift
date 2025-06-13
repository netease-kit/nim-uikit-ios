// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class FunUserInfoHeaderView: NEBaseUserInfoHeaderView {
  override open func commonUI() {
    super.commonUI()
    userHeaderView.layer.cornerRadius = 4

    NSLayoutConstraint.activate([
      lineView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      lineView.rightAnchor.constraint(equalTo: rightAnchor),
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
