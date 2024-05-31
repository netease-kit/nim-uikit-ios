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
      selectBackView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      selectBackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      selectBackView.widthAnchor.constraint(equalToConstant: 56.0),
      selectBackView.heightAnchor.constraint(equalToConstant: 56.0),
    ])

    NSLayoutConstraint.activate([
      iconImageView.centerXAnchor.constraint(equalTo: selectBackView.centerXAnchor),
      iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      iconImageView.heightAnchor.constraint(equalToConstant: 40),
      iconImageView.widthAnchor.constraint(equalToConstant: 40),
    ])
  }
}
