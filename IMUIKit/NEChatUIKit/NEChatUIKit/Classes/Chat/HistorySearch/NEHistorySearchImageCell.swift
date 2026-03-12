//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import MJRefresh
import NEChatKit
import NIMSDK
import SDWebImage
import UIKit

open class NEHistorySearchImageCell: UICollectionViewCell {
  public let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public func setupUI() {
    contentView.addSubview(imageView)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.image = coreLoader.loadImage("default_image")

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  func configure(with model: MessageImageModel) {
    if let imageUrl = model.urlString {
      let options: SDWebImageOptions = [.retryFailed, .allowInvalidSSLCertificates]

      if imageUrl.hasPrefix("http") {
        let url = URL(string: imageUrl)
        imageView.sd_setImage(with: url) { [weak self] image, error, type, url in
          if let err = error as? NSError {
            if err.code == 2001,
               let imageObject = model.message?.attachment as? V2NIMMessageImageAttachment,
               let imageUrl = imageObject.url {
              let url = URL(string: imageUrl)
              let context: [SDWebImageContextOption: Any] = [.imageThumbnailPixelSize: CGSize(width: 350, height: 350)]
              self?.imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(contentsOfFile: imageUrl),
                options: options,
                context: context,
                progress: nil
              )
            } else {
              self?.imageView.image = coreLoader.loadImage("default_image")
            }
          }
        }
      } else {
        let url = URL(fileURLWithPath: imageUrl)
        imageView.sd_setImage(with: url, placeholderImage: nil, options: options, context: nil)
      }
    } else {
      imageView.image = coreLoader.loadImage("default_image")
    }
  }
}
