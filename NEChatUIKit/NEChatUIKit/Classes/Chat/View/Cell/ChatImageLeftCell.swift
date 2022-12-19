
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
import NIMSDK

@objcMembers
public class ChatImageLeftCell: ChatBaseLeftCell {
  public let contentImageView = UIImageView()
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func commonUI() {
    contentImageView.translatesAutoresizingMaskIntoConstraints = false
    contentImageView.contentMode = .scaleAspectFill
    contentImageView.clipsToBounds = true
    contentImageView.addCustomCorner(
      conrners: [.bottomLeft, .bottomRight, .topRight],
      radius: 8,
      backcolor: .white
    )
    bubbleImage.addSubview(contentImageView)
    NSLayoutConstraint.activate([
      contentImageView.rightAnchor.constraint(equalTo: bubbleImage.rightAnchor, constant: 0),
      contentImageView.leftAnchor.constraint(equalTo: bubbleImage.leftAnchor, constant: 0),
      contentImageView.topAnchor.constraint(equalTo: bubbleImage.topAnchor, constant: 0),
      contentImageView.bottomAnchor.constraint(
        equalTo: bubbleImage.bottomAnchor,
        constant: 0
      ),
    ])
  }

  override func setModel(_ model: MessageContentModel) {
    super.setModel(model)
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
        contentImageView.image = UIImage(contentsOfFile: imageUrl)
      }

    } else {
      contentImageView.image = nil
    }
  }
}
