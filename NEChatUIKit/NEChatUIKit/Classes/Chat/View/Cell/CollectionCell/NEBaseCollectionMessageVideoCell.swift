//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open
class NEBaseCollectionMessageVideoCell: NEBaseCollectionMessageImageCell {
  /// 状态视图
  public lazy var collectionStateView: VideoStateView = {
    let state = VideoStateView()
    state.translatesAutoresizingMaskIntoConstraints = false
    state.backgroundColor = .clear
    return state
  }()

  /// 视频时间
  public lazy var collectionVideoTimeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.font = NEConstant.defaultTextFont(10.0)
    label.textAlignment = .center
    return label
  }()

  public lazy var collectionTimeView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionVideoTimeLabel)
    NSLayoutConstraint.activate([
      collectionVideoTimeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 4),
      collectionVideoTimeLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
      collectionVideoTimeLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -4),
      collectionVideoTimeLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2),
    ])
    view.clipsToBounds = true
    view.layer.cornerRadius = 4.0
    view.backgroundColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.6)
    return view
  }()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

  /// 初始化的生命周期
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  /// 反序列化支持回调
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupCommonUI() {
    super.setupCommonUI()
    collectionContentImageView.addSubview(collectionStateView)
    collectionContentImageView.addCustomCorner(conrners: [.topLeft], radius: 8, backcolor: .white)
    NSLayoutConstraint.activate([
      collectionStateView.centerXAnchor.constraint(equalTo: collectionContentImageView.centerXAnchor),
      collectionStateView.centerYAnchor.constraint(equalTo: collectionContentImageView.centerYAnchor),
      collectionStateView.heightAnchor.constraint(equalToConstant: 60),
      collectionStateView.widthAnchor.constraint(equalToConstant: 60),
    ])

    collectionContentImageView.addSubview(collectionTimeView)
    NSLayoutConstraint.activate([
      collectionTimeView.rightAnchor.constraint(equalTo: collectionContentImageView.rightAnchor, constant: -7),
      collectionTimeView.bottomAnchor.constraint(equalTo: collectionContentImageView.bottomAnchor, constant: -7),
    ])

    collectionStateView.isUserInteractionEnabled = false
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let videoObject = model.chatmodel.message?.attachment as? V2NIMMessageVideoAttachment {
      // 获取首帧
      let videoUrl = videoObject.url ?? ""
      let thumbUrl = V2NIMStorageUtil.videoCoverUrl(videoUrl, offset: 0)
      collectionContentImageView.sd_setImage(
        with: URL(string: thumbUrl),
        placeholderImage: nil,
        options: .retryFailed,
        progress: nil,
        completed: nil
      )

      if videoObject.duration > 0 {
        collectionTimeView.isHidden = false
        collectionVideoTimeLabel.text = Date.getFormatPlayTime(TimeInterval(videoObject.duration / 1000))
      } else {
        collectionTimeView.isHidden = true
      }
    }
  }
}
