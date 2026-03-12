
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
import NIMSDK
import UIKit

@objc
public protocol SystemNotificationCellDelegate: NSObjectProtocol {
  @objc optional func onAccept(application: NEAddApplication)
  @objc optional func onRefuse(application: NEAddApplication)
  @objc optional func onAccept(action: NETeamJoinAction)
  @objc optional func onRefuse(action: NETeamJoinAction)
}

enum NotificationHandleType: Int {
  case Pending = 0
  case agree
  case refuse
  case OutOfDate
}

@objcMembers
open class NEBaseValidationCell: NEBaseContactViewCell {
  public var titleLabelRightMargin: NSLayoutConstraint?
  let line = UIView()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    setupCommonCircleHeader()

    contentView.addSubview(redAngleView)
    NSLayoutConstraint.activate([
      redAngleView.centerXAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: userHeaderView.topAnchor, constant: 8),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    contentView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 10),
      titleLabel.topAnchor.constraint(equalTo: userHeaderView.topAnchor),
    ])
    titleLabelRightMargin = titleLabel.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -10
    )
    titleLabelRightMargin?.isActive = true

    contentView.addSubview(optionLabel)
    NSLayoutConstraint.activate([
      optionLabel.leftAnchor.constraint(equalTo: userHeaderView.rightAnchor, constant: 10),
      optionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      optionLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -180),
    ])

    contentView.addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    line.backgroundColor = UIColor(hexString: "#F5F8FC")
  }

  open func confige(application: NEAddApplication) {
    // 设置头像
    let url = application.displayUserWithFriend?.user?.avatar
    let name = application.displayUserWithFriend?.shortName() ?? application.displayUserId ?? ""
    let accountId = application.displayUserWithFriend?.user?.accountId ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)

    // 设置未读状态（未读数角标+底色）
    redAngleView.isHidden = true
    contentView.backgroundColor = .white
    if application.unreadCount > 0 {
      contentView.backgroundColor = UIColor(hexString: "0xF3F5F7")
      if application.unreadCount > 1 {
        redAngleView.isHidden = false
        redAngleView.text = application.unreadCount > 99 ? "99+" : "\(application.unreadCount)"
      }
    }

    titleLabel.text = application.displayUserWithFriend?.showName() ?? application.displayUserId
    optionLabel.text = application.detail
  }

  open func confige(teamJoinAction: NETeamJoinAction) {
    // 设置头像
    let url = teamJoinAction.displayUserWithFriend?.user?.avatar
    let name = teamJoinAction.displayUserWithFriend?.shortName() ?? teamJoinAction.displayUserId
    let accountId = teamJoinAction.displayUserWithFriend?.user?.accountId ?? ""
    userHeaderView.configHeadData(headUrl: url, name: name, uid: accountId)

    // 设置未读状态（未读数角标+底色）
    redAngleView.isHidden = true
    contentView.backgroundColor = .white
    if teamJoinAction.unreadCount > 0 {
      contentView.backgroundColor = UIColor(hexString: "0xF3F5F7")
      if teamJoinAction.unreadCount > 1 {
        redAngleView.isHidden = false
        redAngleView.text = teamJoinAction.unreadCount > 99 ? "99+" : "\(teamJoinAction.unreadCount)"
      }
    }

    titleLabel.text = teamJoinAction.displayUserWithFriend?.showName() ?? teamJoinAction.displayUserId
    optionLabel.text = teamJoinAction.detail
  }
}
