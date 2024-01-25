
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseContactViewCell: UITableViewCell {
  public lazy var avatarImage: UIImageView = {
    let avatar = UIImageView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.addSubview(nameLabel)
    avatar.clipsToBounds = true
    avatar.contentMode = .scaleAspectFill
    avatar.backgroundColor = UIColor.colorWithNumber(number: 0)
    avatar.accessibilityIdentifier = "id.avatar"
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatar.leftAnchor, constant: 1),
      nameLabel.rightAnchor.constraint(equalTo: avatar.rightAnchor, constant: -1),
      nameLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      nameLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
    ])
    return avatar
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

  public lazy var nameLabel: UILabel = {
    let name = UILabel()
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textColor = .white
    name.textAlignment = .center
    name.font = UIFont.systemFont(ofSize: 14.0)
    name.adjustsFontSizeToFitWidth = true
    name.accessibilityIdentifier = "id.noAvatar"
    return name
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
    contentView.addSubview(avatarImage)
    leftConstraint = avatarImage.leftAnchor.constraint(
      equalTo: contentView.leftAnchor,
      constant: 20
    )
    leftConstraint?.isActive = true
  }

  func showNameOnCircleHeader(_ name: String) {
    nameLabel.text = name
      .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
  }
}
