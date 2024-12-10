
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageAudioCell: NormalChatMessageBaseCell, ChatAudioCellProtocol {
  public var messageId: String?
  public var isPlaying: Bool = false

  public lazy var audioImageViewLeft: UIImageView = {
    let view = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
    view.contentMode = .center
    view.translatesAutoresizingMaskIntoConstraints = false
    view.accessibilityIdentifier = "id.animation"
    return view
  }()

  public lazy var timeLabelLeft: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .left
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  public lazy var contentLabelLeft: UILabel = {
    let label = UILabel()
    label.isHidden = true
    label.font = messageTextFont
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .justified
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.voiceToText"
    return label
  }()

  public lazy var backViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(audioImageViewLeft)
    NSLayoutConstraint.activate([
      audioImageViewLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_cell_margin),
      audioImageViewLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
      audioImageViewLeft.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewLeft.heightAnchor.constraint(equalToConstant: 28),
    ])

    view.addSubview(timeLabelLeft)
    NSLayoutConstraint.activate([
      timeLabelLeft.leftAnchor.constraint(equalTo: audioImageViewLeft.rightAnchor, constant: 12),
      timeLabelLeft.centerYAnchor.constraint(equalTo: audioImageViewLeft.centerYAnchor),
      timeLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
      timeLabelLeft.heightAnchor.constraint(equalToConstant: 28),
    ])
    audioImageViewLeft.animationDuration = 1
    if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"),
       let leftmage2 = UIImage.ne_imageNamed(name: "left_play_2"),
       let leftmage3 = UIImage.ne_imageNamed(name: "left_play_3") {
      audioImageViewLeft.animationImages = [leftImage1, leftmage2, leftmage3]
    }

    view.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_cell_margin),
      contentLabelLeft.topAnchor.constraint(equalTo: audioImageViewLeft.bottomAnchor, constant: 4),
      contentLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_cell_margin),
    ])
    return view
  }()

  public lazy var audioImageViewRight: UIImageView = {
    let view = UIImageView(image: UIImage.ne_imageNamed(name: "audio_play"))
    view.contentMode = .center
    view.translatesAutoresizingMaskIntoConstraints = false
    view.accessibilityIdentifier = "id.animation"
    return view
  }()

  public lazy var timeLabelRight: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 14)
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .right
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.time"
    return label
  }()

  public lazy var contentLabelRight: UILabel = {
    let label = UILabel()
    label.isHidden = true
    label.font = messageTextFont
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .justified
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.voiceToText"
    return label
  }()

  public lazy var backViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear

    view.addSubview(audioImageViewRight)
    NSLayoutConstraint.activate([
      audioImageViewRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_cell_margin),
      audioImageViewRight.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
      audioImageViewRight.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewRight.heightAnchor.constraint(equalToConstant: 28),
    ])

    view.addSubview(timeLabelRight)
    NSLayoutConstraint.activate([
      timeLabelRight.rightAnchor.constraint(equalTo: audioImageViewRight.leftAnchor, constant: -12),
      timeLabelRight.centerYAnchor.constraint(equalTo: audioImageViewRight.centerYAnchor),
      timeLabelRight.heightAnchor.constraint(equalToConstant: 28),
    ])

    audioImageViewRight.animationDuration = 1
    if let image1 = UIImage.ne_imageNamed(name: "play_1"),
       let image2 = UIImage.ne_imageNamed(name: "play_2"),
       let image3 = UIImage.ne_imageNamed(name: "play_3") {
      audioImageViewRight.animationImages = [image1, image2, image3]
    }

    view.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_cell_margin),
      contentLabelRight.topAnchor.constraint(equalTo: audioImageViewRight.bottomAnchor, constant: 4),
      contentLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_cell_margin),
    ])
    return view
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(backViewLeft)
    NSLayoutConstraint.activate([
      backViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 0),
      backViewLeft.topAnchor.constraint(equalTo: replyViewLeft.bottomAnchor, constant: 0),
      backViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: 0),
      backViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 0),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(backViewRight)
    NSLayoutConstraint.activate([
      backViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: 0),
      backViewRight.topAnchor.constraint(equalTo: replyViewRight.bottomAnchor, constant: 0),
      backViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
      backViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 0),
    ])
  }

  open func startAnimation(byRight: Bool) {
    let audioImageView = byRight ? audioImageViewRight : audioImageViewLeft
    if !audioImageView.isAnimating {
      audioImageView.startAnimating()
    }

    if let m = contentModel as? MessageAudioModel {
      m.isPlaying = true
      isPlaying = true
    }
  }

  open func stopAnimation(byRight: Bool) {
    let audioImageView = byRight ? audioImageViewRight : audioImageViewLeft
    if audioImageView.isAnimating {
      audioImageView.stopAnimating()
    }

    if let m = contentModel as? MessageAudioModel {
      m.isPlaying = false
      isPlaying = false
    }
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    audioImageViewLeft.isHidden = showRight
    timeLabelLeft.isHidden = showRight

    audioImageViewRight.isHidden = !showRight
    timeLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    if let m = model as? MessageAudioModel {
      contentModel = m
      let timeLabel = isSend ? timeLabelRight : timeLabelLeft

      timeLabel.text = "\(m.duration)" + "s"
      m.isPlaying ? startAnimation(byRight: isSend) : stopAnimation(byRight: isSend)
      messageId = m.message?.messageClientId

      contentLabelRight.isHidden = true
      contentLabelLeft.isHidden = true
      if let text = m.text {
        let contentLabel = isSend ? contentLabelRight : contentLabelLeft
        contentLabel.text = text
        contentLabel.isHidden = false
        let textSize = String.getRealSize(text, messageTextFont, CGSize(width: max(chat_text_maxW, m.audioWidth) - chat_cell_margin * 2, height: CGFloat.greatestFiniteMagnitude))
        let contentWidth = max(m.audioWidth, ceil(textSize.width) + chat_cell_margin * 2)
        let contentHeight = chat_min_h + ceil(textSize.height) + chat_content_margin
        model.contentSize = CGSize(width: contentWidth, height: contentHeight)
        model.height = model.contentSize.height + chat_content_margin * 2 + model.fullNameHeight + chat_pin_height
        if let time = model.timeContent, !time.isEmpty {
          model.height += chat_timeCellH
        }
      }
    }
    super.setModel(model, isSend)
  }
}
