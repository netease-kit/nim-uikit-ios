
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIM2Kit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseContactTableViewCell: NEBaseContactViewCell, ContactCellDataProtrol {
  public lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .center
    imageView.accessibilityIdentifier = "id.arrow"
    return imageView
  }()

  public lazy var bottomLine: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
    initSubviewsLayout()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    setupCommonCircleHeader()

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(arrowImageView)
    NSLayoutConstraint.activate([
      arrowImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrowImageView.widthAnchor.constraint(equalToConstant: 15),
      arrowImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      arrowImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: avatarImageView.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    contentView.addSubview(redAngleView)
    NSLayoutConstraint.activate([
      redAngleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      redAngleView.rightAnchor.constraint(equalTo: arrowImageView.leftAnchor, constant: -10),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  open func initSubviewsLayout() {
    if NEKitContactConfig.shared.ui.contactProperties.avatarType == .cycle {
      avatarImageView.layer.cornerRadius = 18.0
    } else if NEKitContactConfig.shared.ui.contactProperties.avatarCornerRadius > 0 {
      avatarImageView.layer.cornerRadius = NEKitContactConfig.shared.ui.contactProperties.avatarCornerRadius
    } else {
      avatarImageView.layer.cornerRadius = 18.0 // Normal UI
    }
  }

  open func setConfig() {
    titleLabel.textColor = NEKitContactConfig.shared.ui.contactProperties.itemTitleColor
    nameLabel.font = UIFont.systemFont(ofSize: 14.0)
    nameLabel.textColor = UIColor.white
  }

  open func setModel(_ model: ContactInfo) {
    guard var user = model.user else {
      return
    }
    setConfig()

    // 更新用户信息
    if let userId = user.user?.accountId, let u = NEFriendUserCache.shared.getFriendInfo(userId) {
      user = u
    }

    if model.contactCellType == 1 {
      NEALog.infoLog("contact other cell configData", desc: "\(user.friend?.alias), image name:\(user.user?.avatar)")
      nameLabel.text = ""
      titleLabel.text = user.friend?.alias
      avatarImageView.image = UIImage.ne_imageNamed(name: user.user?.avatar)
      avatarImageView.backgroundColor = model.headerBackColor
      arrowImageView.isHidden = false
    } else {
      // person、custom
      titleLabel.text = user.showName()
      nameLabel.text = user.shortName(count: 2)

      if let imageUrl = user.user?.avatar, !imageUrl.isEmpty {
        NEALog.infoLog("contact p2p cell configData", desc: "imageName:\(imageUrl)")
        nameLabel.isHidden = true
        avatarImageView.sd_setImage(with: URL(string: imageUrl), completed: nil)
      } else {
        NEALog.infoLog("contact p2p cell configData", desc: "imageName is nil")
        nameLabel.isHidden = false
        avatarImageView.sd_setImage(with: nil)
        avatarImageView.backgroundColor = model.headerBackColor
      }
      arrowImageView.isHidden = true
    }
  }
}
