
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatTimeTableViewCell: UITableViewCell {
  var timeLabelWidthAnchor: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    timeLabel.numberOfLines = 0
    contentView.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
    ])
    timeLabelWidthAnchor = timeLabel.widthAnchor.constraint(equalToConstant: kScreenWidth - 64 * 2)
    timeLabelWidthAnchor?.isActive = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setModel(_ model: MessageTipsModel) {
    timeLabel.text = model.text
    timeLabelWidthAnchor?.constant = model.contentSize.width
  }

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = DefaultTextFont(NEKitChatConfig.shared.ui.timeTextSize)
    label.textColor = NEKitChatConfig.shared.ui.timeTextColor
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
}
