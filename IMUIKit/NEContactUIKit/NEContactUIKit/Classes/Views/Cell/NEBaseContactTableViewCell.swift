
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
  public var contactCellType = ContactCellType.ContactPerson

  public lazy var arrowImageView: UIImageView = {
    let imageView = UIImageView(image: coreLoader.loadImage("arrow_right"))
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .center
    imageView.accessibilityIdentifier = "id.arrow"
    return imageView
  }()

  public lazy var onlineView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 4
    view.backgroundColor = UIColor(hexString: "#D4D9DA")
    view.isHidden = true
    return view
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
    backgroundColor = .clear

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 12),
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

    contentView.addSubview(onlineView)
    NSLayoutConstraint.activate([
      onlineView.rightAnchor.constraint(equalTo: userHeaderView.rightAnchor),
      onlineView.bottomAnchor.constraint(equalTo: userHeaderView.bottomAnchor),
      onlineView.widthAnchor.constraint(equalToConstant: 8),
      onlineView.heightAnchor.constraint(equalToConstant: 8),
    ])

    contentView.addSubview(bottomLine)
    NSLayoutConstraint.activate([
      bottomLine.leftAnchor.constraint(equalTo: userHeaderView.leftAnchor),
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
    if ContactUIConfig.shared.contactProperties.avatarType == .cycle {
      userHeaderView.layer.cornerRadius = 18.0
    } else if ContactUIConfig.shared.contactProperties.avatarCornerRadius > 0 {
      userHeaderView.layer.cornerRadius = ContactUIConfig.shared.contactProperties.avatarCornerRadius
    } else {
      userHeaderView.layer.cornerRadius = 18.0 // Normal UI
    }
  }

  open func setConfig() {
    titleLabel.textColor = ContactUIConfig.shared.contactProperties.itemTitleColor
  }

  open func setOnline(_ online: Bool) {
    onlineView.isHidden = contactCellType != .ContactPerson
    onlineView.backgroundColor = online ? UIColor(hexString: "#84ED85") : UIColor(hexString: "#D4D9DA")
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

    contactCellType = model.contactCellType
    if model.contactCellType == .ContactOthers {
      titleLabel.text = user.friend?.alias
      arrowImageView.isHidden = false

      let url = user.user?.avatar
      userHeaderView.image = UIImage.ne_imageNamed(name: url)
      userHeaderView.setTitle("")
      userHeaderView.backgroundColor = .clear
    } else {
      // person、custom
      titleLabel.text = user.showName()
      arrowImageView.isHidden = true

      let url = user.user?.avatar
      let name = user.shortName() ?? ""
      let accountId = user.user?.accountId ?? ""
      userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)
    }
  }
}
