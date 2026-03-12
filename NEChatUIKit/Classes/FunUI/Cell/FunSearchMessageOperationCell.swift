
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import UIKit

@objcMembers
open class FunSearchMessageOperationCell: OperationCell {
  lazy var lineView: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = UIColor(hexString: "#C9C9C9")
    return line
  }()

  override open func commonUI() {
    super.commonUI()

    imageView.removeFromSuperview()

    label.textColor = .funChatQuickHistoryCellTitleTextColor
    label.font = .systemFont(ofSize: 16)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
    ])

    label.updateLayoutConstraint(firstItem: label, secondItem: label, attribute: .height, constant: 48)

    contentView.addSubview(lineView)
    NSLayoutConstraint.activate([
      lineView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
      lineView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 20),
      lineView.widthAnchor.constraint(equalToConstant: 0.25),
    ])
  }
}
