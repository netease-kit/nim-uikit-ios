
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBaseChatMessageTipCell: UITableViewCell {
  var timeLabelWidthAnchor: NSLayoutConstraint?

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    timeLabel.numberOfLines = 0
    contentView.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
    ])
    timeLabelWidthAnchor = timeLabel.widthAnchor.constraint(equalToConstant: chat_content_maxW)
    timeLabelWidthAnchor?.isActive = true
  }

  func setModel(_ model: MessageTipsModel) {
    timeLabel.text = model.text
    timeLabelWidthAnchor?.constant = model.contentSize.width
  }

  public lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.timeTextSize)
    label.textColor = NEKitChatConfig.shared.ui.timeTextColor
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
}
