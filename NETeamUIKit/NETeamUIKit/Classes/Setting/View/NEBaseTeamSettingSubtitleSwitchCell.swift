
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseTeamSettingSubtitleSwitchCell: NEBaseTeamSettingSwitchCell {
  public lazy var subTitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = NEConstant.hexRGB(0x999999)
    label.font = NEConstant.defaultTextFont(14.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.subTitleValue"
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

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    subTitleLabel.text = model?.subTitle
  }

  override open func setupUI() {
    super.setupUI()
    contentView.addSubview(subTitleLabel)
  }
}
