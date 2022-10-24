
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class UserSettingSwitchCell: UserSettingBaseCell {
  var tSwitch: UISwitch = {
    let q = UISwitch()
    q.translatesAutoresizingMaskIntoConstraints = false
    q.onTintColor = NEConstant.hexRGB(0x337EFF)
    return q
  }()

  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let open = model?.switchOpen {
      tSwitch.isOn = open
    }
  }

  func setupUI() {
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 36),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -84),
    ])

    contentView.addSubview(tSwitch)
    NSLayoutConstraint.activate([
      tSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      tSwitch.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
    ])
    tSwitch.addTarget(self, action: #selector(switchChange(_:)), for: .touchUpInside)
  }

  func switchChange(_ s: UISwitch) {
    if let block = model?.swichChange {
      block(s.isOn)
    }
  }
}
