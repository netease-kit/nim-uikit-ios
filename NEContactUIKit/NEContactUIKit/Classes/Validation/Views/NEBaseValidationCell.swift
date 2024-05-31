
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECoreIM2Kit
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
      redAngleView.centerXAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: -8),
      redAngleView.centerYAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 8),
      redAngleView.heightAnchor.constraint(equalToConstant: 18),
    ])

    addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 10),
      titleLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
    ])
    titleLabelRightMargin = titleLabel.rightAnchor.constraint(
      equalTo: contentView.rightAnchor,
      constant: -10
    )
    titleLabelRightMargin?.isActive = true

    addSubview(optionLabel)
    NSLayoutConstraint.activate([
      optionLabel.leftAnchor.constraint(equalTo: avatarImageView.rightAnchor, constant: 10),
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

    // 设置头像
    if let headerUrl = model.userInfo?.user?.avatar, !headerUrl.isEmpty {
      avatarImageView.sd_setImage(with: URL(string: headerUrl), completed: nil)
      nameLabel.text = ""
      avatarImageView.backgroundColor = .clear
    } else if let teamUrl = model.teamInfo?.avatarUrl, !teamUrl.isEmpty {
      avatarImageView.sd_setImage(with: URL(string: teamUrl), completed: nil)
      nameLabel.text = ""
      avatarImageView.backgroundColor = .clear
    } else {
      // 无头像设置其name
      showNameOnCircleHeader(model.userInfo?.showName() ?? "")
      avatarImageView.sd_setImage(with: URL(string: ""), completed: nil)
      avatarImageView.backgroundColor = UIColor.colorWithString(string: model.userInfo?.user?.accountId)
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

    if model.applicantAccid != IMKitClient.instance.account() {
      optionLabelContent = localizable("add_request")
    } else {
      if model.handleStatus == .HandleTypeNo {
        optionLabelContent = localizable("refused_request")
      } else if model.handleStatus == .HandleTypeOk {
        optionLabelContent = localizable("agreed_request")
      }
    }

    titleLabel.text = model.userInfo?.showName()
    optionLabel.text = optionLabelContent
  }
}
