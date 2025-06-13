
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objc public enum ChangeType: Int {
  case TeamName = 0
  case NickName
}

@objc
public enum TeamSettingType: Int {
  case Discuss = 0
  case Senior = 1
}

@objcMembers
open class NEBaseTeamSettingCell: CornerCell {
  /// 群设置数据模型
  var model: SettingCellModel?

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0x333333)
    label.font = NEConstant.defaultTextFont(16.0)
    label.accessibilityIdentifier = "id.titleLabel"
    return label
  }()

  public lazy var arrowView: UIImageView = {
    let imageView = UIImageView(image: coreLoader.loadImage("arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.backgroundColor = .clear
    showDefaultLine = true
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func configure(_ anyModel: Any) {
    if let m = anyModel as? SettingCellModel {
      model = m
      cornerType = m.cornerType
      titleLabel.text = m.cellName
    }
  }
}
