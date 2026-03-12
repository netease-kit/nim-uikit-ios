//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NIMSDK
import SDWebImage
import UIKit

open class NEHistorySearchVideoCell: NEHistorySearchImageCell {
  public let iconImageView = UIImageView()
  public let timeLabel = UILabel()
  weak var currentModel: MessageVideoModel?

  public lazy var stateView: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override public func setupUI() {
    super.setupUI()
    contentView.addSubview(stateView)
    stateView.isHidden = true
    NSLayoutConstraint.activate([
      stateView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
      stateView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
      stateView.heightAnchor.constraint(equalToConstant: 60),
      stateView.widthAnchor.constraint(equalToConstant: 60),
    ])

    contentView.addSubview(iconImageView)
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.image = UIImage.ne_imageNamed(name: "history_search_video")

    NSLayoutConstraint.activate([
      iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
      iconImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      iconImageView.widthAnchor.constraint(equalToConstant: 24),
      iconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])

    contentView.addSubview(timeLabel)
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.textColor = .white
    timeLabel.font = .systemFont(ofSize: 12)

    NSLayoutConstraint.activate([
      timeLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
      timeLabel.leftAnchor.constraint(equalTo: iconImageView.rightAnchor, constant: 4),
    ])
  }

  override open func prepareForReuse() {
    super.prepareForReuse()
    currentModel = nil
  }

  override func configure(with model: MessageImageModel) {
    if let model = model as? MessageVideoModel,
       let videoObject = model.message?.attachment as? V2NIMMessageVideoAttachment {
      currentModel = model
      currentModel?.historyVideoCell = self

      // 获取首帧
      let videoUrl = videoObject.url ?? ""
      let thumbUrl = V2NIMStorageUtil.videoCoverUrl(videoUrl, offset: 0)
      imageView.sd_setImage(
        with: URL(string: thumbUrl),
        placeholderImage: nil,
        options: .retryFailed,
        progress: nil,
        completed: nil
      )

      if videoObject.duration > 0 {
        timeLabel.isHidden = false
        timeLabel.text = Date.getFormatPlayTime(TimeInterval(videoObject.duration / 1000))
      } else {
        timeLabel.isHidden = true
      }
    }
  }

  open func uploadProgress(_ progress: UInt) {
    guard let model = currentModel else { return }

    if model.state == .Success {
      stateView.state = .VideoPlay
      stateView.isHidden = true
    } else {
      stateView.state = .VideoDownload
      stateView.isHidden = false
      stateView.setProgress(Float(model.progress) / 100.0)
    }
  }
}
