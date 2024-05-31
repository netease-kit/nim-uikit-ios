//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open
class NEBaseCollectionMessageImageCell: NEBaseCollectionMessageCell {
  /// 图片消息内容图片
  public let collectionContentImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.isUserInteractionEnabled = true
    return imageView
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

    collectionContentImageView.addCustomCorner(
      conrners: [.bottomLeft, .bottomRight, .topRight, .topLeft],
      radius: 8,
      backcolor: .white
    )
    backView.addSubview(collectionContentImageView)
    NSLayoutConstraint.activate([
      collectionContentImageView.leftAnchor.constraint(equalTo: line.leftAnchor, constant: 0),
      collectionContentImageView.bottomAnchor.constraint(equalTo: line.topAnchor, constant: -12),
    ])
    contentWidth = collectionContentImageView.widthAnchor.constraint(equalToConstant: 0)
    contentWidth?.isActive = true
    contentHeight = collectionContentImageView.heightAnchor.constraint(equalToConstant: 0)
    contentHeight?.isActive = true

    if let gesture = contentGesture {
      collectionContentImageView.addGestureRecognizer(gesture)
    }
  }

  override open func configureData(_ model: CollectionMessageModel) {
    super.configureData(model)
    if let m = model.chatmodel as? MessageImageModel, let imageUrl = m.urlString {
      if imageUrl.hasPrefix("http") {
        collectionContentImageView.sd_setImage(
          with: URL(string: imageUrl),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        collectionContentImageView.sd_setImage(with: url)
      }

    } else {
      collectionContentImageView.image = nil
    }
  }
}
