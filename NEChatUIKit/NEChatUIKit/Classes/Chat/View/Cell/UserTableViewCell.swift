
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit

@objcMembers
public class UserTableViewCell: UITableViewCell {
  public var avatarImage = UIImageView()
  public var nameLabel = UILabel()
  public var titleLabel = UILabel()
  public var userModel: User?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    baseCommonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func baseCommonUI() {
    // avatar
    selectionStyle = .none
    backgroundColor = .white
    avatarImage.layer.cornerRadius = 21
    avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    avatarImage.clipsToBounds = true
    avatarImage.isUserInteractionEnabled = true
    contentView.addSubview(avatarImage)
    NSLayoutConstraint.activate([
      avatarImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
      avatarImage.widthAnchor.constraint(equalToConstant: 42),
      avatarImage.heightAnchor.constraint(equalToConstant: 42),
      avatarImage.topAnchor.constraint(equalTo: topAnchor, constant: 10),
    ])

    // name
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 12)
    nameLabel.textColor = .white
    nameLabel.text = "placeholder"
    contentView.addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
    ])

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "placeholder"
    titleLabel.font = UIFont.systemFont(ofSize: 16)
    titleLabel.textColor = UIColor(
      red: 51 / 255.0,
      green: 51 / 255.0,
      blue: 51 / 255.0,
      alpha: 1.0
    )
    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  public func setModel(_ model: User) {
    userModel = model
    avatarImage.backgroundColor = UIColor.colorWithString(string: model.userId)
    nameLabel.text = model.shortName(count: 2)
    titleLabel.text = model.showName()

    if let avatarURL = model.userInfo?.avatarUrl {
      avatarImage
        .sd_setImage(with: URL(string: avatarURL)) { [weak self] image, error, type, url in
          if image != nil {
            self?.avatarImage.image = image
            self?.nameLabel.isHidden = true
          } else {
            self?.avatarImage.image = nil
            self?.nameLabel.isHidden = false
          }
        }
    } else {
      avatarImage.image = nil
      nameLabel.isHidden = false
    }
  }
}
