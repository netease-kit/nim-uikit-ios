// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import UIKit

class CustomChatCell: NEBaseChatMessageCell {
  public var testLabel = UILabel()

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    testLabel.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(testLabel)
    NSLayoutConstraint.activate([
      testLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      testLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
    testLabel.font = UIFont.systemFont(ofSize: 14)
    testLabel.textColor = UIColor.black
  }

  override func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    // 隐藏左侧控件
    hideLeft(true)

    // 隐藏右侧控件
    hideRight(true)

    print("this is custom message")
    testLabel.text = "this is custom message"
  }
}
