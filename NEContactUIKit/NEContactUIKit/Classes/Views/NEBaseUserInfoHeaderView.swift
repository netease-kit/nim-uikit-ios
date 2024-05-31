
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import UIKit

@objcMembers
open class NEBaseUserInfoHeaderView: UIView {
  public var labelConstraints = [NSLayoutConstraint]()
  public lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.backgroundColor = UIColor(hexString: "#537FF4")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.accessibilityIdentifier = "id.avatar"
    return imageView
  }()

  public lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 22)
    nameLabel.textColor = .white
    return nameLabel
  }()

  public lazy var titleLabel: CopyableLabel = {
    let titleLabel = CopyableLabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
    titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    titleLabel.accessibilityIdentifier = "id.name"
    return titleLabel
  }()

  public lazy var detailLabel: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.account"
    return detailLabel
  }()

  public lazy var detailLabel2: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.commentName"
    return detailLabel
  }()

  lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .ne_greyLine
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    backgroundColor = .white
    addSubview(avatarImageView)
    addSubview(nameLabel)
    addSubview(titleLabel)
    addSubview(detailLabel)
    addSubview(lineView)

    NSLayoutConstraint.activate([
      avatarImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      avatarImageView.widthAnchor.constraint(equalToConstant: 60),
      avatarImageView.heightAnchor.constraint(equalToConstant: 60),
      avatarImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
    ])

    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImageView.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
    ])

    commonUI(showDetail: false)
  }

  func commonUI(showDetail: Bool) {
    NSLayoutConstraint.deactivate(labelConstraints)
    var titleConstraint = [NSLayoutConstraint]()
    var detailConstraint = [NSLayoutConstraint]()
    var detail2Constraint = [NSLayoutConstraint]()
    if showDetail {
      titleConstraint = [
        titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 20),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -35),
        titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: -2),
        titleLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      addSubview(detailLabel2)
      detail2Constraint = [
        detailLabel2.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel2.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel2.topAnchor.constraint(equalTo: detailLabel.bottomAnchor),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]
    } else {
      titleConstraint = [
        titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
        titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 7),
        titleLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
        detailLabel.rightAnchor.constraint(equalTo: titleLabel.rightAnchor),
        detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        detailLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      detailLabel2.removeFromSuperview()
      detail2Constraint = []
    }
    labelConstraints = titleConstraint + detailConstraint + detail2Constraint
    NSLayoutConstraint.activate(labelConstraints)
    updateConstraintsIfNeeded()
  }

  open func setData(user: NEUserWithFriend?) {
    guard let userFriend = user else {
      return
    }

    // avatar
    if let imageUrl = userFriend.user?.avatar, !imageUrl.isEmpty {
      avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      avatarImageView.backgroundColor = .clear
      nameLabel.isHidden = true
    } else {
      avatarImageView.sd_setImage(with: nil)
      avatarImageView.backgroundColor = UIColor.colorWithString(string: userFriend.user?.accountId)
      nameLabel.text = userFriend.shortName(count: 2)
      nameLabel.isHidden = false
    }

    // title
    let uid = userFriend.user?.accountId ?? ""
    if let alias = userFriend.friend?.alias, !alias.isEmpty {
      commonUI(showDetail: true)
      titleLabel.text = alias
      detailLabel.text = "\(localizable("nick")):\(userFriend.user?.name ?? uid)"
      detailLabel.copyString = userFriend.user?.name ?? uid
      detailLabel2.text = "\(localizable("account")):\(uid)"
      detailLabel2.copyString = uid
    } else {
      commonUI(showDetail: false)
      titleLabel.text = userFriend.showName()
      detailLabel.text = "\(localizable("account")):\(uid)"
      detailLabel.copyString = uid
    }
  }
}
