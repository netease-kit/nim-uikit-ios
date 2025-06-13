
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class ContactTableViewCell: NEBaseContactTableViewCell {
  override open func setConfig() {
    super.setConfig()
    titleLabel.font = .systemFont(ofSize: ContactUIConfig.shared.contactProperties.itemTitleSize > 0 ? ContactUIConfig.shared.contactProperties.itemTitleSize : 14)
  }

  override open func commonUI() {
    super.commonUI()
    backgroundColor = .normalContactItemBackgroundColor
    bottomLine.backgroundColor = .normalContactItemLineBackgroundColor
  }

  override open func setupCommonCircleHeader() {
    super.setupCommonCircleHeader()
    NSLayoutConstraint.activate([
      userHeaderView.widthAnchor.constraint(equalToConstant: 36),
      userHeaderView.heightAnchor.constraint(equalToConstant: 36),
      userHeaderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    if model.contactCellType == .ContactPerson {
      bottomLine.isHidden = true
    }
  }
}
