
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit
@objcMembers
open class TextWithRightArrowCell: ContactBaseTextCell {
  public var arrowImage = UIImageView(image: UIImage.ne_imageNamed(name: "arrowRight"))

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    arrowImage.translatesAutoresizingMaskIntoConstraints = false
    arrowImage.contentMode = .center
    contentView.addSubview(arrowImage)
    NSLayoutConstraint.activate([
      arrowImage.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20),
      arrowImage.widthAnchor.constraint(equalToConstant: 20),
      arrowImage.heightAnchor.constraint(equalToConstant: 20),
      arrowImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func setModel(model: UserItem) {
    super.setModel(model: model)
//        self.detailTitleLabel.text = model.detailTitle
  }
}
