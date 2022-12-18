
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatReplyRightCell: ChatBaseRightCell {
  public let replyLabel = UILabel()
  public let textView = UITextView()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    replyLabel.font = UIFont.systemFont(ofSize: 12)
    replyLabel.textColor = UIColor(hexString: "#929299")
    replyLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(replyLabel)
    NSLayoutConstraint.activate([
      replyLabel.leadingAnchor.constraint(equalTo: bubbleImage.leadingAnchor, constant: 8),
      replyLabel.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: qChat_margin),
      replyLabel.heightAnchor.constraint(equalToConstant: 26.0),
      replyLabel.trailingAnchor.constraint(equalTo: bubbleImage.trailingAnchor, constant: -8),
    ])

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isScrollEnabled = false
    textView.showsVerticalScrollIndicator = false
    textView.isUserInteractionEnabled = false
    textView.textContainer.maximumNumberOfLines = 0
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.font = DefaultTextFont(16)
    textView.backgroundColor = .red
    textView.contentMode = .center
    textView.backgroundColor = .clear
    bubbleImage.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: 0),
      textView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 8),
      textView.topAnchor.constraint(
        equalTo: replyLabel.bottomAnchor,
        constant: -qChat_margin
      ),
      textView.bottomAnchor.constraint(
        equalTo: bubbleImage.bottomAnchor,
        constant: -qChat_margin
      ),
    ])
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageTextModel {
      textView.attributedText = m.attributeStr
    }
    replyLabel.text = model.replyText
  }
}
