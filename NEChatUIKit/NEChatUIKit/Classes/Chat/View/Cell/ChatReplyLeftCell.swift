
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatReplyLeftCell: ChatBaseLeftCell {
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
      replyLabel.leadingAnchor.constraint(equalTo: bubbleImage.leadingAnchor, constant: qChat_margin),
      replyLabel.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: qChat_margin - 1),
      replyLabel.heightAnchor.constraint(equalToConstant: 26.0),
      replyLabel.trailingAnchor.constraint(equalTo: bubbleImage.trailingAnchor, constant: -qChat_margin),
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
      textView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -qChat_margin),
      textView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: qChat_margin),
      textView.topAnchor.constraint(equalTo: replyLabel.bottomAnchor, constant: -(qChat_margin - 1)),
      textView.bottomAnchor.constraint(equalTo: bubbleImage.bottomAnchor, constant: -qChat_margin),
    ])
  }

  func sizeWidthFromString(_ text: String, _ font: UIFont) -> Double {
    // 根据内容计算size
    let maxSize = CGSize(width: qChat_content_maxW, height: 0)
    let attibutes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
    let labelSize = NSString(string: text).boundingRect(with: maxSize, attributes: attibutes, context: nil)
    return ceil(labelSize.width) + qChat_margin * 2
  }

  override open func setModel(_ model: MessageContentModel) {
    if let m = model as? MessageTextModel {
      textView.attributedText = m.attributeStr
      if let text = textView.attributedText,
         let font = textView.font {
        model.contentSize.width = max(sizeWidthFromString(text.string, font), model.contentSize.width)
      }
    }

    if let text = model.replyText,
       let font = replyLabel.font {
      replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                              font: replyLabel.font,
                                                              color: replyLabel.textColor)
      model.contentSize.width = max(sizeWidthFromString(text, font), model.contentSize.width)
    }

    super.setModel(model)
  }
}
