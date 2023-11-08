// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objcMembers
open class FunTeamTableViewCell: NEBaseTeamTableViewCell {
  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .funContactLineBorderColor
    return view
  }()

  override func commonUI() {
    super.commonUI()
    avatarImage.layer.cornerRadius = 4
    avatarImage.updateLayoutConstraint(firstItem: avatarImage, seconedItem: nil, attribute: .width, constant: 40)
    avatarImage.updateLayoutConstraint(firstItem: avatarImage, seconedItem: nil, attribute: .height, constant: 40)

    titleLabel.textColor = .ne_darkText

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
