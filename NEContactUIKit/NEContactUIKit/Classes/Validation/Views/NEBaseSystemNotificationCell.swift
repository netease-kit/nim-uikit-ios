
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIMKit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseSystemNotificationCell: NEBaseValidationCell {
  private var notifModel: NENotification?
  public weak var delegate: SystemNotificationCellDelegate?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    contentView.addSubview(agreeBtn)
    contentView.addSubview(rejectBtn)
    contentView.addSubview(resultImage)
    contentView.addSubview(resultLabel)
    resultLabel.text = ""
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

  override open func confige(_ model: NENotification) {
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
        resultLabel.text = localizable("agreed")
        resultImage.image = UIImage.ne_imageNamed(name: "finishFlag")
      case .HandleTypeNo:
        resultLabel.text = localizable("refused")
        resultImage.image = UIImage.ne_imageNamed(name: "refused")
      case .HandleTypeOutOfDate:
        resultLabel.text = localizable("expired")
        resultImage.image = UIImage.ne_imageNamed(name: "refused")
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

  public var rejectBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("refuse"), for: .normal)
    button.setTitleColor(UIColor(hexString: "333333"), for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    button.clipsToBounds = false
    button.layer.cornerRadius = 4
    button.layer.borderColor = UIColor(hexString: "D9D9D9").cgColor
    button.layer.borderWidth = 1
    button.accessibilityIdentifier = "id.reject"
    return button
  }()

  public var agreeBtn: ExpandButton = {
    let button = ExpandButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(localizable("agree"), for: .normal)
    let blue = UIColor(hexString: "337EFF")
    button.setTitleColor(blue, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    button.clipsToBounds = true
    button.layer.cornerRadius = 4
    button.layer.borderWidth = 1
    button.layer.borderColor = blue.cgColor
    button.accessibilityIdentifier = "id.accept"
    return button
  }()

  public lazy var resultImage: UIImageView = {
    let rightImage = UIImageView()
    rightImage.translatesAutoresizingMaskIntoConstraints = false
    rightImage.image = UIImage.ne_imageNamed(name: "finishFlag")
    return rightImage
  }()

  public lazy var resultLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = UIColor(hexString: "B3B7BC")
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.verifyResult"
    return label
  }()

  open func rejectClick(_ sender: UIButton) {
    if let model = notifModel {
      delegate?.onRefuse(model)
    }
  }

  open func agreeClick(_ sender: UIButton) {
    if let model = notifModel {
      delegate?.onAccept(model)
    }
  }
}
