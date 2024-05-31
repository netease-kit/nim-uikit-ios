
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseChatMessageTipCell: UITableViewCell {
  var timeLabelHeightAnchor: NSLayoutConstraint? // 消息时间高度约束
  var contentLabelCenterYAnchor: NSLayoutConstraint? // 消息内容中心Y约束

  /// 时间
  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.timeTextSize)
    label.textColor = NEKitChatConfig.shared.ui.messageProperties.timeTextColor
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.messageTipText"
    return label
  }()

  /// 内容
  public lazy var contentLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.timeTextSize)
    label.textColor = NEKitChatConfig.shared.ui.messageProperties.timeTextColor
    label.textAlignment = .center
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.messageTipText"
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    contentView.addSubview(timeLabel)
    timeLabelHeightAnchor = timeLabel.heightAnchor.constraint(equalToConstant: 22)
    timeLabelHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      timeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
    ])

    contentView.addSubview(contentLabel)
    contentLabelCenterYAnchor = contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    contentLabelCenterYAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      contentLabel.widthAnchor.constraint(equalToConstant: chat_content_maxW),
    ])
  }

  func setModel(_ model: MessageTipsModel) {
    // time
    if let time = model.timeContent, !time.isEmpty {
      timeLabelHeightAnchor?.constant = chat_timeCellH
      contentLabelCenterYAnchor?.constant = chat_timeCellH / 2
      timeLabel.text = time
      timeLabel.isHidden = false
    } else {
      timeLabelHeightAnchor?.constant = 0
      contentLabelCenterYAnchor?.constant = 0
      timeLabel.text = ""
      timeLabel.isHidden = true
    }

    contentLabel.text = model.text
  }
}
