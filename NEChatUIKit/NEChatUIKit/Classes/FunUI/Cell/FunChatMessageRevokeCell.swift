// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageRevokeCell: FunChatMessageBaseCell {
  public var revokeLabelLeft = UILabel()
  public var revokeLabelRight = UILabel()
  public var reeditButton = UIButton(type: .custom)
  var revokeLabelRightXAnchor: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    revokeLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    revokeLabelLeft.textColor = UIColor.ne_greyText
    revokeLabelLeft.textAlignment = .center
    revokeLabelLeft.lineBreakMode = .byTruncatingMiddle
    revokeLabelLeft.font = UIFont.systemFont(ofSize: 14.0)
    revokeLabelLeft.accessibilityIdentifier = "id.messageText"
    contentView.addSubview(revokeLabelLeft)
    NSLayoutConstraint.activate([
      revokeLabelLeft.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      revokeLabelLeft.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
      revokeLabelLeft.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
      revokeLabelLeft.heightAnchor.constraint(equalToConstant: 16),
    ])
  }

  open func commonUIRight() {
    revokeLabelRight.translatesAutoresizingMaskIntoConstraints = false
    revokeLabelRight.textColor = UIColor.ne_greyText
    revokeLabelRight.textAlignment = .center
    revokeLabelRight.font = UIFont.systemFont(ofSize: 14.0)
    revokeLabelRight.accessibilityIdentifier = "id.messageText"
    contentView.addSubview(revokeLabelRight)
    revokeLabelRightXAnchor = revokeLabelRight.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0)
    revokeLabelRightXAnchor?.isActive = true
    NSLayoutConstraint.activate([
      revokeLabelRight.widthAnchor.constraint(equalToConstant: 120),
      revokeLabelRight.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
      revokeLabelRight.heightAnchor.constraint(equalToConstant: 16),
    ])

    reeditButton.translatesAutoresizingMaskIntoConstraints = false
    reeditButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
    reeditButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    reeditButton.accessibilityIdentifier = "id.reeditButton"

    contentView.addSubview(reeditButton)
    NSLayoutConstraint.activate([
      reeditButton.leftAnchor.constraint(equalTo: revokeLabelRight.rightAnchor, constant: 8),
      reeditButton.widthAnchor.constraint(equalToConstant: 58),
      reeditButton.topAnchor.constraint(equalTo: revokeLabelRight.topAnchor, constant: 0),
      reeditButton.bottomAnchor.constraint(equalTo: revokeLabelRight.bottomAnchor, constant: 0),
    ])
    reeditButton.addTarget(self, action: #selector(reeditEvent), for: .touchUpInside)
  }

  override open func showLeftOrRight(showRight: Bool) {
    avatarImageLeft.isHidden = true
    nameLabelLeft.isHidden = true
    bubbleImageLeft.isHidden = true
    pinImageLeft.isHidden = true
    pinLabelLeft.isHidden = true
    fullNameLabel.isHidden = true

    avatarImageRight.isHidden = true
    nameLabelRight.isHidden = true
    bubbleImageRight.isHidden = true
    pinImageRight.isHidden = true
    pinLabelRight.isHidden = true
    activityView.isHidden = true
    readView.isHidden = true
    selectedButton.isHidden = true

    revokeLabelLeft.isHidden = showRight
    revokeLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let isSend = IMKitClient.instance.isMe(model.message?.senderId)
    let revokeLabel = isSend ? revokeLabelRight : revokeLabelLeft

    if let time = model.message?.createTime {
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        model.timeOut = true
      }
    }

    model.contentSize = CGSize(width: kScreenWidth, height: 0)
    super.setModel(model, isSend)
    showLeftOrRight(showRight: isSend)

    revokeLabel.textColor = .funChatInputViewPlaceholderTextColor
    if isSend {
      revokeLabel.text = chatLocalizable("You") + chatLocalizable("withdrew_message")
    } else {
      revokeLabel.text = (model.fullName ?? "") + " " + chatLocalizable("withdrew_message")
    }

    if isSend, model.isReedit == true {
      if model.timeOut == true {
        reeditButton.isHidden = true
        revokeLabelRightXAnchor?.constant = 0
      } else {
        reeditButton.isHidden = false
        reeditButton.setTitle(chatLocalizable("message_reedit"), for: .normal)
        revokeLabelRightXAnchor?.constant = -32
      }
    } else {
      reeditButton.isHidden = true
      revokeLabelRightXAnchor?.constant = 0
    }
  }

  func reeditEvent(button: UIButton) {
    delegate?.didTapReeditButton(self, contentModel)
  }
}
