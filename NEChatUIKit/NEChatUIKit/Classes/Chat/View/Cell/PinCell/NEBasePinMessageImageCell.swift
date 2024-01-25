// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEBasePinMessageImageCell: NEBasePinMessageCell {
  public let contentImageView = UIImageView()

  override open func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func setupUI() {
    super.setupUI()
    contentImageView.translatesAutoresizingMaskIntoConstraints = false
    contentImageView.contentMode = .scaleAspectFill
    contentImageView.clipsToBounds = true
    contentImageView.isUserInteractionEnabled = true
    contentImageView.addCustomCorner(
      conrners: [.bottomLeft, .bottomRight, .topRight, .topLeft],
      radius: 8,
      backcolor: .white
    )
    backView.addSubview(contentImageView)
    NSLayoutConstraint.activate([
      contentImageView.leftAnchor.constraint(equalTo: line.leftAnchor, constant: 0),
      contentImageView.topAnchor.constraint(equalTo: line.bottomAnchor, constant: 12),
    ])
    contentWidth = contentImageView.widthAnchor.constraint(equalToConstant: 0)
    contentWidth?.isActive = true
    contentHeight = contentImageView.heightAnchor.constraint(equalToConstant: 0)
    contentHeight?.isActive = true

    if let gesture = contentGesture {
      contentImageView.addGestureRecognizer(gesture)
    }
  }

  override open func configure(_ item: PinMessageModel) {
    super.configure(item)

    if let m = item.chatmodel as? MessageImageModel, let imageUrl = m.imageUrl {
      if imageUrl.hasPrefix("http") {
        contentImageView.sd_setImage(
          with: URL(string: imageUrl),
          placeholderImage: nil,
          options: .retryFailed,
          progress: nil,
          completed: nil
        )
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        contentImageView.sd_setImage(with: url)
      }

    } else {
      contentImageView.image = nil
    }
  }
}
