
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunConversationSearchCell: NEBaseConversationSearchCell {
  /// 分隔线视图
  lazy var bottomLine: UIView = {
    let bottomLine = UIView()
    bottomLine.translatesAutoresizingMaskIntoConstraints = false
    bottomLine.backgroundColor = .funConversationLineBorderColor
    return bottomLine
  }()

  /// UI 初始化
  override open func setupSubviews() {
    super.setupSubviews()
    headImageView.layer.cornerRadius = 4.0

    headImageView.updateLayoutConstraint(firstItem: headImageView, seconedItem: nil, attribute: .width, constant: 40)
    headImageView.updateLayoutConstraint(firstItem: headImageView, seconedItem: nil, attribute: .height, constant: 40)

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: headImageView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  override func getRangeTextColor() -> UIColor {
    UIColor.funConversationThemeColor
  }
}
