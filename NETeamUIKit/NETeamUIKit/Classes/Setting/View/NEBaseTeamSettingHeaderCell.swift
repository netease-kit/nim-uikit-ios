
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import UIKit

@objcMembers
open class NEBaseTeamSettingHeaderCell: NEBaseTeamSettingCell {
  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.translatesAutoresizingMaskIntoConstraints = false
    header.clipsToBounds = true
    return header
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let url = model?.headerUrl, !url.isEmpty {
      headerView.sd_setImage(with: URL(string: url), completed: nil)
      headerView.setTitle("")
    } else {
      headerView.setTitle(model?.defaultHeadData ?? "")
      headerView.backgroundColor = UIColor.colorWithString(string: model?.defaultHeadData)
    }
  }

  open func setupUI() {
    contentView.addSubview(titleLabel)
    contentView.addSubview(arrow)
    contentView.addSubview(headerView)
  }
}
