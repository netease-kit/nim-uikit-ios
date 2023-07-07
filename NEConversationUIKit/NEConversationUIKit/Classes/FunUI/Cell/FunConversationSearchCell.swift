
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunConversationSearchCell: NEBaseConversationSearchCell {
  override open func setupSubviews() {
    super.setupSubviews()
    headImge.layer.cornerRadius = 4.0

    headImge.updateLayoutConstraint(firstItem: headImge, seconedItem: nil, attribute: .width, constant: 40)
    headImge.updateLayoutConstraint(firstItem: headImge, seconedItem: nil, attribute: .height, constant: 40)

    let bottomLine = UIView()
    bottomLine.translatesAutoresizingMaskIntoConstraints = false
    bottomLine.backgroundColor = .funConversationLineBorderColor
    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: headImge.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  override func getRangeTextColor() -> UIColor {
    UIColor.funConversationThemeColor
  }
}
