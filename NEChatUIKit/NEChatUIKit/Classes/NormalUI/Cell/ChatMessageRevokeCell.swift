
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

// protocol ChatRevokeRightCellDelegate: NEChatBaseCellDelegate  {
//    func onReeditMessage(_ cell: UITableViewCell, _ model: MessageContentModel?)
// }

// typealias ReeditBlock = (_ cell: ChatRevokeRightCell, _ model: MessageContentModel?) -> ()

@objcMembers
open class ChatMessageRevokeCell: NormalChatMessageBaseCell {
  public var revokeLabelLeft = UILabel()
  public var revokeLabelRight = UILabel()
  public var reeditButton = UIButton(type: .custom)
  public var reeditButtonW: NSLayoutConstraint?
//    public var reeditBlock: ReeditBlock?
//    public override var delegate: NEChatBaseCellDelegate?
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
    revokeLabelLeft.font = UIFont.systemFont(ofSize: 16.0)
    revokeLabelLeft.accessibilityIdentifier = "id.messageText"
    bubbleImageLeft.addSubview(revokeLabelLeft)
    NSLayoutConstraint.activate([
      revokeLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 16),
      revokeLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      revokeLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -16),
      revokeLabelLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 0),
    ])
  }

  open func commonUIRight() {
    revokeLabelRight.translatesAutoresizingMaskIntoConstraints = false
    revokeLabelRight.textColor = UIColor.ne_greyText
    revokeLabelRight.font = UIFont.systemFont(ofSize: 16.0)
    revokeLabelRight.accessibilityIdentifier = "id.messageText"
    bubbleImageRight.addSubview(revokeLabelRight)
    NSLayoutConstraint.activate([
      revokeLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: 16),
      revokeLabelRight.widthAnchor.constraint(equalToConstant: 100),
      revokeLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      revokeLabelRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
    ])

    reeditButton.translatesAutoresizingMaskIntoConstraints = false
    reeditButton.accessibilityIdentifier = "id.reeditButton"
    reeditButton.setImage(UIImage.ne_imageNamed(name: "right_arrow"), for: .normal)
    reeditButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
    reeditButton.setTitleColor(UIColor.ne_normalTheme, for: .normal)
    reeditButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -30, bottom: 0, right: 0)
    reeditButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 0)

    bubbleImageRight.addSubview(reeditButton)
    reeditButtonW = reeditButton.widthAnchor.constraint(equalToConstant: 86)
    reeditButtonW?.isActive = true
    NSLayoutConstraint.activate([
      reeditButton.leftAnchor.constraint(equalTo: revokeLabelRight.rightAnchor, constant: 8),
      reeditButton.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      reeditButton.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
    ])
    reeditButton.addTarget(self, action: #selector(reeditEvent), for: .touchUpInside)
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    revokeLabelLeft.isHidden = showRight
    revokeLabelRight.isHidden = !showRight
//    reeditButton.isHidden = !showRight

    activityView.isHidden = true
    readView.isHidden = true
    selectedButton.isHidden = true
    pinLabelLeft.isHidden = true
    pinImageLeft.isHidden = true
    pinLabelRight.isHidden = true
    pinImageRight.isHidden = true
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    let isSend = IMKitClient.instance.isMe(model.message?.senderId)
    if let time = model.message?.createTime {
      let date = Date()
      let currentTime = date.timeIntervalSince1970
      if currentTime - time >= 60 * 2 {
        model.timeOut = true
      }
    }

    if isSend,
       model.isReedit == true,
       model.timeOut == false {
      reeditButtonW?.constant = 86
      reeditButton.isHidden = false
      reeditButton.setTitle(chatLocalizable("message_reedit"), for: .normal)
      model.contentSize = CGSize(width: 218, height: chat_min_h)
    } else {
      reeditButtonW?.constant = 0
      reeditButton.isHidden = true
      model.contentSize = CGSize(width: 130, height: chat_min_h)
    }

    super.setModel(model, isSend)
    let revokeLabel = isSend ? revokeLabelRight : revokeLabelLeft
    revokeLabel.text = chatLocalizable("message_recalled")
  }

  func reeditEvent(button: UIButton) {
    delegate?.didTapReeditButton(self, contentModel)
  }
}
