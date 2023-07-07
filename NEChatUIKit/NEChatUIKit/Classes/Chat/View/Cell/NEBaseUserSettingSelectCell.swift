// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseUserSettingSelectCell: NEBaseUserSettingCell {
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = NEConstant.hexRGB(0x999999)
    label.font = NEConstant.defaultTextFont(14.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(arrow)
    contentView.addSubview(subTitleLabel)

    NSLayoutConstraint.activate([
      subTitleLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      subTitleLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
      subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6.0),
    ])
  }

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? UserSettingCellModel {
      subTitleLabel.text = model.subTitle
    }
  }
}
