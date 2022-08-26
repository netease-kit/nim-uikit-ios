
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NEKitCore
import NEKitCommonUI
import NEKitCoreIM
import NIMSDK

protocol SystemNotificationCellDelegate: AnyObject {
  func onAccept(_ notifiModel: XNotification)
  func onRefuse(_ notifiModel: XNotification)
}

enum NotificationHandleType: Int {
  case Pending = 0
  case agree
  case refuse
  case OutOfDate
}

class SystemNotificationCell: BaseValidationCell {
  private var notifModel: XNotification?
  weak var delegate: SystemNotificationCellDelegate?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func setupUI() {
    super.setupUI()
    titleLabel.numberOfLines = 1
    contentView.addSubview(agreeBtn)
    contentView.addSubview(rejectBtn)
    contentView.addSubview(resultImage)
    contentView.addSubview(resultLabel)
    resultLabel.text = "asdasdsadsa"
    NSLayoutConstraint.activate([
      agreeBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      agreeBtn.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      agreeBtn.widthAnchor.constraint(equalToConstant: 60),
      agreeBtn.heightAnchor.constraint(equalToConstant: 32),
    ])
    agreeBtn.addTarget(self, action: #selector(agreeClick(_:)), for: .touchUpInside)

    NSLayoutConstraint.activate([
      rejectBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      rejectBtn.rightAnchor.constraint(equalTo: agreeBtn.leftAnchor, constant: -16),
      rejectBtn.widthAnchor.constraint(equalToConstant: 60),
      rejectBtn.heightAnchor.constraint(equalToConstant: 32),
    ])
    rejectBtn.addTarget(self, action: #selector(rejectClick(_:)), for: .touchUpInside)

    NSLayoutConstraint.activate([
      resultLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      resultLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      resultImage.rightAnchor.constraint(equalTo: resultLabel.leftAnchor, constant: -6),
      resultImage.centerYAnchor.constraint(equalTo: resultLabel.centerYAnchor),
      resultImage.widthAnchor.constraint(equalToConstant: 16),
      resultImage.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  override func confige(_ model: XNotification) {
    super.confige(model)
    notifModel = model
    let hideActionButton = shouldHideActionButton()
    agreeBtn.isHidden = hideActionButton
    rejectBtn.isHidden = hideActionButton

    if hideActionButton {
      let hidden = shouldHideResultStatus()

      resultLabel.isHidden = hidden
      resultImage.isHidden = hidden

      switch notifModel?.handleStatus {
      case .HandleTypeOk:
        resultLabel.text = "已同意"
      case .HandleTypeNo:
        resultLabel.text = "已拒绝"
      case .HandleTypeOutOfDate:
        resultLabel.text = "已过期"
      default:
        resultLabel.text = ""
      }
      titleLabelRightMargin?.constant = hidden ? -20 : -90
    } else {
      resultLabel.isHidden = true
      resultImage.isHidden = true
      titleLabelRightMargin?.constant = -180
    }
  }

  func shouldHideActionButton() -> Bool {
    let type = notifModel?.type
    let handled = notifModel?.handleStatus != .HandleTypePending
    var needHandel = false
    if type == .teamApply ||
      type == .teamInvite ||
      type == .superTeamInvite ||
      type == .superTeamApply {
      needHandel = true
    }

    if type == .addFriendRequest {
      if let obj = notifModel?.attachment {
        if obj.isKind(of: NIMUserAddAttachment.self) {
          let operation = (obj as NIMUserAddAttachment).operationType
          needHandel = operation == .request
        }
      }
    }
    return !(!handled && needHandel)
  }

  func shouldHideResultStatus() -> Bool {
    let type = notifModel?.type
    if type == .addFriendVerify ||
      type == .addFriendReject ||
      type == .teamInviteReject {
      return true
    } else {
      return false
    }
  }

  var rejectBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("拒绝", for: .normal)
    button.setTitleColor(UIColor(hexString: "333333"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    button.clipsToBounds = false
    button.layer.cornerRadius = 4
    button.layer.borderColor = UIColor(hexString: "D9D9D9").cgColor
    button.layer.borderWidth = 1
    return button
  }()

  var agreeBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("同意", for: .normal)
    let blue = UIColor(hexString: "337EFF")
    button.setTitleColor(blue, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.clipsToBounds = true
    button.layer.cornerRadius = 4
    button.layer.borderWidth = 1
    button.layer.borderColor = blue.cgColor
    return button
  }()

  private lazy var resultImage: UIImageView = {
    let rightImage = UIImageView()
    rightImage.translatesAutoresizingMaskIntoConstraints = false
    rightImage.image = UIImage.ne_imageNamed(name: "finishFlag")
    return rightImage
  }()

  private lazy var resultLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "B3B7BC")
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textAlignment = .right
    return label
  }()

  @objc func rejectClick(_ sender: UIButton) {
    if let model = notifModel {
      delegate?.onRefuse(model)
    }
  }

  @objc func agreeClick(_ sender: UIButton) {
    if let model = notifModel {
      delegate?.onAccept(model)
    }
  }
}
