//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open
class NEBaseCollectionMessageAudioCell: NEBaseCollectionMessageCell {
  public lazy var audioImageView: UIImageView = {
    var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
    audioImageView.translatesAutoresizingMaskIntoConstraints = false
    audioImageView.contentMode = .center
    audioImageView.animationDuration = 1
    if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"),
       let leftmage2 = UIImage.ne_imageNamed(name: "left_play_2"),
       let leftmage3 = UIImage.ne_imageNamed(name: "left_play_3") {
      audioImageView.animationImages = [leftImage1, leftmage2, leftmage3]
    }
    return audioImageView
  }()

  var audioTimeLabel = UILabel()
  public var bubbleImage = UIImageView()

  public var isPlaying = false

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// 初始化UI
  override open func setupCommonUI() {
    super.setupCommonUI()

    let receiveImage = NEKitChatConfig.shared.ui.messageProperties.leftBubbleBg ?? UIImage.ne_imageNamed(name: "chat_message_receive")
    bubbleImage.image = receiveImage?
      .resizableImage(withCapInsets: NEKitChatConfig.shared.ui.messageProperties.backgroundImageCapInsets)
    bubbleImage.translatesAutoresizingMaskIntoConstraints = false
    backView.addSubview(bubbleImage)
    contentWidth = bubbleImage.widthAnchor.constraint(equalToConstant: chat_content_maxW)
    contentHeight = bubbleImage.heightAnchor.constraint(equalToConstant: chat_content_maxW)
    bubbleImage.isUserInteractionEnabled = true
    NSLayoutConstraint.activate([
      contentHeight!,
      contentWidth!,
      bubbleImage.leftAnchor.constraint(equalTo: backView.leftAnchor, constant: 16),
      bubbleImage.bottomAnchor.constraint(equalTo: line.bottomAnchor, constant: -12),
    ])

    bubbleImage.addSubview(audioImageView)
    NSLayoutConstraint.activate([
      audioImageView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 16),
      audioImageView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      audioImageView.widthAnchor.constraint(equalToConstant: 28),
      audioImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    audioTimeLabel.font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.pinMessageTextSize)
    audioTimeLabel.textAlignment = .left
    audioTimeLabel.textColor = UIColor.ne_darkText
    audioTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.addSubview(audioTimeLabel)
    NSLayoutConstraint.activate([
      audioTimeLabel.leftAnchor.constraint(equalTo: audioImageView.rightAnchor, constant: 12),
      audioTimeLabel.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      audioTimeLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -12),
      audioTimeLabel.heightAnchor.constraint(equalToConstant: 28),
    ])

    if let gesture = contentGesture {
      bubbleImage.addGestureRecognizer(gesture)
    }
  }

  /// 绑定数据
  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let m = model.chatmodel as? MessageAudioModel {
      audioTimeLabel.text = "\(m.duration)" + "s"
      m.isPlaying == true ? startPlayAnimation() : stopPlayAnimation()
    }
  }

  /// 开始播放动画
  open func startPlayAnimation() {
    if !audioImageView.isAnimating {
      audioImageView.startAnimating()
    }
    if let m = collectionModel?.chatmodel as? MessageAudioModel {
      m.isPlaying = true
      isPlaying = true
    }
  }

  /// 停止播放动画
  open func stopPlayAnimation() {
    if audioImageView.isAnimating {
      audioImageView.stopAnimating()
    }
    if let m = collectionModel?.chatmodel as? MessageAudioModel {
      m.isPlaying = false
      isPlaying = false
    }
  }
}
