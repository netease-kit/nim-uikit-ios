// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class NEBasePinMessageVideoCell: NEBasePinMessageImageCell {
  public lazy var stateView: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  public lazy var videoTimeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .center
    return label
  }()

  public lazy var timeView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(videoTimeLabel)
    NSLayoutConstraint.activate([
      videoTimeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
      videoTimeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      videoTimeLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -4),
      videoTimeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.6)
    return view
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    contentImageView.addSubview(stateView)
    contentImageView.addCustomCorner(conrners: [.topLeft], radius: 8, backcolor: .white)
    NSLayoutConstraint.activate([
      stateView.centerXAnchor.constraint(equalTo: contentImageView.centerXAnchor),
      stateView.centerYAnchor.constraint(equalTo: contentImageView.centerYAnchor),
      stateView.heightAnchor.constraint(equalToConstant: 60),
      stateView.widthAnchor.constraint(equalToConstant: 60),
    ])

    contentImageView.addSubview(timeView)
    NSLayoutConstraint.activate([
      timeView.rightAnchor.constraint(equalTo: contentImageView.rightAnchor, constant: -7),
      timeView.bottomAnchor.constraint(equalTo: contentImageView.bottomAnchor, constant: -7),
    ])

    stateView.isUserInteractionEnabled = false
  }

  override open func configure(_ item: NEPinMessageModel) {
    super.configure(item)

    if let videoObject = item.chatmodel.message?.attachment as? V2NIMMessageVideoAttachment {
      // 获取首帧
      let videoUrl = videoObject.url ?? ""
      let thumbUrl = V2NIMStorageUtil.videoCoverUrl(videoUrl, offset: 0)
      contentImageView.sd_setImage(
        with: URL(string: thumbUrl),
        placeholderImage: nil,
        options: .retryFailed,
        progress: nil,
        completed: nil
      )

      if videoObject.duration > 0 {
        timeView.isHidden = false
        videoTimeLabel.text = Date.getFormatPlayTime(TimeInterval(videoObject.duration / 1000))
      } else {
        timeView.isHidden = true
      }
    }
  }
}
