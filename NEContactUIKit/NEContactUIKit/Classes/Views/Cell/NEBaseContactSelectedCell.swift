
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseContactSelectedCell: NEBaseContactTableViewCell {
  let sImageView = UIImageView()

  var sModel: ContactInfo?

  override open func commonUI() {
    super.commonUI()
    leftConstraint?.constant = 50
    contentView.addSubview(sImageView)
    sImageView.image = UIImage.ne_imageNamed(name: "unselect")
    sImageView.translatesAutoresizingMaskIntoConstraints = false
    sImageView.accessibilityIdentifier = "id.selector"
  }

  /// 重写 setModel 方法，设置 sImageView
  /// - Parameter model: ContactInfo
  override open func setModel(_ model: ContactInfo) {
    super.setModel(model)
    sImageView.isHighlighted = model.isSelected
  }
}
