
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
  lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .ne_greyLine
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

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

    addSubview(lineView)
    NSLayoutConstraint.activate([
      lineView.leftAnchor.constraint(equalTo: leftAnchor),
      lineView.rightAnchor.constraint(equalTo: rightAnchor),
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor),
      lineView.heightAnchor.constraint(equalToConstant: 6),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func setData(user: User?) {
    guard let user = user else {
      return
    }

    // avatar
    if let imageUrl = user.userInfo?.avatarUrl, !imageUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      nameLabel.isHidden = true
    } else {
      avatarImage.sd_setImage(with: nil)
      avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
      nameLabel.text = user.shortName(showAlias: false, count: 2)
      nameLabel.isHidden = false
    }

    // title
    titleLabel.text = user.showName()

    detailLabel.text = "\(localizable("account")):\(user.userId ?? "")"
  }
}
