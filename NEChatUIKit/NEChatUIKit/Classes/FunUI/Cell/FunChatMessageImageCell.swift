// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import UIKit

@objcMembers
open class FunChatMessageImageCell: FunChatMessageBaseCell {
  public let contentImageViewLeft = UIImageView()
  public let contentImageViewRight = UIImageView()
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func commonUI() {
    commonUIRight()
    commonUILeft()
  }

  open func commonUILeft() {
    contentImageViewLeft.translatesAutoresizingMaskIntoConstraints = false
    contentImageViewLeft.contentMode = .scaleAspectFill
    contentImageViewLeft.clipsToBounds = true
    contentImageViewLeft.layer.cornerRadius = 4
    bubbleImageLeft.image = nil
    bubbleImageLeft.addSubview(contentImageViewLeft)
    NSLayoutConstraint.activate([
      contentImageViewLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor),
      contentImageViewLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor),
      contentImageViewLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor),
      contentImageViewLeft.bottomAnchor.constraint(equalTo: bubbleImageLeft.bottomAnchor),
    ])
  }

  open func commonUIRight() {
    contentImageViewRight.translatesAutoresizingMaskIntoConstraints = false
    contentImageViewRight.contentMode = .scaleAspectFill
    contentImageViewRight.clipsToBounds = true
    contentImageViewRight.layer.cornerRadius = 4
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

    if let m = model as? MessageImageModel, let imageUrl = m.imageUrl {
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
