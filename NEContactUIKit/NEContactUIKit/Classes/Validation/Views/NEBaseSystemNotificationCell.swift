
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseSystemNotificationCell: NEBaseValidationCell {
  private var addApplication: NEAddApplication?
  private var teamJoinAction: NETeamJoinAction?
  public weak var delegate: SystemNotificationCellDelegate?

  public var rejectButton: ExpandButton = {
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

  public var agreeButton: ExpandButton = {
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
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.image = UIImage.ne_imageNamed(name: "valid_processed")
    return imageView
  }()

  public lazy var resultLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .ne_emptyTitleColor
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textAlignment = .right
    label.accessibilityIdentifier = "id.verifyResult"
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    contentView.addSubview(agreeButton)
    contentView.addSubview(rejectButton)
    contentView.addSubview(resultImage)
    contentView.addSubview(resultLabel)
    resultLabel.text = ""
    NSLayoutConstraint.activate([
      agreeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      agreeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      agreeButton.widthAnchor.constraint(equalToConstant: 60),
      agreeButton.heightAnchor.constraint(equalToConstant: 32),
    ])
    agreeButton.addTarget(self, action: #selector(agreeClick(_:)), for: .touchUpInside)

    NSLayoutConstraint.activate([
      rejectButton.centerYAnchor.constraint(equalTo: agreeButton.centerYAnchor),
      rejectButton.rightAnchor.constraint(equalTo: agreeButton.leftAnchor, constant: -16),
      rejectButton.widthAnchor.constraint(equalToConstant: 60),
      rejectButton.heightAnchor.constraint(equalToConstant: 32),
    ])
    rejectButton.addTarget(self, action: #selector(rejectClick(_:)), for: .touchUpInside)

    NSLayoutConstraint.activate([
      resultLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      resultLabel.centerYAnchor.constraint(equalTo: agreeButton.centerYAnchor),
    ])

    NSLayoutConstraint.activate([
      resultImage.rightAnchor.constraint(equalTo: resultLabel.leftAnchor, constant: -6),
      resultImage.centerYAnchor.constraint(equalTo: resultLabel.centerYAnchor),
      resultImage.widthAnchor.constraint(equalToConstant: 16),
      resultImage.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  override open func confige(application: NEAddApplication) {
    super.confige(application: application)
    addApplication = application

    if application.handleStatus != .FRIEND_ADD_APPLICATION_STATUS_INIT {
      agreeButton.isHidden = true
      rejectButton.isHidden = true
      titleLabelRightMargin?.constant = -90

      if application.v2Notification.applicantAccountId == IMKitClient.instance.account() {
        // 自己申请的，不展示结果
        resultLabel.isHidden = true
        resultImage.isHidden = true
      } else {
        resultLabel.isHidden = false
        resultImage.isHidden = false

        switch application.handleStatus {
        case .FRIEND_ADD_APPLICATION_STATUS_AGREED, .FRIEND_ADD_APPLICATION_STATUS_DIRECT_ADD:
          resultLabel.text = localizable("valid_agreed")
          resultImage.image = UIImage.ne_imageNamed(name: "valid_processed")
        case .FRIEND_ADD_APPLICATION_STATUS_REJECED:
          resultLabel.text = localizable("valid_refused")
          resultImage.image = UIImage.ne_imageNamed(name: "valid_refused")
        case .FRIEND_ADD_APPLICATION_STATUS_EXPIRED:
          resultLabel.text = localizable("expired")
          resultImage.image = UIImage.ne_imageNamed(name: "valid_refused")
        default:
          resultLabel.text = ""
        }
      }
    } else {
      agreeButton.isHidden = false
      rejectButton.isHidden = false
      resultLabel.isHidden = true
      resultImage.isHidden = true
      titleLabelRightMargin?.constant = -180
    }
  }

  override open func confige(teamJoinAction: NETeamJoinAction) {
    super.confige(teamJoinAction: teamJoinAction)
    self.teamJoinAction = teamJoinAction
//    contentView.updateLayoutConstraint(firstItem: titleLabel, secondItem: userHeaderView, attribute: .top, constant: 6)
    contentView.updateLayoutConstraint(firstItem: optionLabel, secondItem: titleLabel, attribute: .top, constant: 12)
    contentView.updateLayoutConstraint(firstItem: optionLabel, secondItem: contentView, attribute: .right, constant: -16)
    contentView.updateLayoutConstraint(firstItem: agreeButton, secondItem: contentView, attribute: .centerY, constant: -10)

    if teamJoinAction.handleStatus != .TEAM_JOIN_ACTION_STATUS_INIT {
      agreeButton.isHidden = true
      rejectButton.isHidden = true
      titleLabelRightMargin?.constant = -90

      resultLabel.isHidden = false
      resultImage.isHidden = false

      switch teamJoinAction.handleStatus {
      case .TEAM_JOIN_ACTION_STATUS_AGREED:
        resultLabel.text = localizable("valid_agreed")
        resultImage.image = UIImage.ne_imageNamed(name: "valid_processed")
      case .TEAM_JOIN_ACTION_STATUS_REJECTED:
        resultLabel.text = localizable("valid_refused")
        resultImage.image = UIImage.ne_imageNamed(name: "valid_refused")
      case .TEAM_JOIN_ACTION_STATUS_EXPIRED:
        resultLabel.text = localizable("expired")
        resultImage.image = UIImage.ne_imageNamed(name: "valid_refused")
      default:
        resultLabel.text = ""
      }
    } else {
      if teamJoinAction.nimTeamJoinAction.actionType == .TEAM_JOIN_ACTION_TYPE_REJECT_APPLICATION ||
        teamJoinAction.nimTeamJoinAction.actionType == .TEAM_JOIN_ACTION_TYPE_REJECT_INVITATION {
        // 申请被拒绝，不展示结果
        resultLabel.isHidden = true
        resultImage.isHidden = true
        agreeButton.isHidden = true
        rejectButton.isHidden = true
        titleLabelRightMargin?.constant = -16
      } else {
        agreeButton.isHidden = false
        rejectButton.isHidden = false
        resultLabel.isHidden = true
        resultImage.isHidden = true
        titleLabelRightMargin?.constant = -180
      }
    }
  }

  open func rejectClick(_ sender: UIButton) {
    if let model = addApplication {
      delegate?.onRefuse?(application: model)
    }

    if let model = teamJoinAction {
      delegate?.onRefuse?(action: model)
    }
  }

  open func agreeClick(_ sender: UIButton) {
    if let model = addApplication {
      delegate?.onAccept?(application: model)
    }

    if let model = teamJoinAction {
      delegate?.onAccept?(action: model)
    }
  }
}
