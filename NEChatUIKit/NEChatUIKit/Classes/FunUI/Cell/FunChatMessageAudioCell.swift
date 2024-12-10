// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class FunChatMessageAudioCell: FunChatMessageBaseCell, ChatAudioCellProtocol {
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

  public var contentLabelLeftViewWidthAnchor: NSLayoutConstraint?
  public var contentLabelLeftViewHeightAnchor: NSLayoutConstraint?
  public lazy var contentLabelLeftView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.white
    view.layer.cornerRadius = 4
    view.accessibilityIdentifier = "id.voiceToTextView"

    view.addSubview(contentLabelLeft)
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_content_margin),
      contentLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_content_margin + funMargin),
      contentLabelLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      contentLabelLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -chat_content_margin),
    ])
    return view
  }()

  public lazy var contentLabelLeft: UILabel = {
    let label = UILabel()
    label.font = messageTextFont
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .justified
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.voiceToText"
    return label
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

  public var contentLabelRightViewWidthAnchor: NSLayoutConstraint?
  public var contentLabelRightViewHeightAnchor: NSLayoutConstraint?
  public lazy var contentLabelRightView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.funRecordAudioProgressNormalColor
    view.layer.cornerRadius = 4
    view.accessibilityIdentifier = "id.voiceToTextView"

    view.addSubview(contentLabelRight)
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -chat_content_margin - funMargin),
      contentLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: chat_content_margin),
      contentLabelRight.topAnchor.constraint(equalTo: view.topAnchor, constant: chat_content_margin),
      contentLabelRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -chat_content_margin),
    ])
    return view
  }()

  public lazy var contentLabelRight: UILabel = {
    let label = UILabel()
    label.font = messageTextFont
    label.textColor = UIColor.ne_darkText
    label.textAlignment = .justified
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.accessibilityIdentifier = "id.voiceToText"
    return label
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func commonUILeft() {
    super.commonUILeft()
    bubbleImageLeft.addSubview(audioImageViewLeft)
    NSLayoutConstraint.activate([
      audioImageViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 16),
      audioImageViewLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
      audioImageViewLeft.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewLeft.heightAnchor.constraint(equalToConstant: 28),
    ])

    bubbleImageLeft.addSubview(timeLabelLeft)
    NSLayoutConstraint.activate([
      timeLabelLeft.leftAnchor.constraint(equalTo: audioImageViewLeft.rightAnchor, constant: 12),
      timeLabelLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
      timeLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -12),
      timeLabelLeft.heightAnchor.constraint(equalToConstant: 28),
    ])
    audioImageViewLeft.animationDuration = 1
    if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"),
       let leftmage2 = UIImage.ne_imageNamed(name: "left_play_2"),
       let leftmage3 = UIImage.ne_imageNamed(name: "left_play_3") {
      audioImageViewLeft.animationImages = [leftImage1, leftmage2, leftmage3]
    }

    contentView.addSubview(contentLabelLeftView)
    contentLabelLeftViewWidthAnchor = contentLabelLeftView.widthAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftViewWidthAnchor?.isActive = true
    contentLabelLeftViewHeightAnchor = contentLabelLeftView.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelLeftView.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: funMargin),
      contentLabelLeftView.topAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor, constant: 4),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()
    bubbleImageRight.addSubview(audioImageViewRight)
    NSLayoutConstraint.activate([
      audioImageViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -16),
      audioImageViewRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
      audioImageViewRight.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewRight.heightAnchor.constraint(equalToConstant: 28),
    ])

    bubbleImageRight.addSubview(timeLabelRight)
    NSLayoutConstraint.activate([
      timeLabelRight.rightAnchor.constraint(equalTo: audioImageViewRight.leftAnchor, constant: -12),
      timeLabelRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
      timeLabelRight.heightAnchor.constraint(equalToConstant: 28),
    ])

    audioImageViewRight.animationDuration = 1
    if let image1 = UIImage.ne_imageNamed(name: "play_1"),
       let image2 = UIImage.ne_imageNamed(name: "play_2"),
       let image3 = UIImage.ne_imageNamed(name: "play_3") {
      audioImageViewRight.animationImages = [image1, image2, image3]
    }

    contentView.addSubview(contentLabelRightView)
    contentLabelRightViewWidthAnchor = contentLabelRightView.widthAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightViewWidthAnchor?.isActive = true
    contentLabelRightViewHeightAnchor = contentLabelRightView.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightViewHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelRightView.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -funMargin),
      contentLabelRightView.topAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor, constant: 4),
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

      timeLabel.text = "\(m.duration)" + "″"
      m.isPlaying ? startAnimation(byRight: isSend) : stopAnimation(byRight: isSend)
      messageId = m.message?.messageClientId

      contentLabelRightView.isHidden = true
      contentLabelLeftView.isHidden = true
      if let text = m.text {
        let contentLabel = isSend ? contentLabelRight : contentLabelLeft
        let contentLabelView = isSend ? contentLabelRightView : contentLabelLeftView
        contentLabel.text = text
        contentLabelView.isHidden = false

        let textSize = String.getRealSize(text, messageTextFont, CGSize(width: audio_max_width - (chat_cell_margin * 2 + funMargin), height: CGFloat.greatestFiniteMagnitude))
        let contentWidth = ceil(textSize.width) + chat_cell_margin * 2 + funMargin
        let contentHeight = ceil(textSize.height) + chat_content_margin * 2
        let contentLabelViewWidthAnchor = isSend ? contentLabelRightViewWidthAnchor : contentLabelLeftViewWidthAnchor
        let contentLabelViewHeightAnchor = isSend ? contentLabelRightViewHeightAnchor : contentLabelLeftViewHeightAnchor
        contentLabelViewWidthAnchor?.constant = contentWidth
        contentLabelViewHeightAnchor?.constant = contentHeight
        model.height = fun_chat_min_h + contentHeight + chat_content_margin * 2 + model.fullNameHeight + chat_pin_height
        if let time = model.timeContent, !time.isEmpty {
          model.height += chat_timeCellH
        }
      }
    }
    super.setModel(model, isSend)
  }
}
