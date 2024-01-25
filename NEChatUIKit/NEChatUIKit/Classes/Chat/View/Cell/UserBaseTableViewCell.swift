
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objcMembers
open class UserBaseTableViewCell: UITableViewCell {
  public lazy var avatarImage: UIImageView = {
    let avatarImage = UIImageView()
    avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    avatarImage.clipsToBounds = true
    avatarImage.isUserInteractionEnabled = true
    avatarImage.contentMode = .scaleAspectFill
    avatarImage.accessibilityIdentifier = "id.avatar"
    return avatarImage
  }()

  public lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 12)
    nameLabel.textColor = .white
    nameLabel.text = "placeholder"
    nameLabel.accessibilityIdentifier = "id.avatar"
    return nameLabel
  }()

  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "placeholder"
    titleLabel.accessibilityIdentifier = "id.nickname"
    return titleLabel
  }()

  public var userModel: NEKitUser?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .white
    baseCommonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func baseCommonUI() {
    selectionStyle = .none
    backgroundColor = .white
    contentView.addSubview(avatarImage)
    contentView.addSubview(nameLabel)
    contentView.addSubview(titleLabel)

    // name
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
    ])

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "placeholder"
  }

  open func setModel(_ model: NEKitUser) {
    userModel = model
    nameLabel.text = model.shortName(showAlias: false, count: 2)
    titleLabel.text = model.showName()

    if let avatarURL = model.userInfo?.avatarUrl, !avatarURL.isEmpty {
      avatarImage
        .sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
          if image != nil {
            self?.avatarImage.image = image
            self?.nameLabel.isHidden = true
            self?.avatarImage.backgroundColor = .clear
          } else {
            self?.avatarImage.image = nil
            self?.nameLabel.isHidden = false
            self?.avatarImage.backgroundColor = UIColor.colorWithString(string: model.userId)
          }
        }
    } else {
      avatarImage.image = nil
      nameLabel.isHidden = false
      avatarImage.backgroundColor = UIColor.colorWithString(string: model.userId)
    }
  }
}
