
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol ChatAudioCell {
  var isPlaying: Bool { get set }
  var messageId: String? { get set }
  func startAnimation()
  func stopAnimation()
}

@objcMembers
public class ChatAudioRightCell: ChatBaseRightCell, ChatAudioCell {
  var messageId: String?
  var isPlaying: Bool = false
  var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "audio_play"))
  var timeLabel = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    audioImageView.contentMode = .center
    audioImageView.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.addSubview(audioImageView)
    NSLayoutConstraint.activate([
      audioImageView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -16),
      audioImageView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      audioImageView.widthAnchor.constraint(equalToConstant: 28),
      audioImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    timeLabel.font = UIFont.systemFont(ofSize: 14)
    timeLabel.textColor = UIColor.ne_darkText
    timeLabel.textAlignment = .right
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.rightAnchor.constraint(equalTo: audioImageView.leftAnchor, constant: -12),
      timeLabel.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      timeLabel.heightAnchor.constraint(equalToConstant: 28),
    ])

    audioImageView.animationDuration = 1
    if let image1 = UIImage.ne_imageNamed(name: "play_1"),
       let image2 = UIImage.ne_imageNamed(name: "play_2"),
       let image3 = UIImage.ne_imageNamed(name: "play_3") {
      audioImageView.animationImages = [image1, image2, image3]
    }
  }

  func startAnimation() {
    if !audioImageView.isAnimating {
      audioImageView.startAnimating()
      if let m = contentModel as? MessageAudioModel {
        m.isPlaying = true
        isPlaying = true
      }
    }
  }

  func stopAnimation() {
    if audioImageView.isAnimating {
      audioImageView.stopAnimating()
      if let m = contentModel as? MessageAudioModel {
        m.isPlaying = false
        isPlaying = false
      }
    }
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
    if let m = model as? MessageAudioModel {
      timeLabel.text = "\(m.duration)" + "s"
      m.isPlaying ? startAnimation() : stopAnimation()
      messageId = m.message?.messageId
    }
  }
}
