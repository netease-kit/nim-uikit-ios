
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class NEInputMoreCell: UICollectionViewCell {
  public var cellData: NEMoreItemModel?
  /// 功能标识图片
  public lazy var avatarImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.isUserInteractionEnabled = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.accessibilityIdentifier = "id.actionIcon"
    return imageView
  }()

  /// 功能说明文本
  public lazy var titleLabel: UILabel = {
    let titleLabel = UILabel()
    titleLabel.textColor = UIColor.ne_greyText
    titleLabel.font = UIFont.systemFont(ofSize: 10)
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.accessibilityIdentifier = "id.menuIcon"
    return titleLabel
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupViews() {
    contentView.addSubview(avatarImageView)
    contentView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      avatarImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      avatarImageView.widthAnchor.constraint(equalToConstant: NEMoreCell_Image_Size.width),
      avatarImageView.heightAnchor.constraint(equalToConstant: NEMoreCell_Image_Size.height),
    ])

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: NEMoreCell_Title_Height),
    ])
  }

  func config(_ itemModel: NEMoreItemModel) {
    cellData = itemModel
    avatarImageView.image = itemModel.customImage == nil ? itemModel.image : itemModel.customImage
    titleLabel.text = itemModel.title
  }

  /// 获取大小
  /// - Returns: 返回单元大小
  public static func getSize() -> CGSize {
    let menuSize = NEMoreCell_Image_Size
    return CGSize(width: menuSize.width, height: menuSize.height + NEMoreCell_Title_Height)
  }
}
