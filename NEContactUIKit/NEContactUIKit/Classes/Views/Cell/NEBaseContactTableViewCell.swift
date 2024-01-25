
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
import NECoreIMKit
import NECoreKit
import UIKit

@objcMembers
open class NEBaseContactTableViewCell: NEBaseContactViewCell, ContactCellDataProtrol {
  public lazy var arrow: UIImageView = {
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
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    setupCommonCircleHeader()

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 12),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -35),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(arrow)
    NSLayoutConstraint.activate([
      arrow.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrow.widthAnchor.constraint(equalToConstant: 15),
      arrow.topAnchor.constraint(equalTo: contentView.topAnchor),
      arrow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: avatarImage.leftAnchor),
      bottomLine.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      bottomLine.heightAnchor.constraint(equalToConstant: 1),
    ])

    contentView.addSubview(redAngleView)
    NSLayoutConstraint.activate([
      redAngleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      redAngleView.rightAnchor.constraint(equalTo: arrow.leftAnchor, constant: -10),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])
  }

  open func initSubviewsLayout() {
    if NEKitContactConfig.shared.ui.contactProperties.avatarType == .rectangle {
      avatarImage.layer.cornerRadius = NEKitContactConfig.shared.ui.contactProperties.avatarCornerRadius
    } else if NEKitContactConfig.shared.ui.contactProperties.avatarType == .cycle {
      avatarImage.layer.cornerRadius = 18.0
    } else {
      avatarImage.layer.cornerRadius = 18.0 // Normal UI
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

    if let userId = user.userId, let u = ChatUserCache.getUserInfo(userId) {
      user = u
    }

    if model.contactCellType == 1 {
      NELog.infoLog("contact other cell configData", desc: "\(user.alias), image name:\(user.userInfo?.avatarUrl)")
      nameLabel.text = ""
      titleLabel.text = user.alias
      avatarImage.image = UIImage.ne_imageNamed(name: user.userInfo?.avatarUrl)
      avatarImage.backgroundColor = model.headerBackColor
      arrow.isHidden = false
    } else {
      // person、custom
      titleLabel.text = user.showName()
      nameLabel.text = user.shortName(showAlias: false, count: 2)

      if let imageUrl = user.userInfo?.avatarUrl, !imageUrl.isEmpty {
        NELog.infoLog("contact p2p cell configData", desc: "imageName:\(imageUrl)")
        nameLabel.isHidden = true
        avatarImage.sd_setImage(with: URL(string: imageUrl), completed: nil)
      } else {
        NELog.infoLog("contact p2p cell configData", desc: "imageName is nil")
        nameLabel.isHidden = false
        avatarImage.sd_setImage(with: nil)
        avatarImage.backgroundColor = model.headerBackColor
      }
      arrow.isHidden = true
    }
  }
}
