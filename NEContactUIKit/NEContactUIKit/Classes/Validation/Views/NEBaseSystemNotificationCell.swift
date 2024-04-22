
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
  private var notifModel: NENotification?
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
    imageView.image = UIImage.ne_imageNamed(name: "finishFlag")
    return imageView
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
      rejectButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      rejectButton.rightAnchor.constraint(equalTo: agreeButton.leftAnchor, constant: -16),
      rejectButton.widthAnchor.constraint(equalToConstant: 60),
      rejectButton.heightAnchor.constraint(equalToConstant: 32),
    ])
    rejectButton.addTarget(self, action: #selector(rejectClick(_:)), for: .touchUpInside)

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

    if model.handleStatus != .HandleTypePending {
      agreeButton.isHidden = true
      rejectButton.isHidden = true
      titleLabelRightMargin?.constant = -90

      if model.applicantAccid == IMKitClient.instance.account() {
        // 自己申请的，不展示结果
        resultLabel.isHidden = true
        resultImage.isHidden = true
      } else {
        resultLabel.isHidden = false
        resultImage.isHidden = false

        switch model.handleStatus {
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
      }
    } else {
      agreeButton.isHidden = false
      rejectButton.isHidden = false
      resultLabel.isHidden = true
      resultImage.isHidden = true
      titleLabelRightMargin?.constant = -180
    }
  }

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
