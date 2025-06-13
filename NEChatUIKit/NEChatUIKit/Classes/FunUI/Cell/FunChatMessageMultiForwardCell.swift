
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunChatMessageMultiForwardCell: FunChatMessageBaseCell {
  let contentWidth: CGFloat = 228
  let titleLabelFontSize: CGFloat = 16
  let contentLabelFontSize: CGFloat = 12

  override open func commonUILeft() {
    bubbleImageLeft.image = nil
    let image = UIImage.ne_imageNamed(name: "multiForward_message_receive_fun")
    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      backViewLeft.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      backViewLeft.image = image
      backViewLeft.contentMode = .scaleAspectFill
    }

    bubbleImageLeft.addSubview(backViewLeft)
    NSLayoutConstraint.activate([
      backViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 0),
      backViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      backViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: -0),
      backViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -0),
    ])

    backViewLeft.addSubview(titleLabelLeft1)
    NSLayoutConstraint.activate([
      titleLabelLeft1.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: 12 + funMargin),
      titleLabelLeft1.rightAnchor.constraint(lessThanOrEqualTo: backViewLeft.rightAnchor, constant: NEAppLanguageUtil.getCurrentLanguage() == .english ? -114 : -102),
      titleLabelLeft1.topAnchor.constraint(equalTo: backViewLeft.topAnchor, constant: 12),
      titleLabelLeft1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backViewLeft.addSubview(titleLabelLeft2)
    NSLayoutConstraint.activate([
      titleLabelLeft2.leftAnchor.constraint(equalTo: titleLabelLeft1.rightAnchor),
      titleLabelLeft2.centerYAnchor.constraint(equalTo: titleLabelLeft1.centerYAnchor),
      titleLabelLeft2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelLeft2.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 100 : 88),
    ])

    backViewLeft.addSubview(contentLabelLeft1)
    NSLayoutConstraint.activate([
      contentLabelLeft1.leftAnchor.constraint(equalTo: titleLabelLeft1.leftAnchor),
      contentLabelLeft1.topAnchor.constraint(equalTo: titleLabelLeft1.bottomAnchor, constant: 4),
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
      contentHistoryLeft.bottomAnchor.constraint(equalTo: backViewLeft.bottomAnchor, constant: -8),
      contentHistoryLeft.heightAnchor.constraint(equalToConstant: 14),
    ])

    backViewLeft.addSubview(dividerLineLeft)
    NSLayoutConstraint.activate([
      dividerLineLeft.leftAnchor.constraint(equalTo: backViewLeft.leftAnchor, constant: funMargin),
      dividerLineLeft.rightAnchor.constraint(equalTo: backViewLeft.rightAnchor),
      dividerLineLeft.topAnchor.constraint(equalTo: contentHistoryLeft.topAnchor, constant: -8),
      dividerLineLeft.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  override open func commonUIRight() {
    bubbleImageRight.image = nil
    let image = UIImage.ne_imageNamed(name: "multiForward_message_send_fun")
    if let backgroundImageCapInsets = ChatUIConfig.shared.messageProperties.backgroundImageCapInsets {
      backViewRight.image = image?.resizableImage(withCapInsets: backgroundImageCapInsets)
    } else {
      backViewRight.image = image
      backViewRight.contentMode = .scaleAspectFill
    }

    bubbleImageRight.addSubview(backViewRight)
    NSLayoutConstraint.activate([
      backViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: 0),
      backViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      backViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: -0),
      backViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -0),
    ])

    backViewRight.addSubview(titleLabelRight1)
    NSLayoutConstraint.activate([
      titleLabelRight1.leftAnchor.constraint(equalTo: backViewRight.leftAnchor, constant: 12),
      titleLabelRight1.rightAnchor.constraint(lessThanOrEqualTo: backViewRight.rightAnchor, constant: NEAppLanguageUtil.getCurrentLanguage() == .english ? -114 : -102),
      titleLabelRight1.topAnchor.constraint(equalTo: backViewRight.topAnchor, constant: 12),
      titleLabelRight1.heightAnchor.constraint(equalToConstant: 22),
    ])

    backViewRight.addSubview(titleLabelRight2)
    NSLayoutConstraint.activate([
      titleLabelRight2.leftAnchor.constraint(equalTo: titleLabelRight1.rightAnchor),
      titleLabelRight2.centerYAnchor.constraint(equalTo: titleLabelRight1.centerYAnchor),
      titleLabelRight2.heightAnchor.constraint(equalToConstant: 22),
      titleLabelRight2.widthAnchor.constraint(equalToConstant: NEAppLanguageUtil.getCurrentLanguage() == .english ? 100 : 88),
    ])

    backViewRight.addSubview(contentLabelRight1)
    NSLayoutConstraint.activate([
      contentLabelRight1.leftAnchor.constraint(equalTo: titleLabelRight1.leftAnchor),
      contentLabelRight1.topAnchor.constraint(equalTo: titleLabelRight1.bottomAnchor, constant: 4),
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
      contentHistoryRight.bottomAnchor.constraint(equalTo: backViewRight.bottomAnchor, constant: -8),
      contentHistoryRight.heightAnchor.constraint(equalToConstant: 14),
    ])

    backViewRight.addSubview(dividerLineRight)
    NSLayoutConstraint.activate([
      dividerLineRight.leftAnchor.constraint(equalTo: backViewRight.leftAnchor),
      dividerLineRight.rightAnchor.constraint(equalTo: backViewRight.rightAnchor, constant: -funMargin),
      dividerLineRight.topAnchor.constraint(equalTo: contentHistoryRight.topAnchor, constant: -8),
      dividerLineRight.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    guard let data = NECustomUtils.dataOfCustomMessage(model.message?.attachment) else {
      return
    }

    let font = UIFont.systemFont(ofSize: contentLabelFontSize)
    let bubbleW = isSend ? bubbleWRight : bubbleWLeft
    let bubbleH = isSend ? bubbleHRight : bubbleHLeft
    let titleLabel = isSend ? titleLabelRight1 : titleLabelLeft1
    let titleLabel2 = isSend ? titleLabelRight2 : titleLabelLeft2
    let contentLabel1 = isSend ? contentLabelRight1 : contentLabelLeft1
    let contentLabel2 = isSend ? contentLabelRight2 : contentLabelLeft2
    let contentLabel3 = isSend ? contentLabelRight3 : contentLabelLeft3

    bubbleW?.constant = 256
    bubbleH?.constant = 130

    if let sessionName = data["sessionName"] as? String {
      titleLabel.attributedText =
        NEEmotionTool.getAttWithStr(str: sessionName,
                                    font: .systemFont(ofSize: titleLabelFontSize),
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
      if let senderNick = abstracts[i]["senderNick"] as? String {
        contentText = NEFriendUserCache.getCutName(senderNick)
        if let content = abstracts[i]["content"] as? String {
          contentText += "：" + content
        }
      }

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 1 // 设置行间距
      paragraphStyle.lineBreakMode = .byTruncatingTail
      let attributedText = NEEmotionTool.getAttWithStr(str: contentText,
                                                       font: font,
                                                       color: .funChatMultiForwardContentColor)
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
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
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
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.contentHistoryLeft"
    return label
  }()

  public lazy var backViewRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
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
    label.textAlignment = .left
    label.accessibilityIdentifier = "id.contentHistoryRight"
    return label
  }()
}
