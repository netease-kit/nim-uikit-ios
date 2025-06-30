
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import UIKit

@objcMembers
open class TeamTextWithDetailCell: TeamBaseTextCell {
  public var detailTitleLabel = UILabel()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    detailTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    detailTitleLabel.font = UIFont.systemFont(ofSize: 12)
    detailTitleLabel.textColor = UIColor(hexString: "#A6ADB6")
    detailTitleLabel.textAlignment = .justified
    detailTitleLabel.accessibilityIdentifier = "id.detailTitleLabel"
    contentView.addSubview(detailTitleLabel)
    NSLayoutConstraint.activate([
      detailTitleLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor),
      detailTitleLabel.rightAnchor.constraint(
        equalTo: contentView.rightAnchor,
        constant: -20
      ),
      detailTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: chat_cell_margin),
      detailTitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -chat_cell_margin),
      detailTitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
    ])
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setModel(model: TeamDetailItem) {
    super.setModel(model: model)
    detailTitleLabel.text = model.detailTitle
  }
}
