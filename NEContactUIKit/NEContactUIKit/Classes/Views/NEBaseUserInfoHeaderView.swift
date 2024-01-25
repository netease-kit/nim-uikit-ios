
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import UIKit

@objcMembers
open class NEBaseUserInfoHeaderView: UIView {
  public var labelConstraints = [NSLayoutConstraint]()
  public lazy var avatarImage: UIImageView = {
    let avatarImage = UIImageView()
    avatarImage.backgroundColor = UIColor(hexString: "#537FF4")
    avatarImage.translatesAutoresizingMaskIntoConstraints = false
    avatarImage.contentMode = .scaleAspectFill
    avatarImage.clipsToBounds = true
    avatarImage.accessibilityIdentifier = "id.avatar"
    return avatarImage
  }()

  public lazy var nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.textAlignment = .center
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = UIFont.systemFont(ofSize: 22)
    nameLabel.textColor = .white
    return nameLabel
  }()

  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
    titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    titleLabel.accessibilityIdentifier = "id.name"
    return titleLabel
  }()

  public lazy var detailLabel: UILabel = {
    let detailLabel = UILabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.account"
    return detailLabel
  }()

  public lazy var detailLabel2: UILabel = {
    let detailLabel = UILabel()
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
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    backgroundColor = .white
    addSubview(avatarImage)
    addSubview(nameLabel)
    addSubview(titleLabel)
    addSubview(detailLabel)
    addSubview(lineView)

    NSLayoutConstraint.activate([
      avatarImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
      avatarImage.widthAnchor.constraint(equalToConstant: 60),
      avatarImage.heightAnchor.constraint(equalToConstant: 60),
      avatarImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
    ])

    NSLayoutConstraint.activate([
      nameLabel.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      nameLabel.rightAnchor.constraint(equalTo: avatarImage.rightAnchor),
      nameLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
      nameLabel.bottomAnchor.constraint(equalTo: avatarImage.bottomAnchor),
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
        titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 20),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -35),
        titleLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor, constant: -2),
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
        titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 16),
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
        titleLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor, constant: 7),
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

  open func setData(user: NEKitUser?) {
    guard let user = user else {
      return
    }

    // avatar
    if let imageUrl = user.userInfo?.avatarUrl, !imageUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      avatarImage.backgroundColor = .clear
      nameLabel.isHidden = true
    } else {
      avatarImage.sd_setImage(with: nil)
      avatarImage.backgroundColor = UIColor.colorWithString(string: user.userId)
      nameLabel.text = user.shortName(showAlias: false, count: 2)
      nameLabel.isHidden = false
    }
  }
}
