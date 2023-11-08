
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import UIKit

@objcMembers
open class NEBaseTeamDefaultIconCell: UICollectionViewCell {
  override public init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  override public var isSelected: Bool {
    didSet {
      print("default icon select ", isSelected)
      selectBack.isHidden = !isSelected
    }
  }

  lazy var iconImage: UIImageView = {
    let image = UIImageView()
    image.translatesAutoresizingMaskIntoConstraints = false
    image.contentMode = .scaleAspectFill
    return image
  }()

  lazy var selectBack: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = NEConstant.hexRGB(0xF4F4F4)
    view.clipsToBounds = true
    view.layer.cornerRadius = 8.0
    view.isHidden = true
    return view
  }()

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupUI() {
    contentView.addSubview(selectBack)
    contentView.addSubview(iconImage)
  }
}
