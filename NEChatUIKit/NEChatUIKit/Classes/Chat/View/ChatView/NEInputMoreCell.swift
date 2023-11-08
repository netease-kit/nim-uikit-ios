
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
public class NEInputMoreCell: UICollectionViewCell {
  public var cellData: NEMoreItemModel?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  func setupViews() {
    contentView.addSubview(avatarImage)
    contentView.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      avatarImage.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      avatarImage.topAnchor.constraint(equalTo: contentView.topAnchor),
      avatarImage.widthAnchor.constraint(equalToConstant: NEMoreCell_Image_Size.width),
      avatarImage.heightAnchor.constraint(equalToConstant: NEMoreCell_Image_Size.height),
    ])

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: avatarImage.bottomAnchor),
      titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      titleLabel.heightAnchor.constraint(equalToConstant: NEMoreCell_Title_Height),
    ])
  }

  lazy var avatarImage: UIImageView = {
    let imageView = UIImageView()
    imageView.isUserInteractionEnabled = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.accessibilityIdentifier = "id.actionIcon"
    return imageView
  }()

  lazy var titleLabel: UILabel = {
    let title = UILabel()
    title.textColor = UIColor.ne_greyText
    title.font = UIFont.systemFont(ofSize: 10)
    title.textAlignment = .center
    title.translatesAutoresizingMaskIntoConstraints = false
    return title
  }()

  func config(_ itemModel: NEMoreItemModel) {
    cellData = itemModel
    avatarImage.image = itemModel.customImage == nil ? itemModel.image : itemModel.customImage
    titleLabel.text = itemModel.title
  }

  /// 获取大小
  /// - Returns: 返回单元大小
  public static func getSize() -> CGSize {
    let menuSize = NEMoreCell_Image_Size
    return CGSize(width: menuSize.width, height: menuSize.height + NEMoreCell_Title_Height)
  }
}
