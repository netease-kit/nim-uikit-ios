// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objcMembers
open class BlackListCell: NEBaseBlackListCell {
  override func commonUI() {
    super.commonUI()
    avatarImage.layer.cornerRadius = 21

    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.textColor = UIColor(
      red: 51 / 255.0,
      green: 51 / 255.0,
      blue: 51 / 255.0,
      alpha: 1.0
    )

    button.layer.borderColor = UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1).cgColor

    button.setTitleColor(UIColor(red: 0.2, green: 0.494, blue: 1, alpha: 1), for: .normal)

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  private lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.ne_greyLine
    return view
  }()
}
