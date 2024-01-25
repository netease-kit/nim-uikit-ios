
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamSettingRightCustomCell: TeamSettingSubtitleCell {
  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let icon = model?.rightCustomViewIcon, icon.count > 0 {
      customRightView.isHidden = false
      customRightView.setImage(coreLoader.loadImage(icon), for: .normal)
      arrow.isHidden = true
    } else {
      customRightView.isHidden = true
      arrow.isHidden = false
    }
  }

  override open func setupUI() {
    super.setupUI()

    contentView.addSubview(customRightView)
    NSLayoutConstraint.activate([
      customRightView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      customRightView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -36),
      customRightView.widthAnchor.constraint(equalToConstant: 15),
      customRightView.heightAnchor.constraint(equalToConstant: 15),
    ])
    customRightView.addTarget(
      self,
      action: #selector(customRightViewClick),
      for: .touchUpInside
    )
  }

  public lazy var customRightView: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.accessibilityIdentifier = "id.accountCopy"
    return btn
  }()

  open func customRightViewClick() {
    if let block = model?.customViewClick {
      block()
    }
  }
}
