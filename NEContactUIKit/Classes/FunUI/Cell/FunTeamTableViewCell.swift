// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import UIKit

@objcMembers
open class FunTeamTableViewCell: NEBaseTeamTableViewCell {
  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .funContactLineBorderColor
    return view
  }()

  override open func commonUI() {
    super.commonUI()
    userHeaderView.layer.cornerRadius = 4
    userHeaderView.updateLayoutConstraint(firstItem: userHeaderView, secondItem: nil, attribute: .width, constant: 40)
    userHeaderView.updateLayoutConstraint(firstItem: userHeaderView, secondItem: nil, attribute: .height, constant: 40)

    titleLabel.textColor = .ne_darkText

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: userHeaderView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }
}
