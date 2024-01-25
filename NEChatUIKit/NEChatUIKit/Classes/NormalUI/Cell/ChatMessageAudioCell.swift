
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageAudioCell: NormalChatMessageBaseCell, ChatAudioCellProtocol {
  public var messageId: String?
  public var isPlaying: Bool = false

  public var audioImageViewLeft = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
  public var timeLabelLeft = UILabel()

  public var audioImageViewRight = UIImageView(image: UIImage.ne_imageNamed(name: "audio_play"))
  public var timeLabelRight = UILabel()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    audioImageViewLeft.contentMode = .center
    audioImageViewLeft.translatesAutoresizingMaskIntoConstraints = false
    audioImageViewLeft.accessibilityIdentifier = "id.animation"
    bubbleImageLeft.addSubview(audioImageViewLeft)
    NSLayoutConstraint.activate([
      audioImageViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 16),
      audioImageViewLeft.centerYAnchor.constraint(equalTo: bubbleImageLeft.centerYAnchor),
      audioImageViewLeft.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewLeft.heightAnchor.constraint(equalToConstant: 28),
    ])

    timeLabelLeft.font = UIFont.systemFont(ofSize: 14)
    timeLabelLeft.textColor = UIColor.ne_darkText
    timeLabelLeft.textAlignment = .left
    timeLabelLeft.translatesAutoresizingMaskIntoConstraints = false
    timeLabelLeft.accessibilityIdentifier = "id.time"
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
  }

  open func commonUIRight() {
    audioImageViewRight.contentMode = .center
    audioImageViewRight.translatesAutoresizingMaskIntoConstraints = false
    audioImageViewRight.accessibilityIdentifier = "id.animation"
    bubbleImageRight.addSubview(audioImageViewRight)
    NSLayoutConstraint.activate([
      audioImageViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -16),
      audioImageViewRight.centerYAnchor.constraint(equalTo: bubbleImageRight.centerYAnchor),
      audioImageViewRight.widthAnchor.constraint(equalToConstant: 28),
      audioImageViewRight.heightAnchor.constraint(equalToConstant: 28),
    ])

    timeLabelRight.font = UIFont.systemFont(ofSize: 14)
    timeLabelRight.textColor = UIColor.ne_darkText
    timeLabelRight.textAlignment = .right
    timeLabelRight.translatesAutoresizingMaskIntoConstraints = false
    timeLabelRight.accessibilityIdentifier = "id.time"
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
  }

  open func startAnimation(byRight: Bool) {
    if byRight {
      if !audioImageViewRight.isAnimating {
        audioImageViewRight.startAnimating()
      }
    } else if !audioImageViewLeft.isAnimating {
      audioImageViewLeft.startAnimating()
    }
    if let m = contentModel as? MessageAudioModel {
      m.isPlaying = true
      isPlaying = true
    }
  }

  open func stopAnimation(byRight: Bool) {
    if byRight {
      if audioImageViewRight.isAnimating {
        audioImageViewRight.stopAnimating()
      }
    } else if audioImageViewLeft.isAnimating {
      audioImageViewLeft.stopAnimating()
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
    super.setModel(model, isSend)
    if let m = model as? MessageAudioModel {
      if isSend {
        timeLabelRight.text = "\(m.duration)" + "s"
      } else {
        timeLabelLeft.text = "\(m.duration)" + "s"
      }
      m.isPlaying ? startAnimation(byRight: isSend) : stopAnimation(byRight: isSend)
      messageId = m.message?.messageId
    }
  }
}
