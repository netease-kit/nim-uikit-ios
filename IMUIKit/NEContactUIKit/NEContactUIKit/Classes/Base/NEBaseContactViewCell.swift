
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseContactViewCell: UITableViewCell {
  // 头像
  public lazy var userHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(14.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  public lazy var redAngleView: RedAngleLabel = {
    let label = RedAngleLabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12)
    label.textColor = .white
    label.text = "99+"
    label.backgroundColor = NEConstant.hexRGB(0xF24957)
    label.textInsets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
    label.layer.cornerRadius = 9
    label.clipsToBounds = true
    label.isHidden = true
    label.accessibilityIdentifier = "id.unread"
    return label
  }()

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "333333")
    label.accessibilityIdentifier = "id.name"
    return label
  }()

  public lazy var optionLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "333333")
    label.accessibilityIdentifier = "id.action"
    return label
  }()

  var leftConstraint: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupCommonCircleHeader() {
    contentView.addSubview(userHeaderView)
    leftConstraint = userHeaderView.leftAnchor.constraint(
      equalTo: contentView.leftAnchor,
      constant: 20
    )
    leftConstraint?.isActive = true
  }
}
