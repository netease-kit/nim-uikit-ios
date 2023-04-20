
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ContactBaseViewCell: UITableViewCell {
  public lazy var avatarImage: UIImageView = {
    let avatar = UIImageView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.addSubview(nameLabel)
    avatar.clipsToBounds = true
    avatar.contentMode = .scaleAspectFill
    avatar.backgroundColor = UIColor.colorWithNumber(number: 0)
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
    return label
  }()

  public lazy var nameLabel: UILabel = {
    let name = UILabel()
    name.translatesAutoresizingMaskIntoConstraints = false
    name.textColor = .white
    name.textAlignment = .center
    name.font = UIFont.systemFont(ofSize: 14.0)
    name.adjustsFontSizeToFitWidth = true
    return name
  }()

  public lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "333333")
    return label
  }()

  public lazy var optionLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textColor = UIColor(hexString: "333333")
    return label
  }()

  var leftConstraint: NSLayoutConstraint?

  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupCommonCircleHeader() {
    avatarImage.layer.cornerRadius = 18
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(avatarImage)
    leftConstraint = avatarImage.leftAnchor.constraint(
      equalTo: contentView.leftAnchor,
      constant: 20
    )
    leftConstraint?.isActive = true
    NSLayoutConstraint.activate([
      avatarImage.widthAnchor.constraint(equalToConstant: 36),
      avatarImage.heightAnchor.constraint(equalToConstant: 36),
      avatarImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
    ])
  }

  func showNameOnCircleHeader(_ name: String) {
    nameLabel.text = name
      .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
  }
}
