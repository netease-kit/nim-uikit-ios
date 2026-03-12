
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class FunContactTableViewCell: NEBaseContactTableViewCell {
  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    NSLayoutConstraint.activate([
      userHeaderView.widthAnchor.constraint(equalToConstant: 40),
      userHeaderView.heightAnchor.constraint(equalToConstant: 40),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func commonUI() {
    super.commonUI()
    backgroundColor = .funContactItemBackgroundColor
    bottomLine.backgroundColor = .funContactItemLineBackgroundColor
    contentView.removeLayoutConstraint(firstItem: redAngleView, seconedItem: arrowImageView, attribute: .right)
    redAngleView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10).isActive = true
  }

  override open func initSubviewsLayout() {
    if ContactUIConfig.shared.contactProperties.avatarType == .cycle {
      userHeaderView.layer.cornerRadius = 20.0
    } else if ContactUIConfig.shared.contactProperties.avatarCornerRadius > 0 {
      userHeaderView.layer.cornerRadius = ContactUIConfig.shared.contactProperties.avatarCornerRadius
    } else {
      userHeaderView.layer.cornerRadius = 4.0 // Fun UI
    }
  }

  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: ContactUIConfig.shared.contactProperties.itemTitleSize > 0 ? ContactUIConfig.shared.contactProperties.itemTitleSize : 17)
  }

  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    arrowImageView.isHidden = true
  }
}
