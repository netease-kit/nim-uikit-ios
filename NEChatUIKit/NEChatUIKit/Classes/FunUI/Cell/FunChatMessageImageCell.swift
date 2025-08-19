// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import SDWebImage
import UIKit

@objcMembers
open class FunChatMessageImageCell: FunChatMessageBaseCell {
  public lazy var contentImageViewLeft: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 4
    imageView.accessibilityIdentifier = "id.thumbnail"
    return imageView
  }()

  public lazy var contentImageViewRight: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 4
    imageView.accessibilityIdentifier = "id.thumbnail"
    return imageView
  }()

  override open func commonUILeft() {
    super.commonUILeft()

    bubbleImageLeft.image = nil
    bubbleImageLeft.addSubview(contentImageViewLeft)
    NSLayoutConstraint.activate([
      contentImageViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor),
      contentImageViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor),
      contentImageViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      contentImageViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
    ])
  }

  override open func commonUIRight() {
    super.commonUIRight()

    bubbleImageRight.image = nil
    bubbleImageRight.addSubview(contentImageViewRight)
    NSLayoutConstraint.activate([
      contentImageViewRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor),
      contentImageViewRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor),
      contentImageViewRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor),
      contentImageViewRight.bottomAnchor.constraint(equalTo: bubbleImageRight.bottomAnchor),
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
      if let imageObject = model.message?.attachment as? V2NIMMessageImageAttachment, imageObject.ext != ".gif" {
        options = [.retryFailed, .progressiveLoad]
      }

      if imageUrl.hasPrefix("http") {
        let url = URL(string: imageUrl)
        contentImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        contentImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      }
    } else {
      contentImageView.image = nil
    }
  }
}
