
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseUserSettingSwitchCell: NEBaseUserSettingCell {
  public var tSwitch: UISwitch = {
    let q = UISwitch()
    q.translatesAutoresizingMaskIntoConstraints = false
    q.onTintColor = NEConstant.hexRGB(0x337EFF)
    q.accessibilityIdentifier = "id.tSwitch"
    return q
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
    if let open = model?.switchOpen {
      tSwitch.isOn = open
    }
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(tSwitch)
    tSwitch.addTarget(self, action: #selector(switchChange(_:)), for: .touchUpInside)
  }

  open func switchChange(_ s: UISwitch) {
    if let block = model?.swichChange {
      block(s.isOn)
    }
  }
}
