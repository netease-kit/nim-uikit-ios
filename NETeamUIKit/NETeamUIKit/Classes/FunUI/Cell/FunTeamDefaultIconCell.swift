// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objcMembers
open class FunTeamDefaultIconCell: NEBaseTeamDefaultIconCell {
  override func setupUI() {
    super.setupUI()
    NSLayoutConstraint.activate([
      selectBack.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      selectBack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectBack.widthAnchor.constraint(equalToConstant: 56.0),
      selectBack.heightAnchor.constraint(equalToConstant: 56.0),
    ])

    NSLayoutConstraint.activate([
      iconImage.centerXAnchor.constraint(equalTo: selectBack.centerXAnchor),
      iconImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconImage.heightAnchor.constraint(equalToConstant: 40),
      iconImage.widthAnchor.constraint(equalToConstant: 40),
    ])
  }
}
