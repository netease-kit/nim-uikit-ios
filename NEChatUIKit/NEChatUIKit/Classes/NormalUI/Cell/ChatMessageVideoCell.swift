
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class ChatMessageVideoCell: ChatMessageImageCell {
  weak var weakModel: MessageVideoModel?
  public lazy var stateViewLeft: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  public lazy var timeLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .center
    return label
  }()

  public lazy var timeViewLeft: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(timeLabelLeft)
    NSLayoutConstraint.activate([
      timeLabelLeft.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
      timeLabelLeft.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      timeLabelLeft.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -4),
      timeLabelLeft.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.6)
    return view
  }()

  // Right
  public lazy var stateViewRight: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  public lazy var timeLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .center
    return label
  }()

  public lazy var timeViewRight: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(timeLabelRight)
    NSLayoutConstraint.activate([
      timeLabelRight.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
      timeLabelRight.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      timeLabelRight.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -4),
      timeLabelRight.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.6)
    return view
  }()

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
    contentImageViewLeft.addSubview(stateViewLeft)
    contentImageViewLeft.addCustomCorner(conrners: [.topLeft], radius: 8, backcolor: .white)
    NSLayoutConstraint.activate([
      stateViewLeft.centerXAnchor.constraint(equalTo: contentImageViewLeft.centerXAnchor),
      stateViewLeft.centerYAnchor.constraint(equalTo: contentImageViewLeft.centerYAnchor),
      stateViewLeft.heightAnchor.constraint(equalToConstant: 60),
      stateViewLeft.widthAnchor.constraint(equalToConstant: 60),
    ])

    contentImageViewLeft.addSubview(timeViewLeft)
    NSLayoutConstraint.activate([
      timeViewLeft.rightAnchor.constraint(equalTo: contentImageViewLeft.rightAnchor, constant: -7),
      timeViewLeft.bottomAnchor.constraint(equalTo: contentImageViewLeft.bottomAnchor, constant: -7),
    ])
  }

  open func setupUIRight() {
    contentImageViewRight.addSubview(stateViewRight)
    contentImageViewRight.addCustomCorner(conrners: [.topRight], radius: 8, backcolor: .white)
    NSLayoutConstraint.activate([
      stateViewRight.centerXAnchor.constraint(equalTo: contentImageViewRight.centerXAnchor),
      stateViewRight.centerYAnchor.constraint(equalTo: contentImageViewRight.centerYAnchor),
      stateViewRight.heightAnchor.constraint(equalToConstant: 60),
      stateViewRight.widthAnchor.constraint(equalToConstant: 60),
    ])

    contentImageViewRight.addSubview(timeViewRight)
    NSLayoutConstraint.activate([
      timeViewRight.rightAnchor.constraint(equalTo: contentImageViewRight.rightAnchor, constant: -7),
      timeViewRight.bottomAnchor.constraint(equalTo: contentImageViewRight.bottomAnchor, constant: -7),
    ])
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentImageView = isSend ? contentImageViewRight : contentImageViewLeft
    let timeView = isSend ? timeViewRight : timeViewLeft
    let timeLabel = isSend ? timeLabelRight : timeLabelLeft
    let stateView = isSend ? stateViewRight : stateViewLeft

    if let videoObject = model.message?.messageObject as? NIMVideoObject {
      if let path = videoObject.coverPath, FileManager.default.fileExists(atPath: path) {
        contentImageView.sd_setImage(
          with: URL(fileURLWithPath: path),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      } else {
        contentImageView.sd_setImage(
          with: URL(string: videoObject.coverUrl ?? ""),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      }

      if videoObject.duration > 0 {
        timeView.isHidden = false
        timeLabel.text = Date.getFormatPlayTime(TimeInterval(videoObject.duration / 1000))
      } else {
        timeView.isHidden = true
      }

      if let videoModel = model as? MessageVideoModel {
        weakModel?.cell = nil
        weakModel = videoModel
        videoModel.cell = self
        if videoModel.state == .Success {
          stateView.state = .VideoPlay
        } else {
          stateView.state = .VideoDownload
          stateView.setProgress(videoModel.progress)
          if videoModel.progress >= 1 {
            videoModel.state = .Success
          }
        }
      }
    }
  }

  override open func uploadProgress(byRight: Bool, _ progress: Float) {
    let stateView = byRight ? stateViewRight : stateViewLeft
    stateView.setProgress(progress)
  }
}
