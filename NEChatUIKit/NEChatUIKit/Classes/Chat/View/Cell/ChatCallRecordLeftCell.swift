// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
class ChatCallRecordLeftCell: ChatBaseLeftCell {
  public let contentLabel = UILabel()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func commonUI() {
    contentLabel.translatesAutoresizingMaskIntoConstraints = false
    contentLabel.isEnabled = false
    contentLabel.numberOfLines = 0
    contentLabel.isUserInteractionEnabled = false
    contentLabel.font = DefaultTextFont(16)
    contentLabel.backgroundColor = .clear
    bubbleImage.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: 0),
      contentLabel.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 8),
      contentLabel.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 0),
      contentLabel.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageCallRecordModel {
      contentLabel.attributedText = m.attributeStr
    }
  }
}
