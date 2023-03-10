
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NECommonKit
import NIMSDK

@objcMembers
public class ChatVideoRightCell: ChatImageRightCell {
  weak var weakModel: MessageVideoModel?

  lazy var stateView: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .center
    return label
  }()

  lazy var timeView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
      timeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      timeLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -4),
      timeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.6)
    return view
  }()

  override public func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override public func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//        bubbleImage.addCorner(conrners: .allCorners ,radius: 8)
//        contentImageView.addCorner(conrners: .allCorners, radius: 8)
//    }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setupUI() {
    contentImageView.addSubview(stateView)
    contentImageView.addCustomCorner(conrners: [.topRight], radius: 8, backcolor: .white)
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
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
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

  override public func uploadProgress(_ progress: Float) {
    stateView.setProgress(progress)
  }
}
