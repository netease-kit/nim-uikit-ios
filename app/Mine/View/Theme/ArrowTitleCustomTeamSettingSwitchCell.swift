//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NECommonUIKit
import UIKit

class ArrowTitleCustomTeamSettingSwitchCell: CustomTeamArrowSettingCell {
  /// 选项文本
  lazy var selectLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = NEConstant.hexRGB(0x333333)
    label.font = NEConstant.defaultTextFont(16.0)
    label.textAlignment = .right
    return label
  }()

  override func setupUI() {
    super.setupUI()
    if let backView = arrowView.superview {
      backView.addSubview(selectLabel)
      NSLayoutConstraint.activate([
        selectLabel.rightAnchor.constraint(equalTo: arrowView.leftAnchor, constant: -5),
        selectLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ])
    }
  }

  override func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? CustomSettingCellModel {
      selectLabel.text = model.subTitle
    }
  }
}
