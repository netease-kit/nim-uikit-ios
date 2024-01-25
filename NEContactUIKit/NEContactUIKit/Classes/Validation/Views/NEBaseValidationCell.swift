
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIMKit
import NIMSDK
import UIKit

public protocol SystemNotificationCellDelegate: AnyObject {
  func onAccept(_ notifiModel: NENotification)
  func onRefuse(_ notifiModel: NENotification)
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

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
      redAngleView.centerXAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: avatarImage.topAnchor, constant: 8),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 10),
      titleLabel.topAnchor.constraint(equalTo: avatarImage.topAnchor),
    ])
    titleLabelRightMargin = titleLabel.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -10
    )
    titleLabelRightMargin?.isActive = true

    addSubview(optionLabel)
    NSLayoutConstraint.activate([
      optionLabel.leftAnchor.constraint(equalTo: avatarImage.rightAnchor, constant: 10),
      optionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      optionLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -180),
    ])

    addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
      line.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
    line.backgroundColor = UIColor(hexString: "#F5F8FC")
  }

  open func confige(_ model: NENotification) {
    var optionLabelContent = ""
    var nickName = ""
    var teamName = ""
    // 设置操作者名称

    if let alias = model.userInfo?.alias {
      nickName = alias
    } else if let nick = model.userInfo?.userInfo?.nickName {
      nickName = nick
    } else if let source = model.sourceName {
      nickName = source
    }

    if model.userInfo == nil, let uid = model.sourceID {
      let user = NIMSDK.shared().userManager.userInfo(uid)
      if let alias = user?.alias, !alias.isEmpty {
        nickName = alias
      } else if let nick = user?.userInfo?.nickName, !nick.isEmpty {
        nickName = nick
      }
    }
    // 设置头像
    if let headerUrl = model.userInfo?.userInfo?.avatarUrl, !headerUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: headerUrl), completed: nil)
      nameLabel.text = ""
      avatarImage.backgroundColor = .clear
    } else if let teamUrl = model.teamInfo?.avatarUrl, !teamUrl.isEmpty {
      avatarImage.sd_setImage(with: URL(string: teamUrl), completed: nil)
      nameLabel.text = ""
      avatarImage.backgroundColor = .clear
    } else {
      // 无头像设置其name
      if !nickName.isEmpty {
        showNameOnCircleHeader(nickName)
      } else {
        if let id = model.sourceID {
          showNameOnCircleHeader(id)
        }
      }
      avatarImage.sd_setImage(with: URL(string: ""), completed: nil)
      avatarImage.backgroundColor = UIColor.colorWithString(string: model.userInfo?.userId)
    }

    // 设置未读状态（未读数角标+底色）
    redAngleView.isHidden = true
    contentView.backgroundColor = .white
    if model.unReadCount > 0 {
      contentView.backgroundColor = UIColor(hexString: "0xF3F5F7")
      if model.unReadCount > 1 {
        redAngleView.isHidden = false
        redAngleView.text = model.unReadCount > 99 ? "99+" : "\(model.unReadCount)"
      }
    }

    if let t = model.targetName {
      teamName = t
    }
    if let type = model.type {
      switch type {
      case .teamApply:
        optionLabelContent = "申请加入群聊 \"\(teamName)\""
      case .teamApplyReject:
        optionLabelContent = "拒绝入群邀请 \"\(teamName)\""
      case .teamInvite:
        optionLabelContent = "邀请您加入群聊 \"\(teamName)\""
      case .teamInviteReject:
        optionLabelContent = "拒绝入群邀请 \"\(teamName)\""

      case .superTeamApply:
        optionLabelContent = "申请加入超大群"
      case .superTeamApplyReject:
        optionLabelContent = "拒绝加入超大群"

      case .superTeamInvite:
        optionLabelContent = "邀请您加入群聊 \"\(teamName)\""
      case .superTeamInviteReject:
        optionLabelContent = "拒绝入群邀请 \"\(teamName)\""
      case .addFriendDirectly:
        optionLabelContent = "添加您为好友"
      case .addFriendRequest:
        optionLabelContent = "好友申请"
      case .addFriendVerify:
        optionLabelContent = "同意了你的好友请求"
      case .addFriendReject:
        optionLabelContent = "拒绝了你的好友请求"
      @unknown default:
        optionLabelContent = "未知操作"
      }
    }

    titleLabel.text = nickName
    optionLabel.text = optionLabelContent
  }
}
