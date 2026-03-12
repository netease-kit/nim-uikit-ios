
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class NormalSearchMessageOperationCell: OperationCell {
  override open func commonUI() {
    super.commonUI()

    let backView = UIView()
    backView.translatesAutoresizingMaskIntoConstraints = false
    backView.backgroundColor = .normalSearchMessageCellBg
    backView.layer.cornerRadius = 24
    contentView.insertSubview(backView, belowSubview: imageView)
    NSLayoutConstraint.activate([
      backView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      backView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
      backView.widthAnchor.constraint(equalToConstant: 48),
      backView.heightAnchor.constraint(equalToConstant: 48),
    ])

    imageView.updateLayoutConstraint(firstItem: imageView, secondItem: nil, attribute: .width, constant: 48)
    imageView.updateLayoutConstraint(firstItem: imageView, secondItem: nil, attribute: .height, constant: 48)

    contentView.updateLayoutConstraint(firstItem: label, secondItem: imageView, attribute: .top, constant: 12)
  }
}
