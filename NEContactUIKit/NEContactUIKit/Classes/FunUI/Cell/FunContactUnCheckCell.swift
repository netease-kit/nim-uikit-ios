// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class FunContactUnCheckCell: NEBaseContactUnCheckCell {
  override func setupUI() {
    super.setupUI()
    avatarImage.layer.cornerRadius = 4
    NSLayoutConstraint.activate([
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      avatarImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      avatarImage.widthAnchor.constraint(equalToConstant: 40),
      avatarImage.heightAnchor.constraint(equalToConstant: 40),
    ])
  }
}
