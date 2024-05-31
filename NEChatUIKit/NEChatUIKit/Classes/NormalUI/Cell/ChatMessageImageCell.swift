
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import SDWebImage
import UIKit

@objcMembers
open class ChatMessageImageCell: NormalChatMessageBaseCell {
  public let contentImageViewLeft = UIImageView()
  public let contentImageViewRight = UIImageView()
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    contentImageViewLeft.translatesAutoresizingMaskIntoConstraints = false
    contentImageViewLeft.contentMode = .scaleAspectFill
    contentImageViewLeft.clipsToBounds = true
    contentImageViewLeft.accessibilityIdentifier = "id.thumbnail"
    contentImageViewLeft.addCustomCorner(
      conrners: [.bottomLeft, .bottomRight, .topRight],
      radius: 8,
      backcolor: .white
    )
    bubbleImageLeft.addSubview(contentImageViewLeft)
    NSLayoutConstraint.activate([
      contentImageViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: 0),
      contentImageViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: 0),
      contentImageViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: 0),
      contentImageViewLeft.bottomAnchor.constraint(
        equalTo: bubbleImageLeft.bottomAnchor,
        constant: 0
      ),
    ])
  }

  open func commonUIRight() {
    contentImageViewRight.translatesAutoresizingMaskIntoConstraints = false
    contentImageViewRight.contentMode = .scaleAspectFill
    contentImageViewRight.clipsToBounds = true
    contentImageViewRight.accessibilityIdentifier = "id.thumbnail"
    contentImageViewRight.addCustomCorner(
      conrners: [.topLeft, .bottomLeft, .bottomRight],
      radius: 8,
      backcolor: .white
    )

    bubbleImageRight.addSubview(contentImageViewRight)
    NSLayoutConstraint.activate([
      contentImageViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: 0),
      contentImageViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: 0),
      contentImageViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: 0),
      contentImageViewRight.bottomAnchor.constraint(
        equalTo: bubbleImageRight.bottomAnchor,
        constant: 0
      ),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    contentImageViewLeft.isHidden = showRight
    contentImageViewRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let contentImageView = isSend ? contentImageViewRight : contentImageViewLeft

    if let m = model as? MessageImageModel, let imageUrl = m.urlString {
      var options: SDWebImageOptions = [.retryFailed]
      if let imageObject = model.message?.attachment as? V2NIMMessageImageAttachment, imageObject.ext?.lowercased() != ".gif" {
        options = [.retryFailed, .progressiveLoad]
      }

      let context: [SDWebImageContextOption: Any] = [.imageThumbnailPixelSize: CGSize(width: 1000, height: 1000)]
      if imageUrl.hasPrefix("http") {
        let url = URL(string: imageUrl)
        contentImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: context)
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        contentImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: context)
      }
    } else {
      contentImageView.image = nil
    }
  }
}
