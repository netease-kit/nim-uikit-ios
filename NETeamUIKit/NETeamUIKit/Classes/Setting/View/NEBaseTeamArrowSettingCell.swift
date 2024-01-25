
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseTeamArrowSettingCell: NEBaseTeamSettingCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(arrow)
  }
}
