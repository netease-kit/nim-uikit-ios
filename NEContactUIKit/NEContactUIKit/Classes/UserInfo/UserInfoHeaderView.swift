
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECoreIMKit

@objcMembers
public class UserInfoHeaderView: UIView {
  public var avatarImage = UIImageView()
  public var nameLabel = UILabel()
  public var titleLabel = UILabel()
  public var detailLabel = UILabel()
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    avatarImage.layer.cornerRadius = 30
    avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    avatarImage.contentMode = .scaleAspectFill
    avatarImage.clipsToBounds = true
    addSubview(avatarImage)
    NSLayoutConstraint.activate([
      avatarImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      avatarImage.widthAnchor.constraint(equalToConstant: 60),
      avatarImage.heightAnchor.constraint(equalToConstant: 60),
      avatarImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
    ])

    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 22)
    nameLabel.textColor = .white
    addSubview(nameLabel)
    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
    ])

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
    titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 20),
      titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: 25),
    ])

    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.boldSystemFont(ofSize: 16)
    detailLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    addSubview(detailLabel)
    NSLayoutConstraint.activate([
      detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
      detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
      detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      detailLabel.heightAnchor.constraint(equalToConstant: 22),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setData(user: User?) {
    guard let user = user else {
      return
    }
    avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
    // avatar
    if let imageUrl = user.userInfo?.avatarUrl {
      avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      nameLabel.isHidden = true
    }
    detailLabel.text = user.userId
    // title
    var showName = user.alias?.count ?? 0 > 0 ? user.alias : user.userInfo?.nickName
    if showName == nil || showName?.count == 0 {
      showName = user.userId
    }
    if let name = showName {
      titleLabel.text = name
      if avatarImage.image == nil {
        nameLabel.text = name
          .count > 2 ? String(name[name.index(name.endIndex, offsetBy: -2)...]) : name
      }
    }
  }
}
