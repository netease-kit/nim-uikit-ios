
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatTextRightCell: ChatBaseRightCell {
  public let contentLabel = UILabel()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    contentLabel.translatesAutoresizingMaskIntoConstraints = false
    contentLabel.isEnabled = false
    contentLabel.isUserInteractionEnabled = false
    contentLabel.numberOfLines = 0
    contentLabel.font = DefaultTextFont(16)
    contentLabel.textAlignment = .justified
    bubbleImage.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -qChat_margin),
      contentLabel.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: qChat_margin),
      contentLabel.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 0),
      contentLabel.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: 0),
    ])
  }

  override open func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageTextModel {
      contentLabel.attributedText = m.attributeStr
    }
  }
}
