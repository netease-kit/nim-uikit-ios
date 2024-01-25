// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBasePinMessageRichTextCell: NEBasePinMessageTextCell {
  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    label.textColor = .ne_darkText
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isUserInteractionEnabled = true
    label.numberOfLines = 1
    return label
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUI() {
    backView.addSubview(titleLabel)
    NSLayoutConstraint.activate([
      titleLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      titleLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      titleLabel.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
    ])

    contentLabel.numberOfLines = 2
    backView.addSubview(contentLabel)
    NSLayoutConstraint.activate([
      contentLabel.leftAnchor.constraint(equalTo: line.leftAnchor),
      contentLabel.rightAnchor.constraint(equalTo: line.rightAnchor),
      contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
    ])

    if let gesture = contentGesture {
      contentLabel.addGestureRecognizer(gesture)
    }

    let titleGesture = UITapGestureRecognizer(target: self, action: #selector(contentClick))
    titleLabel.addGestureRecognizer(titleGesture)
  }

  override open func configure(_ item: PinMessageModel) {
    super.configure(item)
    if let model = item.chatmodel as? MessageRichTextModel {
      titleLabel.attributedText = model.titleAttributeStr
    }
  }
}
