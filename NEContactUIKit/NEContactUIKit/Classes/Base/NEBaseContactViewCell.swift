
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseContactViewCell: UITableViewCell {
  public lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.addSubview(nameLabel)
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
    imageView.backgroundColor = UIColor.colorWithNumber(number: 0)
    imageView.accessibilityIdentifier = "id.avatar"
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: imageView.leftAnchor, constant: 1),
      nameLabel.rightAnchor.constraint(equalTo: imageView.rightAnchor, constant: -1),
      nameLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      nameLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
    ])
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

  public lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.textColor = .white
    nameLabel.textAlignment = .center
    nameLabel.font = UIFont.systemFont(ofSize: 14.0)
    nameLabel.adjustsFontSizeToFitWidth = true
    nameLabel.accessibilityIdentifier = "id.noAvatar"
    return nameLabel
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
    contentView.addSubview(avatarImageView)
    leftConstraint = avatarImageView.leftAnchor.constraint(
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
