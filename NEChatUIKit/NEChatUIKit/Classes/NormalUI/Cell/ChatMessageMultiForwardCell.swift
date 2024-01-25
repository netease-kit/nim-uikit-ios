
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class ChatMessageMultiForwardCell: NormalChatMessageBaseCell {
  let contentWidth: CGFloat = 234
  let titleLabelFontSize: CGFloat = 14
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func setupUI() {
    setupUIRight()
    setupUILeft()
  }

  open func setupUILeft() {
    bubbleImageLeft.image = nil
    let image = UIImage.ne_imageNamed(name: "multiForward_message_receive")
    backViewLeft.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)
    bubbleImageLeft.addSubview(backViewLeft)
    NSLayoutConstraint.activate([
      backViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor),
      backViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      backViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
      backViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor),
    ])

    backViewLeft.addSubview(titleLabelLeft1)
    NSLayoutConstraint.activate([
      titleLabelLeft1.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: 16),
      titleLabelLeft1.rightAnchor.constraint(lessThanOrEqualTo: backViewLeft.rightAnchor, constant: -84),
      titleLabelLeft1.topAnchor.constraint(equalTo: backViewLeft.topAnchor, constant: 10),
      titleLabelLeft1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backViewLeft.addSubview(titleLabelLeft2)
    NSLayoutConstraint.activate([
      titleLabelLeft2.leftAnchor.constraint(equalTo: titleLabelLeft1.rightAnchor),
      titleLabelLeft2.centerYAnchor.constraint(equalTo: titleLabelLeft1.centerYAnchor),
      titleLabelLeft2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelLeft2.widthAnchor.constraint(equalToConstant: 74),
    ])

    backViewLeft.addSubview(contentLabelLeft1)
    NSLayoutConstraint.activate([
      contentLabelLeft1.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
      contentLabelLeft1.topAnchor.constraint(equalTo: titleLabelLeft1.bottomAnchor, constant: 2),
      contentLabelLeft1.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelLeft1.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewLeft.addSubview(contentLabelLeft2)
    NSLayoutConstraint.activate([
      contentLabelLeft2.leftAnchor.constraint(equalTo: contentLabelLeft1.leftAnchor),
      contentLabelLeft2.topAnchor.constraint(equalTo: contentLabelLeft1.bottomAnchor),
      contentLabelLeft2.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelLeft2.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewLeft.addSubview(contentLabelLeft3)
    NSLayoutConstraint.activate([
      contentLabelLeft3.leftAnchor.constraint(equalTo: contentLabelLeft2.leftAnchor),
      contentLabelLeft3.topAnchor.constraint(equalTo: contentLabelLeft2.bottomAnchor),
      contentLabelLeft3.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelLeft3.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewLeft.addSubview(contentHistoryLeft)
    NSLayoutConstraint.activate([
      contentHistoryLeft.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
      contentHistoryLeft.bottomAnchor.constraint(equalTo: backViewLeft.bottomAnchor, constant: -12),
      contentHistoryLeft.widthAnchor.constraint(equalToConstant: 60),
      contentHistoryLeft.heightAnchor.constraint(equalToConstant: 14),
    ])

    backViewLeft.addSubview(dividerLineLeft)
    NSLayoutConstraint.activate([
      dividerLineLeft.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: 6),
      dividerLineLeft.rightAnchor.constraint(equalTo: backViewLeft.rightAnchor, constant: -6),
      dividerLineLeft.topAnchor.constraint(equalTo: contentHistoryLeft.topAnchor, constant: -6),
      dividerLineLeft.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  open func setupUIRight() {
    bubbleImageRight.image = nil
    let image = UIImage.ne_imageNamed(name: "multiForward_message_send")
    backViewRight.image = image?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)
    bubbleImageRight.addSubview(backViewRight)
    NSLayoutConstraint.activate([
      backViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor),
      backViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor),
      backViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor),
      backViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor),
    ])

    backViewRight.addSubview(titleLabelRight1)
    NSLayoutConstraint.activate([
      titleLabelRight1.leftAnchor.constraint(equalTo: backViewRight.leftAnchor, constant: 16),
      titleLabelRight1.rightAnchor.constraint(lessThanOrEqualTo: backViewRight.rightAnchor, constant: -84),
      titleLabelRight1.topAnchor.constraint(equalTo: backViewRight.topAnchor, constant: 10),
      titleLabelRight1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backViewRight.addSubview(titleLabelRight2)
    NSLayoutConstraint.activate([
      titleLabelRight2.leftAnchor.constraint(equalTo: titleLabelRight1.rightAnchor),
      titleLabelRight2.centerYAnchor.constraint(equalTo: titleLabelRight1.centerYAnchor),
      titleLabelRight2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelRight2.widthAnchor.constraint(equalToConstant: 74),
    ])

    backViewRight.addSubview(contentLabelRight1)
    NSLayoutConstraint.activate([
      contentLabelRight1.leftAnchor.constraint(equalTo: titleLabelRight1.leftAnchor),
      contentLabelRight1.topAnchor.constraint(equalTo: titleLabelRight1.bottomAnchor, constant: 2),
      contentLabelRight1.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelRight1.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewRight.addSubview(contentLabelRight2)
    NSLayoutConstraint.activate([
      contentLabelRight2.leftAnchor.constraint(equalTo: contentLabelRight1.leftAnchor),
      contentLabelRight2.topAnchor.constraint(equalTo: contentLabelRight1.bottomAnchor),
      contentLabelRight2.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelRight2.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewRight.addSubview(contentLabelRight3)
    NSLayoutConstraint.activate([
      contentLabelRight3.leftAnchor.constraint(equalTo: contentLabelRight2.leftAnchor),
      contentLabelRight3.topAnchor.constraint(equalTo: contentLabelRight2.bottomAnchor),
      contentLabelRight3.widthAnchor.constraint(equalToConstant: contentWidth),
      contentLabelRight3.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
    ])

    backViewRight.addSubview(contentHistoryRight)
    NSLayoutConstraint.activate([
      contentHistoryRight.leftAnchor.constraint(equalTo: titleLabelRight1.leftAnchor),
      contentHistoryRight.bottomAnchor.constraint(equalTo: backViewRight.bottomAnchor, constant: -12),
      contentHistoryRight.widthAnchor.constraint(equalToConstant: 60),
      contentHistoryRight.heightAnchor.constraint(equalToConstant: 14),
    ])

    backViewRight.addSubview(dividerLineRight)
    NSLayoutConstraint.activate([
      dividerLineRight.leftAnchor.constraint(equalTo: backViewRight.leftAnchor, constant: 6),
      dividerLineRight.rightAnchor.constraint(equalTo: backViewRight.rightAnchor, constant: -6),
      dividerLineRight.topAnchor.constraint(equalTo: contentHistoryRight.topAnchor, constant: -6),
      dividerLineRight.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    guard let data = NECustomAttachment.dataOfCustomMessage(message: model.message) else {
      return
    }

    let font = UIFont.systemFont(ofSize: titleLabelFontSize)
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubbleH = isSend ? bubbleHRight : bubbleHLeft
    let titleLabel = isSend ? titleLabelRight1 : titleLabelLeft1
    let titleLabel2 = isSend ? titleLabelRight2 : titleLabelLeft2
    let contentLabel1 = isSend ? contentLabelRight1 : contentLabelLeft1
    let contentLabel2 = isSend ? contentLabelRight2 : contentLabelLeft2
    let contentLabel3 = isSend ? contentLabelRight3 : contentLabelLeft3

    bubbleW?.constant = 266
    bubbleH?.constant = 130

    if let sessionName = data["sessionName"] as? String {
      titleLabel.attributedText =
        NEEmotionTool.getAttWithStr(str: sessionName,
                                    font: .systemFont(ofSize: titleLabelFontSize, weight: .semibold),
                                    color: .ne_darkText)
    } else {
      titleLabel2.text = chatLocalizable("chat_history")
    }

    guard let abstracts = data["abstracts"] as? [[String: Any]] else { return }

    contentLabel2.attributedText = nil
    contentLabel3.attributedText = nil
    for i in 0 ..< abstracts.count {
      var contentLabel = contentLabel1
      if i == 1 {
        contentLabel = contentLabel2
      } else if i == 2 {
        contentLabel = contentLabel3
      }

      var contentText = ""
      if var senderNick = abstracts[i]["senderNick"] as? String {
        if senderNick.count > 5 {
          // 截取字符串 abcdefg -> ab...fg
          let leftEndIndex = senderNick.index(senderNick.startIndex, offsetBy: 2)
          let rightStartIndex = senderNick.index(senderNick.endIndex, offsetBy: -2)
          senderNick = senderNick[senderNick.startIndex ..< leftEndIndex] + "..." + senderNick[rightStartIndex ..< senderNick.endIndex]
        }
        contentText = senderNick
        if let content = abstracts[i]["content"] as? String {
          contentText += "：" + content
        }
      }

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 1 // 设置行间距
      paragraphStyle.lineBreakMode = .byTruncatingTail
      let attributedText = NEEmotionTool.getAttWithStr(str: contentText,
                                                       font: font,
                                                       color: .ne_lightText)
      attributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedText.length))
      contentLabel.attributedText = attributedText
    }

    let numCount1 = String.calculateMaxLines(width: contentWidth,
                                             attributeString: contentLabel1.attributedText,
                                             font: font)
    if numCount1 == 1 {
      contentLabel2.numberOfLines = 2
      contentLabel2.isHidden = contentLabel2.attributedText == nil
      let numCount2 = String.calculateMaxLines(width: contentWidth,
                                               attributeString: contentLabel2.attributedText,
                                               font: font)
      contentLabel3.isHidden = contentLabel3.attributedText == nil || numCount2 >= 2
    } else if numCount1 == 2 {
      contentLabel2.numberOfLines = 1
      contentLabel2.isHidden = contentLabel2.attributedText == nil
      contentLabel3.isHidden = true
    } else {
      contentLabel2.isHidden = true
      contentLabel3.isHidden = true
    }
  }

  // MARK: - lazy load

  public lazy var backViewLeft: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public lazy var titleLabelLeft1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name1"
    return label
  }()

  public lazy var titleLabelLeft2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("chat_history_by")
    label.textColor = .ne_darkText
    label.font = .systemFont(ofSize: titleLabelFontSize, weight: .semibold)
    label.accessibilityIdentifier = "id.name2"
    return label
  }()

  public lazy var contentLabelLeft1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 3
    label.accessibilityIdentifier = "id.content1"
    return label
  }()

  public lazy var contentLabelLeft2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 2
    label.accessibilityIdentifier = "id.content2"
    return label
  }()

  public lazy var contentLabelLeft3: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.content3"
    return label
  }()

  public lazy var dividerLineLeft: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = multiForwardLineColor
    return line
  }()

  public lazy var contentHistoryLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 12)
    label.textColor = .ne_lightText
    label.text = chatLocalizable("chat_history")
    label.accessibilityIdentifier = "id.contentHistoryLeft"
    return label
  }()

  public lazy var backViewRight: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public lazy var titleLabelRight1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.name1"
    return label
  }()

  public lazy var titleLabelRight2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = chatLocalizable("chat_history_by")
    label.textColor = .ne_darkText
    label.font = .systemFont(ofSize: titleLabelFontSize, weight: .semibold)
    label.accessibilityIdentifier = "id.name2"
    return label
  }()

  public lazy var contentLabelRight1: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 3
    label.accessibilityIdentifier = "id.content1"
    return label
  }()

  public lazy var contentLabelRight2: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 2
    label.accessibilityIdentifier = "id.content2"
    return label
  }()

  public lazy var contentLabelRight3: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.content3"
    return label
  }()

  public lazy var dividerLineRight: UIView = {
    let line = UIView()
    line.translatesAutoresizingMaskIntoConstraints = false
    line.backgroundColor = multiForwardLineColor
    return line
  }()

  public lazy var contentHistoryRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 12)
    label.textColor = .ne_lightText
    label.text = chatLocalizable("chat_history")
    label.accessibilityIdentifier = "id.contentHistoryRight"
    return label
  }()
}
