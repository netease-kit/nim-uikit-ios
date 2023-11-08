
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
@objcMembers
open class NEBaseContactSelectedCell: NEBaseContactTableViewCell {
  let sImage = UIImageView()

  var sModel: ContactInfo?

  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override open func commonUI() {
    super.commonUI()
    leftConstraint?.constant = 50
    contentView.addSubview(sImage)
    sImage.image = UIImage.ne_imageNamed(name: "unselect")
    sImage.translatesAutoresizingMaskIntoConstraints = false
    sImage.accessibilityIdentifier = "id.selector"
  }

  override public func setModel(_ model: ContactInfo) {
    super.setModel(model)
    if model.isSelected == false {
      sImage.isHighlighted = false
    } else {
      sImage.isHighlighted = true
    }
  }

  func setSelect() {
    sModel?.isSelected = true
    sImage.isHighlighted = true
  }

  func setUnselect() {
    sModel?.isSelected = false
    sImage.isHighlighted = false
  }
}
