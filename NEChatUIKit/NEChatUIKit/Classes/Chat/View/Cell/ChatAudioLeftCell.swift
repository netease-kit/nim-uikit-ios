
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class ChatAudioLeftCell: ChatBaseLeftCell, ChatAudioCell {
  var isPlaying: Bool = false
  var audioImageView = UIImageView(image: UIImage.ne_imageNamed(name: "left_play_3"))
  var timeLabel = UILabel()
  var messageId: String?
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
      audioImageView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 16),
      audioImageView.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      audioImageView.widthAnchor.constraint(equalToConstant: 28),
      audioImageView.heightAnchor.constraint(equalToConstant: 28),
    ])

    timeLabel.font = UIFont.systemFont(ofSize: 14)
    timeLabel.textColor = UIColor.ne_darkText
    timeLabel.textAlignment = .left
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    bubbleImage.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.leftAnchor.constraint(equalTo: audioImageView.rightAnchor, constant: 12),
      timeLabel.centerYAnchor.constraint(equalTo: bubbleImage.centerYAnchor),
      timeLabel.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: -12),
      timeLabel.heightAnchor.constraint(equalToConstant: 28),
    ])
    audioImageView.animationDuration = 1
    if let leftImage1 = UIImage.ne_imageNamed(name: "left_play_1"),
       let leftmage2 = UIImage.ne_imageNamed(name: "left_play_2"),
       let leftmage3 = UIImage.ne_imageNamed(name: "left_play_3") {
      audioImageView.animationImages = [leftImage1, leftmage2, leftmage3]
    }
  }

  func startAnimation() {
    if !audioImageView.isAnimating {
//            self.messageModel?.audioPlaying = true
      audioImageView.startAnimating()
    }
  }

  func stopAnimation() {
    if audioImageView.isAnimating {
//            self.messageModel?.audioPlaying = false
      audioImageView.stopAnimating()
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
