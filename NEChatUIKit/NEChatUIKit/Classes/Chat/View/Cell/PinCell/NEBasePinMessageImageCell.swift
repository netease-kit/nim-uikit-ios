// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NIMSDK
import SDWebImage
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

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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

  override open func configure(_ item: NEPinMessageModel) {
    super.configure(item)

    if let m = item.chatmodel as? MessageImageModel, let imageUrl = m.urlString {
      let options: SDWebImageOptions = [.retryFailed, .allowInvalidSSLCertificates]

      if imageUrl.hasPrefix("http") {
        let url = URL(string: imageUrl)
        contentImageView.sd_setImage(with: url) { [weak self] image, error, type, url in
          if let err = error as? NSError, err.code == 2001,
             let imageObject = item.message.attachment as? V2NIMMessageImageAttachment,
             let imageUrl = imageObject.url {
            let url = URL(string: imageUrl)
            let context: [SDWebImageContextOption: Any] = [.imageThumbnailPixelSize: CGSize(width: 350, height: 350)]
            self?.contentImageView.sd_setImage(
              with: url,
              placeholderImage: UIImage(contentsOfFile: imageUrl),
              options: options,
              context: context,
              progress: nil
            )
          }
        }
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        contentImageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      }
    } else {
      contentImageView.image = nil
    }
  }
}
